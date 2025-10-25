library(shiny)

# UI
ui <- fluidPage(
  titlePanel("Gestione Provette"),
  
  sidebarLayout(
    sidebarPanel(
      h3("Parametri"),
      
      textInput("id_provetta", "ID Provetta:", ""),
      
      dateInput("data_prelievo", "Data Prelievo:", value = Sys.Date()),
      
      selectInput("tipo_analisi", "Tipo Analisi:",
                  choices = c("Brucellosi", "Tubercolosi", "Leucosi", "Altro"),
                  selected = "Brucellosi"),
      
      selectInput("specie", "Specie:",
                  choices = c("Bovini", "Ovicaprini", "Suini", "Altro"),
                  selected = "Bovini"),
      
      textInput("azienda", "Codice Azienda:", ""),
      
      hr(),
      
      actionButton("aggiungi", "Aggiungi Provetta", class = "btn-primary"),
      actionButton("reset", "Reset", class = "btn-secondary")
    ),
    
    mainPanel(
      h3("Provette Registrate"),
      
      tableOutput("tabella_provette"),
      
      hr(),
      
      h4("Statistiche"),
      verbatimTextOutput("statistiche"),
      
      hr(),
      
      downloadButton("download_csv", "Scarica CSV")
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Reactive values per memorizzare i dati
  provette <- reactiveVal(data.frame(
    ID = character(),
    Data = character(),
    Analisi = character(),
    Specie = character(),
    Azienda = character(),
    stringsAsFactors = FALSE
  ))
  
  # Aggiungi provetta
  observeEvent(input$aggiungi, {
    if(input$id_provetta != "" && input$azienda != "") {
      nuova_provetta <- data.frame(
        ID = input$id_provetta,
        Data = as.character(input$data_prelievo),
        Analisi = input$tipo_analisi,
        Specie = input$specie,
        Azienda = input$azienda,
        stringsAsFactors = FALSE
      )
      
      provette(rbind(provette(), nuova_provetta))
      
      # Reset inputs
      updateTextInput(session, "id_provetta", value = "")
      updateTextInput(session, "azienda", value = "")
      
      showNotification("Provetta aggiunta con successo!", type = "message")
    } else {
      showNotification("Compilare ID Provetta e Codice Azienda", type = "error")
    }
  })
  
  # Reset
  observeEvent(input$reset, {
    provette(data.frame(
      ID = character(),
      Data = character(),
      Analisi = character(),
      Specie = character(),
      Azienda = character(),
      stringsAsFactors = FALSE
    ))
    
    updateTextInput(session, "id_provetta", value = "")
    updateTextInput(session, "azienda", value = "")
  })
  
  # Mostra tabella
  output$tabella_provette <- renderTable({
    provette()
  })
  
  # Statistiche
  output$statistiche <- renderText({
    df <- provette()
    
    if(nrow(df) == 0) {
      return("Nessuna provetta registrata")
    }
    
    paste0(
      "Totale provette: ", nrow(df), "\n",
      "Per analisi:\n",
      paste(names(table(df$Analisi)), ": ", table(df$Analisi), collapse = "\n"),
      "\n\nPer specie:\n",
      paste(names(table(df$Specie)), ": ", table(df$Specie), collapse = "\n")
    )
  })
  
  # Download CSV
  output$download_csv <- downloadHandler(
    filename = function() {
      paste0("provette_", Sys.Date(), ".csv")
    },
    content = function(file) {
      write.csv(provette(), file, row.names = FALSE)
    }
  )
}

# Run the application
shinyApp(ui = ui, server = server)
