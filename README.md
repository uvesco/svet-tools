# SVET Tools

Collezione di strumenti per i servizi veterinari area A in Italia e in Piemonte.

## Struttura del Repository

```
svet-tools/
├─ website/              # Sito Quarto
│  ├─ _quarto.yml       # Configurazione Quarto
│  ├─ index.qmd         # Homepage
│  ├─ tools.qmd         # Pagina strumenti
│  ├─ arvet-2-33.qmd    # ARVET Batch registra campioni
│  ├─ uivision.qmd      # Pagina Ui.Vision
│  ├─ installazione.qmd # Installazione e configurazione
│  ├─ uso-locale.qmd    # Uso locale delle app
│  ├─ troubleshooting.qmd # Risoluzione problemi
│  ├─ about.qmd         # Pagina about
│  └─ styles.scss       # Stili personalizzati
├─ tools/                # Strumenti
│  └─ arvet-2-33/       # App ARVET Batch registra campioni
│     ├─ app.R          # Applicazione Shiny
│     ├─ renv.lock      # Lock file dipendenze
│     └─ ui.vision/     # Macro Ui.Vision
│        ├─ fill_arvet_2-33_bovini.json
│        └─ fill_arvet_2_33_ovicaprini.json
├─ LICENSE
├─ README.md
└─ .gitignore
```

## Contenuto

### Sito Web

Il sito web è sviluppato con [Quarto](https://quarto.org/) e fornisce documentazione e accesso agli strumenti.

Per compilare il sito localmente:

```bash
cd website
quarto render
```

Per visualizzare il sito in modalità di sviluppo:

```bash
cd website
quarto preview
```

### Applicazioni R Shiny

#### ARVET Batch registra campioni

Un'applicazione per preparare i dati per l'inserimento della corrispondenza tra numero campione e contrassegno su ARVET da un file Excel (.xlsx).

Per eseguire l'applicazione:

```r
# Installa le dipendenze
setwd("tools/arvet-2-33")
renv::restore()

# Esegui l'app
shiny::runApp()
```

L'app è anche disponibile online: [https://vesco.shinyapps.io/arvet-2-33/](https://vesco.shinyapps.io/arvet-2-33/)

### Macro Ui.Vision

Le macro Ui.Vision automatizzano processi ripetitivi sui sistemi web veterinari:

- **fill_arvet_2-33_bovini.json**: Automazione per inserimento dati bovini su ARVET campionamenti
- **fill_arvet_2_33_ovicaprini.json**: Automazione per inserimento dati ovicaprini su ARVET campionamenti

## Requisiti

- **R** (>= 4.3.0) per le applicazioni Shiny (opzionale, disponibile anche online)
- **Quarto** per la compilazione del sito web
- **Ui.Vision** browser extension per l'utilizzo delle macro

## Contribuire

I contributi sono benvenuti! Per contribuire:

1. Fork del repository
2. Crea un branch per la tua feature (`git checkout -b feature/nome-feature`)
3. Commit delle modifiche (`git commit -m 'Aggiunta nuova feature'`)
4. Push al branch (`git push origin feature/nome-feature`)
5. Apri una Pull Request

## Licenza

Questo progetto è distribuito sotto licenza GPL-3.0. Vedi il file [LICENSE](LICENSE) per i dettagli.

## Contatti

- Repository: [uvesco/svet-tools](https://github.com/uvesco/svet-tools)
- Issues: [Segnala un problema](https://github.com/uvesco/svet-tools/issues)
