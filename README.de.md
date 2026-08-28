[English](README.md) | [Magyar](README.hu.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Русский](README.ru.md) | [Nederlands](README.nl.md) | [Polski](README.pl.md) | [Українська](README.uk.md) | [Svenska](README.sv.md) | [Italiano](README.it.md) | [日本語](README.ja.md) | [中文](README.zh.md) | [한국어](README.ko.md) | [Kiswahili](README.sw.md)

# QuorumAI

QuorumAI ist ein modulares, selbst gehostetes Multi-Agent-KI-Orchestrierungssystem, das auf LangGraph aufbaut. Es läuft vollständig in Docker, verbindet sich mit allen gängigen Messaging-Plattformen, unterstützt Sprachinteraktion, Smart-Home-Steuerung und simuliert ein mehrrolliges KI-„Unternehmen" mit Langzeitgedächtnis und autonomer Aufgabenausführung.

![Python 3.11](https://img.shields.io/badge/Python-3.11-blue.svg) ![Docker](https://img.shields.io/badge/Docker-Compose-2496ED.svg)

---

## Was ist QuorumAI?

QuorumAI verwandelt ein oder mehrere LLMs in ein Team von KI-Agenten, das:

- Fragen beantwortet, Nachrichten vorliest und Smart-Home-Geräte steuert — ausgelöst über Mikrofon, Telegram, Matrix, Discord, Slack, Signal, WhatsApp, Viber oder IRC.
- Arbeit zwischen spezialisierten Rollen delegiert (CEO, Entwickler, Vertrieb) und mit Qdrant-Vektorsuche sitzungsübergreifendes Langzeitgedächtnis pflegt.
- Autonome Aufgaben über einen Heartbeat-Scheduler ausführt, bei Bedarf menschliche Genehmigung anfordert (HITL) und jede externe Fähigkeit als MCP-Server (Model Context Protocol) bereitstellt.

Alles wird in YAML konfiguriert — kein Code muss geändert werden, um Modelle auszutauschen, Agenten hinzuzufügen oder neue Werkzeuge einzubinden.

---

## Schnellinstallation

### Einzeiler (empfohlen)

Das Bootstrap-Installationsprogramm prüft, ob Python 3 und Docker vorhanden sind, installiert sie falls nötig und startet dann den interaktiven QuorumAI-Installer.

**Linux / macOS:**
```bash
curl -fsSL https://raw.githubusercontent.com/fulopjozsef86/QuorumAI/main/install.sh | bash
```

**Windows (PowerShell — als Administrator ausführen):**
```powershell
irm https://raw.githubusercontent.com/fulopjozsef86/QuorumAI/main/install.ps1 | iex
```

Oder laden Sie `install.bat` / `install.ps1` aus dem Repository herunter und doppelklicken Sie darauf.

> **Hinweis:** Unter Linux installiert das Bootstrap-Skript Docker Engine aus dem offiziellen Docker-Repository (apt/dnf/yum je nach Distribution) und fügt Ihren Benutzer der Gruppe `docker` hinzu. Danach ist eine Ab- und Anmeldung erforderlich. Unter macOS und Windows wird Docker Desktop installiert und Sie werden aufgefordert, es vor dem Fortfahren zu starten.

---

### Python 3 und Docker bereits vorhanden?

Klonen Sie das Repository und führen Sie den interaktiven Installer direkt aus — kein pip oder zusätzliche Abhängigkeiten erforderlich:

```bash
git clone https://github.com/fulopjozsef86/QuorumAI.git
cd QuorumAI
python3 install.py
```

Der Installer:
- Bietet eine interaktive Modulauswahl (Orchestrator, Bridges, Sprache, GUI usw.).
- Schreibt `.env` aus Ihren Antworten, erstellt `data/`-Bind-Mount-Verzeichnisse und führt `docker compose up -d` aus.
- Die Benutzeroberfläche des Installers ist in 16 Sprachen verfügbar.

**Satellite-Modus** — Mikrofon, Bridges oder MCP-Server auf einem separaten Gerät betreiben:
```bash
python3 install.py   # wählen Sie "Satellite" wenn gefragt
```

---

## Schnellstart (manuell)

```bash
git clone https://github.com/your-org/QuorumAI.git
cd QuorumAI

# Gemeinsames Docker-Netzwerk erstellen (einmal pro Host):
docker network create quorum-net

cp .env.example .env
# .env bearbeiten — COMPOSE_PROFILES und benötigte API-Schlüssel setzen

docker compose up -d
```

Prüfen, ob der Orchestrator läuft:

```bash
curl http://localhost:8000/health
```

Testnachricht senden:

```bash
curl -X POST http://localhost:8000/invoke \
  -H 'Content-Type: application/json' \
  -d '{"message": "Hello, introduce yourself."}'
```

GUI aufrufen: `http://localhost:3000`

---

## Architektur

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

Jede Schicht lebt in einem eigenen Verzeichnis mit eigenem `compose.yml`. Die Root-`compose.yml` fasst alle Schichten über `include:` und Docker Compose-Profile zusammen — Sie starten nur, was Sie brauchen.

---

## Funktionen

### Kern-Orchestrierung

- **LangGraph-Laufzeit** — Zustandsmaschinen-Agent-Graph, natives HITL-Checkpointing, `AsyncPostgresSaver`.
- **FastAPI-HTTP-API** — `POST /invoke`, `GET /health`, Streaming, Webhook-Empfänger, Push-Benachrichtigungs-Relay.
- **agents.yaml** — Agenten in YAML deklarieren: Name, Rolle, Provider, Modell, Systemprompt-Pfad, Werkzeuge.
- **Hot-Reload** — `POST /agents/reload` lädt `agents.yaml` ohne Container-Neustart neu.
- **MCP-Werkzeugprotokoll** — jede externe Fähigkeit ist ein MCP-Server; Agenten entdecken Werkzeuge automatisch.
- **Qdrant-Vektorspeicher** — hybride semantische + BM42-Lexikalsuche, mehrsprachige E5-Large-Embeddings, agentenbezogene Collections, Kosinus-Deduplizierung, MMR-diversifizierter Abruf.
- **Nächtliche Gedächtniskonsolidierung** — geplanter „Traum-Job" destilliert PostgreSQL-Sitzungshistorie in langfristige Qdrant-Fakten; führt Fortschritte zusammen, entfernt veraltete flüchtige Einträge; Zustand in PostgreSQL nachverfolgt.
- **PostgreSQL** — LangGraph `AsyncPostgresSaver` Checkpointer + Aufgaben- und Kommentartabellen.
- **Wissensgraph** — FalkorDB (Redis-kompatibel), benutzerspezifische Cypher-Abfragen, automatische Entitätsextraktion.

### LLM-Provider (pro Agent, konfiguriert in agents.yaml)

| Lokal | Cloud |
|---|---|
| Ollama (Standard, kein Schlüssel nötig) | Anthropic Claude |
| llama.cpp | OpenAI |
| LM Studio | OpenRouter |
| vLLM | Google Gemini |
| Docker Model Runner | Grok (xAI) |
| Unsloth Studio | DeepSeek |
| | Mistral AI |
| | Together AI |
| | Fireworks AI |
| | Zhipu AI / Z.AI |
| | Eden AI (Aggregator) |
| | NVIDIA NIM (kostenlose Stufe verfügbar) |

Für den Start ist kein API-Schlüssel erforderlich — Ollama läuft lokal und kostenlos.

**Provider-Pools** — mehrere identische lokale Server (z. B. sechs Ollama-Maschinen) können zu einem benannten Pool zusammengefasst werden. Der Orchestrator verteilt Anfragen per Least-Connections-Algorithmus; scheitern alle Pool-Mitglieder, fällt er auf die reguläre Fallback-Kette zurück. Konfiguration in `providers.yaml`, verwaltbar über den GUI-Tab „Provider".

### Multi-Agent-Unternehmenssimulation

- Rollenbasierte Agenten: CEO, Entwickler, Vertrieb und beliebige benutzerdefinierte Rollen.
- Der Dispatcher-Agent leitet eingehende Anfragen automatisch an den richtigen Spezialisten weiter.
- Pipeline-Agenten: Planer → Ausführer → Prüfer-Schleifen mit gemeinsamem Zustand.
- **Autonome (Deep) Agenten** — `deep: true` an einem Agent oder Pipeline-Stage aktiviert die eingebaute LangGraph-ReAct-Schleife. Der Agent plant, führt aus und iteriert selbstständig — er ruft Werkzeuge wiederholt auf, bis die Aufgabe erledigt ist oder das optionale Werkzeugaufruf-Limit erreicht ist (`deep_max_steps`, 0 = unbegrenzt). Einstellbar pro Agent und pro Pipeline-Stage; Schalter im GUI Agent Builder verfügbar.
- Skill-Bibliothek: Markdown-Skill-Dateien, lazy-loaded pro Agent, Community-Marktplatz zum Teilen.
- Gemeinsamer Arbeitsbereich: Agenten können einen gemeinsamen Dateibereich lesen und beschreiben.
- **Admin-Werkzeuge** — Agenten mit der Rolle `admin` können zur Laufzeit Agenten, Skills, MCP-Server, Cron-Jobs und Heartbeat-Zeitpläne über `system-admin`-Werkzeuge erstellen und löschen. Jede Schreibaktion erfordert HITL-Genehmigung vor der Ausführung.

### Aufgabenverwaltung und Autonomie

- Kanban-Aufgabentafel mit Unteraufgaben und Kommentaren (PostgreSQL-basiert).
- Heartbeat-Scheduler: Agenten übernehmen automatisch ausstehende Aufgaben (standardmäßig alle 5 Minuten).
- Autonome Aufgabenausführung mit HITL-Genehmigungsschranken (Telegram `/approve`, GUI-Schaltflächen).
- Push-Benachrichtigungen: Telegram, Home Assistant `notify`, Web-Push (VAPID). Aufgaben können ein `notify_channel`-Feld angeben, damit die Abschluss-Benachrichtigung immer an die richtige Bridge gesendet wird – unabhängig davon, welche Session die Aufgabe erstellt hat. Agenten können mit `list_notify_channels()` die verfügbaren Kanäle zur Laufzeit abfragen.

**Mehrtägige Aufgaben** — das empfohlene Muster für langwierige Arbeiten über Stunden oder Tage:
1. Erstelle eine Aufgabe mit Titel und Beschreibung (per Chat, Telegram oder dem GUI-Kanban-Board).
2. Der Agent (oder du) ruft `set_subtasks` auf, um sie in benannte Schritte aufzuteilen.
3. Jeder Heartbeat-Lauf nimmt die nächste ausstehende Unteraufgabe auf, erledigt sie und stoppt — die einzelnen LLM-Sitzungen bleiben kurz und fokussiert.
4. Fortschritt, Entscheidungen und Zwischenergebnisse werden als Aufgabenkommentare gespeichert, sodass jeder folgende Lauf den vollständigen Kontext hat.
5. Wenn alle Unteraufgaben erledigt sind, schließt der Agent die Aufgabe und sendet eine Abschlussbenachrichtigung.

Dieses Muster funktioniert ohne Codeänderungen — es baut auf den vorhandenen Aufgaben-Tools (`set_subtasks`, `get_next_subtask`, `complete_subtask`) auf, auf die jeder Agent mit der `tasks`-Tool-Quelle Zugriff hat.

### Sicherheitsüberwachung (Quadrumviratus)

Eine optionale, agentenspezifische Schicht, die jeden riskanten Werkzeugaufruf vor der Ausführung überprüft. Aktiviert mit `guardian: true` in `agents.yaml`; Agenten ohne dieses Flag sind nicht betroffen.

- **Guardian** — ein isolierter LLM-Aufruf (ohne Werkzeuge), der Werkzeugname und Argumente auswertet und zurückgibt: `NONE` (fortfahren), `SOFT VETO: Begründung` (Mensch entscheidet) oder `HARD VETO: Begründung` (sofortige Blockierung).
- **Arbiter** — wird bei SOFT VETO aktiviert; erstellt einen Markdown-Analysebericht und setzt den Graphen per LangGraph `interrupt()` aus. Der Operator genehmigt oder lehnt per Telegram `/approve` oder der GUI ab — gleicher Ablauf wie HITL.
- **Historiker** — ein Heartbeat-Job, der das In-Memory-Guardian-Auditlog liest und einen strukturierten Bericht in die `historian_reports`-PostgreSQL-Tabelle schreibt.
- **Risikoeinstufung** — MCP-Server erhalten in `mcps.yaml` die Kennzeichnung `risk: low` oder `risk: high`. Speicher-, Aufgaben- und Genehmigungswerkzeuge sind immer von der Überprüfung ausgenommen.

```yaml
# agents.yaml
agents:
  - name: ceo
    guardian: true
    guardian_provider: anthropic        # optional — erbt den Agent-Provider, wenn leer
    guardian_model: claude-haiku-4-5-20251001
    arbiter_provider: anthropic
    arbiter_model: claude-sonnet-4-6
```

```yaml
# mcps.yaml
servers:
  - name: playwright
    risk: high        # alle playwright-Werkzeuge erfordern Guardian-Genehmigung
  - name: hu-tools
    risk: low         # Wetter, Nachrichten — ohne Überprüfung durchgeleitet
```

Der `/guardian/log`-Endpoint gibt das Live-Auditlog zurück (letzte 1 000 Entscheidungen).

### Authentifizierung und Multi-Mandantenfähigkeit

| Modus | Beschreibung |
|---|---|
| `AUTH_MODE=none` | Offen — keine Authentifizierung (Standard, für lokale Nutzung geeignet) |
| `AUTH_MODE=local` | Bearer-Token; Benutzer: `LOCAL_USERS=benutzer1:passwort1,...` |
| `AUTH_MODE=sso` | Keycloak OIDC/JWT oder beliebiger OIDC-Provider (Auth0, Okta, Authelia, …) |

**Trennung pro Benutzer.** Im Mehrbenutzerbetrieb sind Speicher und
Wissensgraph jedes Benutzers getrennt: das Langzeitgedächtnis landet in der
eigenen Qdrant-Collection, der Graph im eigenen `scope` — ein Lesevorgang sieht
die eigenen Daten und die vom Administrator gepflegte gemeinsame Ebene, niemals
die eines anderen Benutzers. Auch die nächtliche Wartung läuft **pro Benutzer**.

### Beobachtbarkeit

- Pipeline-Traces mit Token- und Kostenprotokollierung pro Durchlauf.
- Wasserfall-Ansicht im GUI-Tab „Observability".
- Automatische Trace-Bereinigung gesteuert durch `TRACE_RETENTION_DAYS`.

### Webhook-Empfänger

Akzeptiert signierte Webhooks von: GitHub, Gitea, Drone CI, Grafana, n8n, Slack, ERPNext, Twenty CRM, Zammad, Tiledesk, Uptime Kuma, Wekan, Umami, Duplicati, BorgWarehouse.

### Backup und Wiederherstellung

Alle Laufzeitdaten liegen als Bind-Mounts unter `data/`; alle Konfigurationen in YAML-Dateien — kein versteckter Zustand in Containern.

**Backup erstellen** (enthält `.env` + `data/`):

```bash
sudo python3 backup.py backup                    # interaktiv, automatischer Dateiname
sudo python3 backup.py backup /srv/backup.tgz    # expliziter Ausgabepfad
```

**Wiederherstellen**:

```bash
python3 backup.py restore /srv/backup.tgz           # ins aktuelle Verzeichnis
python3 backup.py restore /srv/backup.tgz /opt/qai  # in bestimmtes Verzeichnis
```

Unter Linux / macOS mit `sudo` ausführen, um Dateieigentümer zu erhalten. Unter Windows nicht erforderlich.

---

## Bridges

| Bridge | Transport | Compose-Profil |
|---|---|---|
| Telegram | Bot API, async (python-telegram-bot) | `telegram` |
| Matrix | matrix-nio, Raumebene | `matrix` |
| Discord | discord.py, Slash-Commands | `discord` |
| IRC | irc3 asyncio, Multi-Channel | `irc` |
| WhatsApp | Meta Cloud API Webhook | `whatsapp` |
| Slack | slack-bolt Socket Mode | `slack` |
| Signal | signal-cli REST API Polling | `signal` |
| Viber | FastAPI Webhook, Tastaturschaltflächen | `viber` |

Jede Bridge bietet `/notify` (für Push-Benachrichtigungen vom Orchestrator) und `/health` (Liveness-Check) sowie Allowlists für Absender und Kanäle. Telegram und die GUI unterstützen auch den HITL-`/approve`-Ablauf. Alle Bridges unterstützen die benutzerspezifische Sprachumschaltung über den Befehl `/language`; die Einstellung wird in PostgreSQL gespeichert und überlebt Container-Neustarts.

---

## Sprache

### Mikrofon-Bridge (lokales Mikrofon)

Compose-Profil: `mic`

- openWakeWord — konfigurierbares Aktivierungswort (Standard: „Ok Szif").
- Wyoming Whisper — lokale STT, keine Cloud erforderlich.
- Wyoming Piper — lokale TTS.
- PulseAudio-Socket-Einbindung für Linux-Desktops.

**Plattformhinweise:**

- **Linux** — Der Installer erkennt Ihre UID und bindet automatisch den richtigen PulseAudio-Socket ein (`/run/user/<uid>/pulse`).
- **macOS / Windows** — Docker Desktop leitet keine Audiogeräte weiter. Der Installer schreibt stattdessen eine PulseAudio-TCP-Konfiguration. Richten Sie PulseAudio im TCP-Modus ein, bevor Sie den Mic-Container starten:
  - macOS: `brew install pulseaudio && pulseaudio --load=module-native-protocol-tcp --exit-idle-time=-1 --daemon`
  - Windows (WSL2): `sudo apt install pulseaudio && pulseaudio --load=module-native-protocol-tcp --exit-idle-time=-1 --start`
  - Windows (nativ): PulseAudio für Windows herunterladen, `module-native-protocol-tcp` in `default.pa` aktivieren, Port 4713 in der Firewall freigeben.

### Home Assistant Voice PE

Compose-Profil: `ha`

QuorumAI registriert sich als Konversationsagent in Home Assistant. HA Assist übernimmt Aktivierungswort-Erkennung, Whisper STT und Piper TTS auf HA-Seite; QuorumAI übernimmt Reasoning und Werkzeugaufrufe.

### STT- und TTS-Werkzeuge (agentaufrufbar)

Compose-Profil: `stt-tts`

Stellt Whisper und Piper als HTTP-APIs bereit, die Agenten als `system-stt`- und `system-tts`-Werkzeuge aufrufen können.

---

## GUI

Compose-Profil: `gui` — verfügbar unter `http://localhost:3000`

Entwickelt mit React, Vite und Tailwind CSS.

| Tab | Beschreibung |
|---|---|
| Chat | Nachrichten an jeden Agenten senden; gestreamte Antworten anzeigen |
| Agent Builder | Visuelles Unternehmensdiagramm; Agenten und Rollen erstellen und bearbeiten |
| Skill Editor | Markdown-Skill-Dateien erstellen und verwalten |
| Aufgaben | Kanban-Board; Unteraufgaben-Baum; Kommentare; Genehmigungsschaltflächen |
| Provider | Echtzeit-Provider-Status und verfügbare Modellliste |
| Heartbeat | Scheduler-Zustand; nächste Ausführungszeiten; manueller Trigger |
| Observability | Pipeline-Traces; Token- und Kosten-Wasserfall-Ansicht |

- 16 UI-Sprachen, 14 Themes.
- HITL-Genehmigungsschaltflächen in Chat- und Aufgaben-Tabs integriert.

---

## Installationsdetails

### Voraussetzungen

- Docker Engine 24+ und Docker Compose v2.
- Python 3.8+ für `install.py` — kein pip oder virtualenv erforderlich.
- Für lokale Modelle: Ollama läuft auf dem Host an Port 11434.

### Gemeinsames Netzwerk erstellen (einmal pro Host)

```bash
docker network create quorum-net
```

### Profile auswählen

Profile in `.env` setzen, damit `docker compose up -d` ohne weitere Argumente funktioniert:

```env
COMPOSE_PROFILES=orchestrator,memory,mcp,postgres,telegram,gui
```

Oder explizit übergeben:

```bash
docker compose --profile orchestrator --profile memory --profile gui up -d
```

Verfügbare Profile: `orchestrator`, `memory`, `mcp`, `postgres`, `telegram`, `ha`, `mic`, `gui`, `stt-tts`, `mcp-manager`, `playwright`, `joplin`, `auth`, `email`, `matrix`, `discord`, `irc`, `whatsapp`, `slack`, `signal`, `viber`, `graph`

### Nach Quelländerungen neu erstellen

```bash
# Nur den geänderten Dienst neu bauen:
docker compose build orchestrator

# Ohne andere Container anzufassen neu starten:
docker compose up -d --no-deps orchestrator
```

### Datenverzeichnis-Layout

```
data/
  qdrant/        # Qdrant-Vektoren
  postgres/      # PostgreSQL-Daten
  workspace/     # agentenbezogener Dateiarbeitsbereich
  whisper/       # Whisper-Modell-Cache
  piper/         # Piper-Sprachdateien
  ...
```

Alles unter `data/` ist gitignoriert. Das Sichern dieses Verzeichnisses erhält alle persistenten Zustände.

---

## Konfiguration

Kopieren Sie `.env.example` nach `.env` und füllen Sie das Benötigte aus. Die `.env.example`-Datei enthält eine inline-Dokumentation für jeden Schlüssel.

### Wichtigste Schlüssel

| Schlüssel | Standard | Beschreibung |
|---|---|---|
| `COMPOSE_PROFILES` | — | Kommagetrennte Profile, die gestartet werden |
| `AUTH_MODE` | `none` | `none` / `local` / `sso` |
| `ORCHESTRATOR_PORT` | `8000` | Orchestrator-FastAPI-Port |
| `GUI_PORT` | `3000` | GUI-Port |
| `QDRANT_HTTP_PORT` | `6333` | Qdrant-REST-Port |
| `POSTGRES_PORT` | `5433` | PostgreSQL-Port |
| `POSTGRES_PASSWORD` | `changeme` | PostgreSQL-Passwort — bitte ändern! |
| `TRACE_RETENTION_DAYS` | `14` | Automatisches Löschen von Traces nach N Tagen |
| `ANTHROPIC_API_KEY` | — | Erforderlich bei Anthropic-Provider |
| `OPENROUTER_API_KEY` | — | Erforderlich bei OpenRouter |
| `OPENAI_API_KEY` | — | Erforderlich bei OpenAI |
| `GOOGLE_API_KEY` | — | Erforderlich bei Google Gemini |
| `TELEGRAM_BOT_TOKEN` | — | Erforderlich für Telegram-Bridge |
| `TELEGRAM_CHAT_ID` | — | Telegram-Chat-ID für eingehende Nachrichten |
| `NOTIFY_TELEGRAM_CHAT_ID` | — | Chat-ID für Aufgaben-Abschluss-Benachrichtigungen (entspricht `TELEGRAM_CHAT_ID` falls identisch) |
| `MATRIX_HOMESERVER` | — | Matrix-Server-URL |
| `MATRIX_ACCESS_TOKEN` | — | Matrix-Bot-Zugriffstoken |
| `DISCORD_BOT_TOKEN` | — | Erforderlich für Discord-Bridge |
| `SLACK_BOT_TOKEN` | — | Erforderlich für Slack-Bridge |
| `SLACK_APP_TOKEN` | — | Erforderlich für Slack Socket Mode |
| `SIGNAL_PHONE` | — | Telefonnummer für Signal-Bridge |
| `VIBER_AUTH_TOKEN` | — | Erforderlich für Viber-Bridge |
| `HA_URL` | `http://homeassistant:8123` | Home Assistant-Basis-URL |
| `HA_TOKEN` | — | HA Long-Lived Access Token |
| `IMAP_HOST` | — | IMAP-Server für E-Mail-MCP |
| `SMTP_HOST` | — | SMTP-Server für E-Mail-MCP |
| `FALKORDB_URL` | — | Setzen, um den Wissensgraph zu aktivieren |
| `VAPID_EMAIL` | — | Erforderlich für Web-Push-Benachrichtigungen |
| `VAPID_PRIVATE_KEY` | — | Wird automatisch vom Installer generiert (benötigt das Python-Paket `cryptography`); alternativ: `docker compose exec orchestrator python3 webpush.py` |
| `VAPID_PUBLIC_KEY` | — | Wird zusammen mit dem privaten Schlüssel generiert |
| `HU_TOOLS_PORT` | `4300` | hu-tools-MCP-Port |
| `WHISPER_URL` | `http://whisper-http:8000` | STT-Dienst-URL |
| `PIPER_URL` | `http://piper-http:5000` | TTS-Dienst-URL |
| `ORCHESTRATOR_API_KEY` | — | Wird automatisch vom Installer generiert; Service-zu-Service-Token für Bridges (erforderlich bei `AUTH_MODE=local/sso`) |
| `CONVERSATION_API_KEY` | — | Wird automatisch vom Installer generiert; schützt den HA-Endpunkt `/conversation` (leer = offen) |

Agentenkonfiguration: `orchestrator/agents.yaml`. Vollständige Dokumentation: `.env.example`.

---

## Branchenpakete

Vorgefertigte vertikale Pakete für spezifische Branchen. Jedes Paket enthält Skill-Dateien, empfohlene Agent-Konfigurationen und MCP-Referenzen. Installation über `install.py` oder manuell.

| Paket | Zielgruppe | Hauptfunktionen |
|---|---|---|
| `legal` | Anwaltskanzleien | Dokumentensuche, Vertragsanalyse, ungarische Rechtsrecherche |
| `devops` | IT/DevOps-Unternehmen | Incident-Triage, Runbook-Suche, AIOps mit HITL |
| `agency` | Marketing- & PR-Agenturen | Projektstatus, Lead-Qualifizierung, Brief-Analyse, Kunden-Reporting |

**Manuelle Installation:**
```bash
cp industry-packs/legal/skills/*.md data/skills/
cat industry-packs/legal/agents.yaml
```

**Über Installer:** `python3 install.py` → Ändern → Paket auswählen.

Eigenes Paket erstellen: `industry-packs/_template/` kopieren und `pack.yaml` ausfüllen.

---

## CRM-Integration

Der CRM-MCP (`mcps/crm/`) bietet eine einheitliche Schnittstelle zu mehreren CRM-Systemen über eine austauschbare Adapter-Architektur. Agenten verwenden dieselben Werkzeuge unabhängig vom Backend.

**Unterstützte Adapter:**

| Adapter | System | Typ |
|---|---|---|
| `minicrm` | MiniCRM (ungarischer Marktführer) | Vollständig |
| `hubspot` | HubSpot CRM | Vollständig |
| `pipedrive` | Pipedrive | Vollständig |
| `billingo` | Billingo-Rechnungsstellung | Nur-Lesen |
| `szamlazzhu` | Számlázz.hu-Rechnungsstellung | Nur-Lesen |
| `salesautopilot` | SalesAutopilot (HU Marketing-Automation) | Vollständig |

**Verfügbare Werkzeuge:** `search_entities`, `get_entity`, `create_entity`, `update_entity`, `add_note`, `get_timeline`, `link_entities`, `get_related`, `emit_event`, `list_entity_types`

**Schnellstart:**
```env
CRM_ADAPTER=minicrm
MINICRM_SYSTEM_ID=12345
MINICRM_API_KEY=ihr-schluessel
```

```bash
docker compose --profile crm up -d
```

`crm` zur `tools:`-Liste eines Agenten in `agents.yaml` hinzufügen, um ihm CRM-Zugriff zu geben.

---

## jog.gov.hu MCP — Ungarische Rechtsrecherche

Das jog.gov.hu MCP (`mcps/jog-hu/`) stellt ungarische Rechtsinformationen für KI-Agenten in zwei Betriebsmodi bereit:

**Docker-Modus** (funktioniert immer, kein Playwright erforderlich):

| Werkzeug | Beschreibung |
|---|---|
| `search_njt_laws(keywords)` | Stichwortsuche auf njt.jog.gov.hu — gibt passende Gesetztitel und URLs zurück |
| `get_law_text(law_id, section)` | Vollständiger oder teilweiser Gesetztext von njt.hu (z. B. `"2012. évi I. törvény"`, Abschnitt `"69"`) |
| `list_recent_laws(category, days)` | Aktuelle Gesetze aus dem Magyar Közlöny RSS-Feed |

**Host-Modus** (KI-gestützte Suche, erfordert `host_server.py` auf dem Host-Rechner):

| Werkzeug | Beschreibung |
|---|---|
| `search_law(question)` | Natürlichsprachliche Frage → KI-Antwort + zitierte Gesetzesreferenzen (jog.gov.hu) |

reCAPTCHA v3 bewertet Sitzungen primär nach **IP-Reputation**. Docker-Container-IPs und Cloud/VPS-Server-IPs werden als Rechenzentrumsbereiche eingestuft und erhalten unabhängig von Browser-Fingerabdruck-Anpassungen einen niedrigen Vertrauenswert. Ein Heim- oder Bürorechner mit einer **privaten (Residential) IP** erreicht einen ausreichend hohen Score, um die Prüfung zu bestehen. Eine grafische Oberfläche ist **nicht erforderlich** — der Browser läuft kopflos (headless); die Anzeige spielt keine Rolle.

**Schnellstart (Docker-Werkzeuge — funktioniert immer):**
```bash
docker compose --profile jog-hu up -d
```

**Host-Server starten (KI-Suche — Residential-IP erforderlich):**
```bash
# Funktioniert auf: Heim- oder Büro-Desktop bzw. Laptop (Windows, macOS, Linux)
# Funktioniert NICHT auf: Cloud-/VPS-Servern (Rechenzentrums-IPs von reCAPTCHA gesperrt)
# Grafische Oberfläche NICHT erforderlich — läuft headless

pip install mcp fastmcp httpx playwright playwright-stealth
playwright install chromium

python3 mcps/jog-hu/host_server.py --background   # Daemon starten, Port 4312
python3 mcps/jog-hu/host_server.py --stop          # Daemon stoppen
```

**In `mcps.yaml` eintragen:**
```yaml
- name: jog-hu
  url: http://jog-hu-mcp:4302/mcp/
  description: Hungarian legal search (njt.hu)

# Optional — nur wenn host_server.py läuft:
- name: jog-hu-host
  url: http://host.docker.internal:4312/mcp/
  description: Hungarian legal AI search (jog.gov.hu)
```

`jog-hu` (und optional `jog-hu-host`) zur `tools:`-Liste eines Agenten in `agents.yaml` hinzufügen.

---

## Mitwirken

1. Repository forken und einen Feature-Branch erstellen.
2. Die Schicht- und Compose-Konventionen in `CLAUDE.md` befolgen.
3. Den entsprechenden Testblock in `tests.sh` hinzufügen oder aktualisieren.
4. Pull Request mit einer Beschreibung der hinzugefügten Phase oder Funktion öffnen.

---

## Lizenz
