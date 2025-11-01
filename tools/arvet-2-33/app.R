# app.R
# Requisiti:
# install.packages(c("shiny","readxl","dplyr"))

library(shiny)
library(readxl)
library(dplyr)

ui <- fluidPage(
    titlePanel("Provette & Contrassegni da .xlsx (upload dal PC)"),
    sidebarLayout(
        sidebarPanel(
            fileInput(
                "xlsx", "Seleziona file .xlsx (dal tuo PC)",
                accept = c(".xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
            ),
            hr(),
            uiOutput("col_selects"),
            hr(),
            uiOutput("esito_controlli"),
            uiOutput("download_ui")
        ),
        mainPanel(
            h4("Istruzioni"),
            tags$ol(
                tags$li("Seleziona il file .xlsx dal tuo computer."),
                tags$li("Scegli la colonna 'provetta' (prima) e 'contrassegno' (dopo)."),
                tags$li("Controlli: interi ≥1, sequenza completa 1..N, nessun duplicato in provetta e contrassegno, elenco completo di mancanti e duplicati."),
                tags$li("Se tutto OK, esporta un CSV senza virgolette/intestazione (UTF-8, CRLF).")
            )
        )
    )
)

server <- function(input, output, session) {
    
    # Dati caricati dalla copia temporanea del file caricato
    dati <- reactive({
        req(input$xlsx)
        read_excel(input$xlsx$datapath, guess_max = 100000) |> as.data.frame()
    })
    
    # Menu colonne: provetta PRIMA, contrassegno DOPO; default 1ª e 2ª colonna
    output$col_selects <- renderUI({
        req(dati())
        cols <- names(dati())
        sel_prov  <- if (length(cols) >= 1) cols[1] else NULL
        sel_contr <- if (length(cols) >= 2) cols[2] else NULL
        
        tagList(
            selectInput("col_prov",  "Colonna 'provetta'",     choices = cols, selected = sel_prov),
            selectInput("col_contr", "Colonna 'contrassegno'", choices = cols, selected = sel_contr)
        )
    })
    
    # Validazioni (mancanti + duplicati elencati)
    esito <- reactive({
        req(dati(), input$col_contr, input$col_prov)
        df <- dati()
        
        # Lista dei controlli con risultati
        controlli <- list()
        ok_generale <- TRUE
        
        if (identical(input$col_contr, input$col_prov)) {
            controlli[[length(controlli) + 1]] <- list(
                check = "Colonne diverse (provetta ≠ contrassegno)",
                ok = FALSE,
                dettaglio = "Le colonne selezionate sono identiche"
            )
            ok_generale <- FALSE
        } else {
            controlli[[length(controlli) + 1]] <- list(
                check = "Colonne diverse (provetta ≠ contrassegno)",
                ok = TRUE,
                dettaglio = NULL
            )
        }
        
        contr <- df[[input$col_contr]]
        prov  <- df[[input$col_prov]]
        
        prov_non_na <- prov[!is.na(prov)]
        suppressWarnings(prov_num <- as.numeric(prov_non_na))
        
        # Controllo: valori numerici
        if (any(is.na(prov_num))) {
            controlli[[length(controlli) + 1]] <- list(
                check = "Provetta: valori numerici",
                ok = FALSE,
                dettaglio = "Contiene valori non numerici (esclusi NA)"
            )
            ok_generale <- FALSE
        } else {
            controlli[[length(controlli) + 1]] <- list(
                check = "Provetta: valori numerici",
                ok = TRUE,
                dettaglio = NULL
            )
        }
        
        # Controllo: numeri interi
        if (length(prov_num) > 0 && !all(abs(prov_num - round(prov_num)) < 1e-9)) {
            controlli[[length(controlli) + 1]] <- list(
                check = "Provetta: numeri interi",
                ok = FALSE,
                dettaglio = "Deve contenere solo numeri interi"
            )
            ok_generale <- FALSE
        } else if (length(prov_num) > 0) {
            controlli[[length(controlli) + 1]] <- list(
                check = "Provetta: numeri interi",
                ok = TRUE,
                dettaglio = NULL
            )
        }
        
        # Controllo: valori >= 1
        if (length(prov_num) > 0 && any(prov_num < 1)) {
            controlli[[length(controlli) + 1]] <- list(
                check = "Provetta: valori >= 1",
                ok = FALSE,
                dettaglio = "Alcuni valori sono minori di 1"
            )
            ok_generale <- FALSE
        } else if (length(prov_num) > 0) {
            controlli[[length(controlli) + 1]] <- list(
                check = "Provetta: valori >= 1",
                ok = TRUE,
                dettaglio = NULL
            )
        }
        
        # Controllo: almeno un valore valido
        if (length(prov_num) == 0) {
            controlli[[length(controlli) + 1]] <- list(
                check = "Provetta: almeno un valore valido",
                ok = FALSE,
                dettaglio = "Nessun valore valido (tutti NA?)"
            )
            ok_generale <- FALSE
        } else {
            controlli[[length(controlli) + 1]] <- list(
                check = "Provetta: almeno un valore valido",
                ok = TRUE,
                dettaglio = NULL
            )
        }
        
        # Se ci sono già errori, restituisci subito
        if (!ok_generale) {
            return(list(ok = FALSE, controlli = controlli, info = NULL))
        }
        
        prov_int <- as.integer(round(prov_num))
        N        <- max(prov_int)
        attesi   <- seq_len(N)
        presenti <- sort(unique(prov_int))
        
        mancanti <- setdiff(attesi, presenti)
        
        # Controllo: valori mancanti in provetta
        if (length(mancanti) > 0) {
            controlli[[length(controlli) + 1]] <- list(
                check = "Provetta: sequenza completa (1..N)",
                ok = FALSE,
                dettaglio = sprintf("MANCANTI (%d): %s", length(mancanti), paste(mancanti, collapse = ", "))
            )
            ok_generale <- FALSE
        } else {
            controlli[[length(controlli) + 1]] <- list(
                check = "Provetta: sequenza completa (1..N)",
                ok = TRUE,
                dettaglio = NULL
            )
        }
        
        # Controllo: duplicati in provetta
        tab <- table(prov_int)
        dup_values <- as.integer(names(tab)[tab > 1])
        dup_counts <- as.integer(tab[tab > 1])
        
        if (length(dup_values) > 0) {
            dup_pairs <- paste0(dup_values, "×", dup_counts)
            controlli[[length(controlli) + 1]] <- list(
                check = "Provetta: nessun duplicato",
                ok = FALSE,
                dettaglio = sprintf("DUPLICATI (%d valori): %s", length(dup_values), paste(dup_pairs, collapse = ", "))
            )
            ok_generale <- FALSE
        } else {
            controlli[[length(controlli) + 1]] <- list(
                check = "Provetta: nessun duplicato",
                ok = TRUE,
                dettaglio = NULL
            )
        }
        
        # NUOVO: Controllo duplicati in contrassegno
        contr_non_na <- contr[!is.na(contr)]
        if (length(contr_non_na) > 0) {
            tab_contr <- table(contr_non_na)
            dup_contr_values <- names(tab_contr)[tab_contr > 1]
            dup_contr_counts <- as.integer(tab_contr[tab_contr > 1])
            
            if (length(dup_contr_values) > 0) {
                dup_contr_pairs <- paste0(dup_contr_values, "×", dup_contr_counts)
                controlli[[length(controlli) + 1]] <- list(
                    check = "Contrassegno: nessun duplicato",
                    ok = FALSE,
                    dettaglio = sprintf("DUPLICATI (%d valori): %s", length(dup_contr_values), paste(dup_contr_pairs, collapse = ", "))
                )
                ok_generale <- FALSE
            } else {
                controlli[[length(controlli) + 1]] <- list(
                    check = "Contrassegno: nessun duplicato",
                    ok = TRUE,
                    dettaglio = NULL
                )
            }
        }
        
        n_provette_valide <- length(prov_num)
        n_contr_non_na    <- sum(!is.na(contr))
        
        info <- sprintf(
            "Provette (non NA): %d  |  N massimo atteso: %d  |  Contrassegni (non NA): %d",
            n_provette_valide, N, n_contr_non_na
        )
        
        list(ok = ok_generale,
             controlli = controlli,
             info = info,
             N = N)
    })
    
    output$esito_controlli <- renderUI({
        req(dati(), input$col_contr, input$col_prov)
        e <- esito()
        
        # Genera la lista di controlli con simboli
        controlli_html <- lapply(e$controlli, function(c) {
            simbolo <- if (c$ok) "✓" else "✗"
            colore <- if (c$ok) "#155724" else "#721c24"
            
            if (!is.null(c$dettaglio)) {
                tags$div(
                    style = sprintf("margin-bottom:4px; color:%s;", colore),
                    tags$span(style="font-weight:bold;", simbolo),
                    " ",
                    c$check,
                    tags$br(),
                    tags$span(style="margin-left:20px; font-size:0.9em;", c$dettaglio)
                )
            } else {
                tags$div(
                    style = sprintf("margin-bottom:4px; color:%s;", colore),
                    tags$span(style="font-weight:bold;", simbolo),
                    " ",
                    c$check
                )
            }
        })
        
        style_container <- if (isTRUE(e$ok)) {
            "background:#d4edda; border:1px solid #c3e6cb; padding:8px; border-radius:6px;"
        } else {
            "background:#f8d7da; border:1px solid #f5c6cb; padding:8px; border-radius:6px;"
        }
        
        tagList(
            if (!is.null(e$info)) div(style="margin-bottom:6px;", strong("Riepilogo: "), e$info),
            div(
                style = style_container,
                strong(if (isTRUE(e$ok)) "✓ Tutti i controlli superati" else "✗ Controlli falliti"),
                tags$hr(style="margin:8px 0;"),
                controlli_html
            )
        )
    })
    
    # Download solo se i controlli sono OK
    output$download_ui <- renderUI({
        e <- esito()
        if (!isTRUE(e$ok)) return(NULL)
        downloadButton("dl_csv", "Esporta CSV (provetta, contrassegno)")
    })
    
    # CSV: senza virgolette, senza header, UTF-8, CRLF; copia anche su Desktop (lato server)
    output$dl_csv <- downloadHandler(
        filename = function() { "provette.csv" },
        content = function(file) {
            req(dati(), input$col_contr, input$col_prov)
            df <- dati() %>% select(all_of(c(input$col_prov, input$col_contr)))
            names(df) <- c("provetta", "contrassegno")
            df <- df[complete.cases(df), ]
            
            write.table(
                df,
                file = file,
                sep = ",",
                row.names = FALSE,
                col.names = FALSE,
                quote = FALSE,
                fileEncoding = "UTF-8",
                eol = "\r\n"
            )
            
            # Copia anche su Desktop (lato SERVER)
            desktop_dir <- file.path(path.expand("~"), "Desktop")
            if (!dir.exists(desktop_dir)) dir.create(desktop_dir, recursive = TRUE, showWarnings = FALSE)
            desktop_path <- file.path(desktop_dir, "provette.csv")
            try({ file.copy(from = file, to = desktop_path, overwrite = TRUE) }, silent = TRUE)
        }
    )
}

shinyApp(ui, server)
