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
                tags$li("Controlli: interi ≥1, sequenza completa 1..N, elenco completo di mancanti e duplicati."),
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
        
        if (identical(input$col_contr, input$col_prov)) {
            return(list(ok = FALSE, msg = "Errore: le colonne 'contrassegno' e 'provetta' non possono essere le stesse."))
        }
        
        contr <- df[[input$col_contr]]
        prov  <- df[[input$col_prov]]
        
        prov_non_na <- prov[!is.na(prov)]
        suppressWarnings(prov_num <- as.numeric(prov_non_na))
        if (any(is.na(prov_num))) {
            return(list(ok = FALSE, msg = "Errore: la colonna 'provetta' contiene valori non numerici (esclusi NA)."))
        }
        if (!all(abs(prov_num - round(prov_num)) < 1e-9)) {
            return(list(ok = FALSE, msg = "Errore: la colonna 'provetta' deve contenere solo numeri interi (esclusi NA)."))
        }
        if (any(prov_num < 1)) {
            return(list(ok = FALSE, msg = "Errore: i valori di 'provetta' devono essere >= 1."))
        }
        if (length(prov_num) == 0) {
            return(list(ok = FALSE, msg = "Errore: nessun valore valido in 'provetta' (tutti NA?)."))
        }
        
        prov_int <- as.integer(round(prov_num))
        N        <- max(prov_int)
        attesi   <- seq_len(N)
        presenti <- sort(unique(prov_int))
        
        mancanti <- setdiff(attesi, presenti)
        
        tab <- table(prov_int)
        dup_values <- as.integer(names(tab)[tab > 1])
        dup_counts <- as.integer(tab[tab > 1])
        
        n_provette_valide <- length(prov_num)
        n_contr_non_na    <- sum(!is.na(contr))
        
        info <- sprintf(
            "Provette (non NA): %d  |  N massimo atteso: %d  |  Contrassegni (non NA): %d",
            n_provette_valide, N, n_contr_non_na
        )
        
        error_msgs <- character()
        if (length(mancanti) > 0) {
            error_msgs <- c(error_msgs, sprintf("MANCANTI (%d): %s", length(mancanti), paste(mancanti, collapse = ", ")))
        }
        if (length(dup_values) > 0) {
            dup_pairs <- paste0(dup_values, "×", dup_counts)
            error_msgs <- c(error_msgs, sprintf("DUPLICATI (%d valori): %s", length(dup_values), paste(dup_pairs, collapse = ", ")))
        }
        
        if (length(error_msgs) > 0) {
            return(list(
                ok   = FALSE,
                msg  = paste(c("Errori nei controlli:", error_msgs), collapse = "\n"),
                info = info
            ))
        }
        
        list(ok = TRUE,
             msg = "Controllo superato: sequenza 1..N completa, nessun valore mancante o duplicato.",
             info = info,
             N = N)
    })
    
    output$esito_controlli <- renderUI({
        req(dati(), input$col_contr, input$col_prov)
        e <- esito()
        style_ok  <- "color:#155724; background:#d4edda; border:1px solid #c3e6cb; padding:8px; border-radius:6px; white-space:pre-wrap;"
        style_err <- "color:#721c24; background:#f8d7da; border:1px solid #f5c6cb; padding:8px; border-radius:6px; white-space:pre-wrap;"
        tagList(
            if (!is.null(e$info)) div(style="margin-bottom:6px;", strong("Riepilogo: "), e$info),
            div(style = if (isTRUE(e$ok)) style_ok else style_err, e$msg)
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
