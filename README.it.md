[English](README.md) | [Magyar](README.hu.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Русский](README.ru.md) | [Nederlands](README.nl.md) | [Polski](README.pl.md) | [Українська](README.uk.md) | [Svenska](README.sv.md) | [Italiano](README.it.md) | [日本語](README.ja.md) | [中文](README.zh.md) | [한국어](README.ko.md) | [Kiswahili](README.sw.md)

# QuorumAI

QuorumAI è un sistema modulare di orchestrazione multi-agente per IA, auto-ospitato e costruito su LangGraph. Funziona interamente in Docker, si connette a tutte le principali piattaforme di messaggistica, supporta l'interazione vocale, il controllo della casa intelligente e simula una «azienda» IA multi-ruolo con memoria a lungo termine ed esecuzione autonoma dei compiti.

![Python 3.11](https://img.shields.io/badge/Python-3.11-blue.svg) ![Docker](https://img.shields.io/badge/Docker-Compose-2496ED.svg)

---

<div align="center">
  <video src="https://github.com/user-attachments/assets/7bd072b6-75cd-4345-9fe0-fa2f3ee0566e" controls width="800"></video>

  <p><b><a href="https://license.quorumai.eu/portal/register">Inizia ora — registrati per una prova gratuita di 30 giorni »</a></b></p>
</div>

---

## Cos'è QuorumAI

QuorumAI trasforma uno o più LLM in un team di agenti IA in grado di:

- Rispondere a domande, leggere le notizie e controllare dispositivi domotici — attivato da microfono, Telegram, Matrix, Discord, Slack, Signal, WhatsApp, Viber o IRC.
- Delegare il lavoro tra ruoli specializzati (CEO, sviluppatore, vendite) e mantenere la memoria a lungo termine tra le sessioni tramite la ricerca vettoriale di Qdrant.
- Eseguire compiti in modo autonomo tramite uno schedulatore heartbeat, richiedere l'approvazione umana quando necessario (HITL) ed esporre ogni capacità esterna come server MCP (Model Context Protocol).

Tutto si configura in YAML. Non sono necessarie modifiche al codice per cambiare modelli, aggiungere agenti o collegare nuovi strumenti.

---

## Installazione rapida

### Una riga (consigliato)

Il programma di installazione bootstrap verifica la presenza di Python 3 e Docker, li installa se mancanti, quindi avvia l'installatore interattivo di QuorumAI.

**Linux / macOS:**
```bash
curl -fsSL https://raw.githubusercontent.com/FulopJozsi/QuorumAI/main/install.sh | bash
```

**Windows (PowerShell — eseguire come Amministratore):**
```powershell
irm https://raw.githubusercontent.com/FulopJozsi/QuorumAI/main/install.ps1 | iex
```

Oppure scarica `install.bat` / `install.ps1` dal repository e fai doppio clic.

> **Nota:** Su Linux, il bootstrap installa Docker Engine dal repository ufficiale Docker (apt/dnf/yum a seconda della distribuzione) e aggiunge l'utente al gruppo `docker`. È necessario disconnettersi e riconnettersi. Su macOS e Windows installa Docker Desktop e chiede di avviarlo prima di continuare.

---

### Hai già Python 3 e Docker?

Clona il repository ed esegui l'installatore interattivo direttamente — non sono necessari pip o dipendenze aggiuntive:

```bash
git clone https://github.com/FulopJozsi/QuorumAI.git
cd QuorumAI
python3 install.py
```

L'installatore:
- Presenta un selettore di moduli interattivo (orchestratore, bridge, voce, GUI e altro).
- Scrive `.env` dalle tue risposte, crea le directory bind-mount `data/` ed esegue `docker compose up -d`.
- L'interfaccia dell'installatore è disponibile in 16 lingue.

**Modalità Satellite** — eseguire microfono, bridge o server MCP su una macchina separata:
```bash
python3 install.py   # scegli "Satellite" quando richiesto
```

---

## Avvio rapido

```bash
git clone https://github.com/FulopJozsi/QuorumAI.git
cd QuorumAI
python3 install.py
```

Verificare che l'orchestratore sia in funzione:

```bash
curl http://localhost:8000/health
```

Inviare un messaggio di test:

```bash
curl -X POST http://localhost:8000/invoke \
  -H 'Content-Type: application/json' \
  -d '{"message": "Hello, introduce yourself."}'
```

GUI disponibile su: `http://localhost:3000`

---

## Architettura

```
┌─────────────────────────────────────────────────────────────┐
│                      quorum-net (Docker network)             │
│                                                             │
│  ┌──────────────┐   ┌──────────┐   ┌─────────────────────┐ │
│  │   Bridges    │   │   GUI    │   │    MCP Servers      │ │
│  │  Telegram    │──▶│  React   │   │  hu-tools  │ │
│  │  Matrix      │   │  Vite    │   │  home-assistant     │ │
│  │  Discord     │   │ Tailwind │   │  email, joplin      │ │
│  │  IRC, etc.   │   └──────────┘   │  playwright, mgr    │ │
│  └──────┬───────┘                  └──────────┬──────────┘ │
│         │              ┌────────────────────┐  │            │
│         └─────────────▶│    Orchestrator    │◀─┘            │
│                        │    LangGraph       │               │
│                        │    FastAPI :8000   │               │
│                        └────────┬───────────┘               │
│               ┌─────────────────┼─────────────────┐         │
│          ┌────▼────┐      ┌─────▼────┐    ┌───────▼──────┐  │
│          │ Qdrant  │      │PostgreSQL│    │  FalkorDB    │  │
│          │ Memory  │      │Checkpoint│    │  Knowledge   │  │
│          └─────────┘      └──────────┘    └──────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

Ogni livello risiede nella propria directory con il proprio `compose.yml`. Il `compose.yml` radice aggrega tutti i livelli tramite `include:` e i profili Docker Compose — si avvia solo ciò che è necessario.

---

## Funzionalità

### Orchestrazione principale

- **Runtime LangGraph** — grafo di agenti a macchina a stati, checkpointing HITL nativo, `AsyncPostgresSaver`.
- **API HTTP FastAPI** — `POST /invoke`, `GET /health`, streaming, ricevitore webhook, relay notifiche push.
- **agents.yaml** — dichiarare agenti in YAML: nome, ruolo, provider, modello, percorso prompt di sistema, strumenti.
- **Ricarica a caldo** — `POST /agents/reload` ricarica `agents.yaml` senza riavviare il container.
- **Protocollo strumenti MCP** — ogni capacità esterna è un server MCP; gli agenti scoprono gli strumenti automaticamente.
- **Memoria vettoriale Qdrant** — ricerca ibrida semantica + BM42 lessicale, embedding multilingual-e5-large, collezioni per agente, deduplicazione coseno, recupero diversificato MMR.
- **Consolidamento notturno della memoria** — «lavoro di sogno» pianificato che distilla la cronologia delle sessioni PostgreSQL in fatti Qdrant a lungo termine; unisce le progressioni, rimuove le voci effimere obsolete; stato tracciato in PostgreSQL.
- **PostgreSQL** — checkpointer `AsyncPostgresSaver` di LangGraph + tabelle di compiti e commenti.
- **Grafo della conoscenza** — FalkorDB (compatibile Redis), query Cypher per utente, estrazione automatica di entità.

### Provider LLM (per agente, configurati in agents.yaml)

| Locali | Cloud |
|---|---|
| Ollama (predefinito, senza chiave) | Anthropic Claude |
| llama.cpp | OpenAI |
| LM Studio | OpenRouter |
| vLLM | Google Gemini |
| Docker Model Runner | Grok (xAI) |
| Unsloth Studio | DeepSeek |
| | Mistral AI |
| | Together AI |
| | Fireworks AI |
| | Zhipu AI / Z.AI |
| | Eden AI (aggregatore) |
| | NVIDIA NIM (livello gratuito disponibile) |

Non è necessaria alcuna chiave API per iniziare — Ollama funziona localmente e gratuitamente.

**Pool di provider** — più server locali identici (ad es. sei macchine Ollama) possono essere raggruppati in un pool con nome. L'orchestratore distribuisce le richieste con bilanciamento least-connections; se tutti i membri del pool falliscono, si ricade sulla catena di fallback normale. Configurato in `providers.yaml` e gestibile dalla scheda Provider della GUI.

### Simulazione di azienda multi-agente

- Agenti basati su ruoli: CEO, sviluppatore, vendite e qualsiasi ruolo personalizzato.
- L'agente dispatcher indirizza automaticamente le richieste in arrivo allo specialista corretto.
- Agenti pipeline: cicli pianificatore → esecutore → revisore con stato condiviso.
- **Agenti autonomi (Deep)** — imposta `deep: true` su qualsiasi agente o fase pipeline per attivare il ciclo ReAct LangGraph integrato. L'agente pianifica, esegue e itera autonomamente — chiama strumenti ripetutamente fino al completamento del compito o al raggiungimento del limite opzionale di chiamate agli strumenti (`deep_max_steps`, 0 = illimitato). Configurabile per agente e per fase di pipeline; interruttore disponibile nel GUI Agent Builder.
- Libreria di competenze: file Markdown di competenze, caricamento lazy per agente, marketplace comunitario per la condivisione.
- Area di lavoro condivisa: gli agenti possono leggere e scrivere un'area file condivisa.
- **Strumenti di amministrazione** — gli agenti con ruolo `admin` possono creare ed eliminare agenti, skill, server MCP, cron job e pianificazioni heartbeat in fase di esecuzione tramite gli strumenti `system-admin`. Ogni azione di scrittura richiede l'approvazione HITL prima dell'esecuzione.

### Gestione dei compiti e autonomia

- Bacheca Kanban con sottocompiti e commenti (basata su PostgreSQL).
- Schedulatore heartbeat: gli agenti raccolgono automaticamente i compiti in attesa (ogni 5 minuti per impostazione predefinita).
- Esecuzione autonoma con gate di approvazione HITL (Telegram `/approve`, pulsanti GUI).
- Notifiche push: Telegram, Home Assistant `notify`, web push (VAPID). Le attività possono specificare un campo `notify_channel` in modo che il messaggio di completamento vada sempre al bridge corretto, indipendentemente dalla sessione che ha creato l'attività. Gli agenti possono chiamare `list_notify_channels()` per scoprire i canali disponibili in fase di esecuzione.

**Attività su più giorni** — il modello consigliato per lavori di lunga durata che si estendono su ore o giorni:
1. Crea un'attività con titolo e descrizione (tramite chat, Telegram o la bacheca Kanban della GUI).
2. L'agente (o tu) chiama `set_subtasks` per suddividerla in passi denominati.
3. Ogni esecuzione heartbeat raccoglie il successivo sottocompito in sospeso, lo completa e si ferma — le singole sessioni LLM rimangono brevi e focalizzate.
4. I progressi, le decisioni e i risultati intermedi vengono memorizzati come commenti all'attività, così ogni esecuzione successiva ha il contesto completo di ciò che è avvenuto in precedenza.
5. Quando tutte le sottoattività sono completate, l'agente chiude l'attività e invia una notifica di completamento.

Questo modello funziona senza modifiche al codice — si basa sugli strumenti attività esistenti (`set_subtasks`, `get_next_subtask`, `complete_subtask`) a cui ha accesso qualsiasi agente con la sorgente di strumenti `tasks`.

### Supervisione della sicurezza (Quadrumvirato)

Uno strato opzionale per agente che verifica ogni chiamata di strumento rischiosa prima dell'esecuzione. Attivato con `guardian: true` in `agents.yaml`; gli agenti senza questo flag non sono interessati.

- **Guardian** — una chiamata LLM isolata (senza strumenti) che valuta il nome e gli argomenti dello strumento e restituisce: `NONE` (proseguire), `SOFT VETO: motivo` (decisione umana richiesta) o `HARD VETO: motivo` (blocco immediato).
- **Arbitro** — attivato su SOFT VETO; genera un rapporto di analisi Markdown e sospende il grafo tramite LangGraph `interrupt()`. L'operatore approva o rifiuta tramite Telegram `/approve` o l'interfaccia grafica — stesso flusso del HITL.
- **Storiografo** — un job heartbeat che legge il log di audit Guardian in memoria e scrive un rapporto strutturato nella tabella PostgreSQL `historian_reports`.
- **Classificazione del rischio** — i server MCP ricevono l'etichetta `risk: low` o `risk: high` in `mcps.yaml`. Gli strumenti di memoria, attività e approvazione sono sempre esclusi dal controllo.

```yaml
# agents.yaml
agents:
  - name: ceo
    guardian: true
    guardian_provider: anthropic        # opzionale — eredita il provider dell'agente se vuoto
    guardian_model: claude-haiku-4-5-20251001
    arbiter_provider: anthropic
    arbiter_model: claude-sonnet-4-6
```

```yaml
# mcps.yaml
servers:
  - name: playwright
    risk: high        # tutti gli strumenti playwright richiedono l'approvazione del Guardian
  - name: hu-tools
    risk: low         # meteo, notizie — trasmessi senza controllo
```

L'endpoint `/guardian/log` restituisce il log di audit in tempo reale (ultime 1 000 decisioni).

### Autenticazione e multi-tenancy

| Modalità | Descrizione |
|---|---|
| `AUTH_MODE=none` | Aperto — nessuna autenticazione (predefinito, per uso locale) |
| `AUTH_MODE=local` | Token Bearer; utenti definiti in `LOCAL_USERS=utente1:pass1,...` |
| `AUTH_MODE=sso` | Keycloak OIDC/JWT, o qualsiasi provider OIDC (Auth0, Okta, Authelia, …) |

**Isolamento per utente.** In modalità multiutente la memoria e il grafo
della conoscenza di ogni utente sono separati: la memoria a lungo termine va
nella propria collection Qdrant e il grafo nel proprio `scope` — una lettura vede
i dati propri e il livello comune curato dall'amministratore, mai quelli di un
altro utente. Anche la manutenzione notturna gira **per utente**.

### Osservabilità

- Tracce pipeline con registrazione token e costi per turno.
- Vista a cascata nella scheda Monitoraggio della GUI.
- Pulizia automatica delle tracce controllata da `TRACE_RETENTION_DAYS`.

### Ricevitore webhook

Accetta webhook firmati da: GitHub, Gitea, Drone CI, Grafana, n8n, Slack, ERPNext, Twenty CRM, Zammad, Tiledesk, Uptime Kuma, Wekan, Umami, Duplicati, BorgWarehouse.

### Backup e persistenza della configurazione

Tutti i dati di runtime si trovano in `data/` come bind mount; tutta la configurazione in file YAML — nessuno stato nascosto nei container.

**Creare un backup** (include `.env` + `data/`):

```bash
sudo python3 backup.py backup                 # interattivo, nome file automatico
sudo python3 backup.py backup /srv/backup.tgz # percorso di output esplicito
```

**Ripristinare**:

```bash
python3 backup.py restore /srv/backup.tgz           # ripristino nella directory corrente
python3 backup.py restore /srv/backup.tgz /opt/qai  # ripristino in una directory specifica
```

Su Linux / macOS eseguire con `sudo` per preservare la proprietà dei file. Su Windows non è necessario.

---

## Bridge

| Bridge | Trasporto | Profilo Compose |
|---|---|---|
| Telegram | Bot API, async (python-telegram-bot) | `telegram` |
| Matrix | matrix-nio, livello stanza | `matrix` |
| Discord | discord.py, slash command | `discord` |
| IRC | irc3 asyncio, multi-canale | `irc` |
| WhatsApp | Meta Cloud API webhook | `whatsapp` |
| Slack | slack-bolt Socket Mode | `slack` |
| Signal | signal-cli REST API polling | `signal` |
| Viber | FastAPI webhook, pulsanti tastiera | `viber` |

Ogni bridge espone `/notify` (per notifiche push dall'orchestratore) e `/health` (verifica di attività), e supporta allowlist per mittenti e canali. Telegram e la GUI supportano anche il flusso HITL `/approve`. Tutti i bridge supportano il cambio di lingua per utente tramite il comando `/language`; la preferenza viene salvata in PostgreSQL e sopravvive ai riavvii dei container.

---

## Voce

### Bridge microfono (microfono locale)

Profilo Compose: `mic`

- openWakeWord — wake word configurabile (predefinito: "Ok Szif").
- Wyoming Whisper — STT locale, senza cloud.
- Wyoming Piper — TTS locale.
- Mount socket PulseAudio per desktop Linux.

**Note sulla piattaforma:**

- **Linux** — l'installer rileva il tuo UID e monta automaticamente il socket PulseAudio corretto (`/run/user/<uid>/pulse`).
- **macOS / Windows** — Docker Desktop non passa attraverso i dispositivi audio. L'installer scrive invece una configurazione PulseAudio TCP. Configurare PulseAudio in modalità TCP prima di avviare il container mic:
  - macOS: `brew install pulseaudio && pulseaudio --load=module-native-protocol-tcp --exit-idle-time=-1 --daemon`
  - Windows (WSL2): `sudo apt install pulseaudio && pulseaudio --load=module-native-protocol-tcp --exit-idle-time=-1 --start`
  - Windows (nativo): scaricare PulseAudio per Windows, decommentare `module-native-protocol-tcp` in `default.pa`, consentire la porta 4713 nel firewall.

### Home Assistant Voice PE

Profilo Compose: `ha`

QuorumAI si registra come agente di conversazione in Home Assistant. HA Assist gestisce il rilevamento della wake word, Whisper STT e Piper TTS lato HA; QuorumAI gestisce il ragionamento e le chiamate agli strumenti.

### Strumenti STT e TTS (chiamabili dagli agenti)

Profilo Compose: `stt-tts`

Espone Whisper e Piper come API HTTP che gli agenti possono chiamare come strumenti `system-stt` e `system-tts`.

---

## GUI

Profilo Compose: `gui` — disponibile su `http://localhost:3000`

Costruita con React, Vite e Tailwind CSS.

| Scheda | Descrizione |
|---|---|
| Chat | Invia messaggi a qualsiasi agente; visualizza le risposte in streaming |
| Agent Builder | Diagramma aziendale visuale; crea e modifica agenti e i loro ruoli |
| Skill Editor | Crea e gestisci file di competenze Markdown |
| Tasks | Bacheca Kanban; albero sottocompiti; commenti; pulsanti di approvazione |
| Providers | Stato in tempo reale dei provider e lista modelli disponibili |
| Heartbeat | Stato dello schedulatore; orari prossima esecuzione; attivazione manuale |
| Observability | Tracce pipeline; vista a cascata token e costi |

- 16 lingue di interfaccia, 14 temi.
- Pulsanti di approvazione HITL integrati nelle schede Chat e Tasks.

---

## Dettagli di installazione

### Prerequisiti

- Docker Engine 24+ e Docker Compose v2.
- Python 3.8+ per `install.py` — senza pip o virtualenv.
- Per modelli locali: Ollama in esecuzione sull'host sulla porta 11434.

### Creare la rete condivisa (una volta per host)

```bash
docker network create quorum-net
```

### Selezione dei profili

Impostare i profili in `.env` in modo che il semplice `docker compose up -d` funzioni:

```env
COMPOSE_PROFILES=orchestrator,memory,mcp,postgres,telegram,gui
```

Oppure passarli esplicitamente:

```bash
docker compose --profile orchestrator --profile memory --profile gui up -d
```

Profili disponibili: `orchestrator`, `memory`, `mcp`, `postgres`, `telegram`, `ha`, `mic`, `gui`, `stt-tts`, `mcp-manager`, `playwright`, `joplin`, `auth`, `email`, `matrix`, `discord`, `irc`, `whatsapp`, `slack`, `signal`, `viber`, `graph`

### Layout della directory data

```
data/
  qdrant/        # Vettori Qdrant
  postgres/      # Dati PostgreSQL
  workspace/     # Area file condivisa per agente
  whisper/       # Cache modelli Whisper
  piper/         # File voci Piper
  ...
```

Tutto ciò che si trova sotto `data/` è gitignored. Il backup di questa directory preserva tutto lo stato persistente.

---

## Configurazione

Copiare `.env.example` in `.env` e compilare ciò che serve. Il file `.env.example` contiene documentazione inline per ogni chiave.

### Chiavi più importanti

| Chiave | Predefinito | Descrizione |
|---|---|---|
| `COMPOSE_PROFILES` | — | Profili da avviare, separati da virgole |
| `AUTH_MODE` | `none` | `none` / `local` / `sso` |
| `ORCHESTRATOR_PORT` | `8000` | Porta FastAPI dell'orchestratore |
| `GUI_PORT` | `3000` | Porta GUI |
| `QDRANT_HTTP_PORT` | `6333` | Porta REST Qdrant |
| `POSTGRES_PORT` | `5433` | Porta PostgreSQL |
| `POSTGRES_PASSWORD` | `changeme` | Password PostgreSQL — cambiarla! |
| `TRACE_RETENTION_DAYS` | `14` | Eliminazione automatica delle tracce dopo N giorni |
| `ANTHROPIC_API_KEY` | — | Richiesta per provider Anthropic |
| `OPENROUTER_API_KEY` | — | Richiesta per OpenRouter |
| `OPENAI_API_KEY` | — | Richiesta per OpenAI |
| `GOOGLE_API_KEY` | — | Richiesta per Google Gemini |
| `TELEGRAM_BOT_TOKEN` | — | Richiesto per bridge Telegram |
| `TELEGRAM_CHAT_ID` | — | ID chat Telegram da accettare |
| `NOTIFY_TELEGRAM_CHAT_ID` | — | ID chat per notifiche di completamento attività (uguale a `TELEGRAM_CHAT_ID` se identico) |
| `MATRIX_HOMESERVER` | — | URL server Matrix |
| `MATRIX_ACCESS_TOKEN` | — | Token di accesso bot Matrix |
| `DISCORD_BOT_TOKEN` | — | Richiesto per bridge Discord |
| `SLACK_BOT_TOKEN` | — | Richiesto per bridge Slack |
| `SLACK_APP_TOKEN` | — | Richiesto per Slack Socket Mode |
| `SIGNAL_PHONE` | — | Numero di telefono per bridge Signal |
| `VIBER_AUTH_TOKEN` | — | Richiesto per bridge Viber |
| `HA_URL` | `http://homeassistant:8123` | URL base di Home Assistant |
| `HA_TOKEN` | — | Token di accesso a lunga durata HA |
| `IMAP_HOST` | — | Server IMAP per Email MCP |
| `SMTP_HOST` | — | Server SMTP per Email MCP |
| `FALKORDB_URL` | — | Impostare per abilitare il grafo della conoscenza |
| `VAPID_EMAIL` | — | Richiesto per notifiche web push |
| `VAPID_PRIVATE_KEY` | — | Generato automaticamente dall'installer (richiede il pacchetto Python `cryptography`); altrimenti: `docker compose exec orchestrator python3 webpush.py` |
| `VAPID_PUBLIC_KEY` | — | Generato insieme alla chiave privata |
| `HU_TOOLS_PORT` | `4300` | Porta MCP hu-tools |
| `WHISPER_URL` | `http://whisper-http:8000` | URL servizio STT |
| `PIPER_URL` | `http://piper-http:5000` | URL servizio TTS |
| `ORCHESTRATOR_API_KEY` | — | Generato automaticamente dall'installer; token servizio-a-servizio per i bridge (obbligatorio in `AUTH_MODE=local/sso`) |
| `CONVERSATION_API_KEY` | — | Generato automaticamente dall'installer; protegge l'endpoint HA `/conversation` (vuoto = aperto) |

La configurazione degli agenti si trova in `orchestrator/agents.yaml` — non in `.env`.

---

## Pacchetti settoriali

Pacchetti verticali predefiniti per settori specifici. Ogni pacchetto contiene file di competenze, configurazioni di agenti suggerite e riferimenti MCP. Installabili tramite `install.py` o manualmente.

| Pacchetto | Target | Competenze chiave |
|---|---|---|
| `legal` | Studi legali | Ricerca documenti, analisi contratti, ricerca legale ungherese |
| `devops` | Aziende IT/DevOps | Triage incidenti, ricerca runbook, AIOps con HITL |
| `agency` | Agenzie marketing e PR | Stato progetto, qualificazione lead, analisi brief, reporting clienti |

**Installazione manuale:**
```bash
cp industry-packs/legal/skills/*.md data/skills/
cat industry-packs/legal/agents.yaml
```

**Tramite installer:** rieseguire `python3 install.py` → Modifica → seleziona un pacchetto settoriale.

Crea il tuo pacchetto copiando `industry-packs/_template/` e compilando `pack.yaml`.

---

## Integrazione CRM

Il CRM MCP (`mcps/crm/`) fornisce un'interfaccia unificata per più sistemi CRM tramite un'architettura ad adattatori intercambiabili. Gli agenti utilizzano gli stessi strumenti indipendentemente dal backend.

**Adattatori supportati:**

| Adattatore | Sistema | Tipo |
|---|---|---|
| `minicrm` | MiniCRM (leader di mercato ungherese) | Completo |
| `hubspot` | HubSpot CRM | Completo |
| `pipedrive` | Pipedrive | Completo |
| `billingo` | Fatturazione Billingo | Solo lettura |
| `szamlazzhu` | Fatturazione Számlázz.hu | Solo lettura |
| `salesautopilot` | SalesAutopilot (marketing automation HU) | Completo |

**Strumenti disponibili:** `search_entities`, `get_entity`, `create_entity`, `update_entity`, `add_note`, `get_timeline`, `link_entities`, `get_related`, `emit_event`, `list_entity_types`

**Avvio rapido:**
```env
CRM_ADAPTER=minicrm
MINICRM_SYSTEM_ID=12345
MINICRM_API_KEY=chiave
```

```bash
docker compose --profile crm up -d
```

Aggiungere `crm` alla lista `tools:` di un agente in `agents.yaml` per dargli accesso al CRM.

---

## jog.gov.hu MCP — Ricerca legale ungherese

Il MCP jog.gov.hu (`mcps/jog-hu/`) fornisce informazioni legali ungheresi agli agenti IA in due modalità di distribuzione:

**Modalità Docker** (funziona sempre, senza Playwright):

| Strumento | Descrizione |
|---|---|
| `search_njt_laws(keywords)` | Ricerca per parole chiave su njt.jog.gov.hu — restituisce titoli e URL delle leggi corrispondenti |
| `get_law_text(law_id, section)` | Testo completo o parziale della legge da njt.hu (es. `"2012. évi I. törvény"`, sezione `"69"`) |
| `list_recent_laws(category, days)` | Leggi recenti dal feed RSS di Magyar Közlöny |

**Modalità host** (ricerca con IA, richiede l'esecuzione di `host_server.py` sulla macchina host):

| Strumento | Descrizione |
|---|---|
| `search_law(question)` | Domanda in linguaggio naturale → risposta IA + riferimenti legali citati (jog.gov.hu) |

reCAPTCHA v3 valuta le sessioni principalmente in base alla **reputazione dell'IP**. Gli IP dei container Docker e dei server cloud/VPS sono classificati come indirizzi datacenter e ricevono un punteggio di fiducia basso — indipendentemente dalle patch al fingerprint del browser. Una macchina domestica o aziendale su un **IP residenziale** ottiene un punteggio sufficientemente alto da superare il controllo. Non è richiesto un display grafico — il browser funziona in modalità headless; il display è irrilevante.

**Avvio rapido (strumenti Docker — funziona sempre):**
```bash
docker compose --profile jog-hu up -d
```

**Avviare il server host (ricerca IA — IP residenziale richiesto):**
```bash
# Funziona su: desktop o laptop domestico/aziendale (Windows, macOS, Linux)
# NON funziona su: server cloud/VPS (IP datacenter bloccati da reCAPTCHA)
# Display grafico NON richiesto — esegue in modalità headless

pip install mcp fastmcp httpx playwright playwright-stealth
playwright install chromium

python3 mcps/jog-hu/host_server.py --background   # avvia daemon, porta 4312
python3 mcps/jog-hu/host_server.py --stop          # ferma daemon
```

**Aggiungere a `mcps.yaml`:**
```yaml
- name: jog-hu
  url: http://jog-hu-mcp:4302/mcp/
  description: Hungarian legal search (njt.hu)

# Opzionale — solo se host_server.py è in esecuzione:
- name: jog-hu-host
  url: http://host.docker.internal:4312/mcp/
  description: Hungarian legal AI search (jog.gov.hu)
```

Aggiungere `jog-hu` (e opzionalmente `jog-hu-host`) alla lista `tools:` di un agente in `agents.yaml`.
