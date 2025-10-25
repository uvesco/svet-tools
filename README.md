# SVET Tools

Collezione di strumenti per i servizi veterinari area A in Italia e in Piemonte.

## Struttura del Repository

```
svet-tools/
├─ website/              # Sito Quarto
│  ├─ _quarto.yml       # Configurazione Quarto
│  ├─ index.qmd         # Homepage
│  ├─ tools.qmd         # Pagina strumenti
│  ├─ uivision.qmd      # Pagina UI Vision
│  ├─ about.qmd         # Pagina about
│  └─ styles.scss       # Stili personalizzati
├─ tools/                # Strumenti
│  ├─ shiny-provette/   # App Shiny gestione provette
│  │  ├─ app.R          # Applicazione Shiny
│  │  ├─ renv.lock      # Lock file dipendenze
│  │  └─ www/           # Assets statici
│  └─ uivision/         # Macro UI Vision
│     └─ macros/
│        ├─ 233_ovicaprini.json  # Macro per ovicaprini
│        └─ 233_bovini.json      # Macro per bovini
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

#### Shiny Provette

Un'applicazione interattiva per la gestione delle provette veterinarie.

Per eseguire l'applicazione:

```r
# Installa le dipendenze
renv::restore()

# Esegui l'app
shiny::runApp("tools/shiny-provette")
```

### Macro UI Vision

Le macro UI Vision automatizzano processi ripetitivi sui sistemi web veterinari:

- **233_ovicaprini.json**: Automazione per gestione ovicaprini nel sistema 233
- **233_bovini.json**: Automazione per gestione bovini nel sistema 233

## Requisiti

- **R** (>= 4.3.0) per le applicazioni Shiny
- **Quarto** per la compilazione del sito web
- **UI Vision** browser extension per l'utilizzo delle macro

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
