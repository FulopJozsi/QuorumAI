[English](README.md) | [Magyar](README.hu.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Русский](README.ru.md) | [Nederlands](README.nl.md) | [Polski](README.pl.md) | [Українська](README.uk.md) | [Svenska](README.sv.md) | [Italiano](README.it.md) | [日本語](README.ja.md) | [中文](README.zh.md) | [한국어](README.ko.md) | [Kiswahili](README.sw.md)

# QuorumAI

QuorumAI is een modulair, zelf-gehost multi-agent AI-orkestratiesysteem gebouwd op LangGraph. Het draait volledig in Docker, verbindt zich met alle belangrijke berichtenplatforms, ondersteunt spraakinteractie, smart-home-bediening en simuleert een AI-"bedrijf" met meerdere rollen, langetermijngeheugen en autonome taakuitvoering.

![Python 3.11](https://img.shields.io/badge/Python-3.11-blue.svg) ![Docker](https://img.shields.io/badge/Docker-Compose-2496ED.svg)

---

<div align="center">
  <video src="https://github.com/user-attachments/assets/7bd072b6-75cd-4345-9fe0-fa2f3ee0566e" controls width="800"></video>

  <p><b><a href="https://license.quorumai.eu/portal/register">Begin hier — meld je aan voor een gratis proefperiode van 30 dagen »</a></b></p>
</div>

---

## Wat is QuorumAI?

QuorumAI verandert één of meer LLM's in een team van AI-agents dat:

- Vragen beantwoordt, nieuws voorleest en smart-home-apparaten bedient — geactiveerd via microfoon, Telegram, Matrix, Discord, Slack, Signal, WhatsApp, Viber of IRC.
- Werk delegeert tussen gespecialiseerde rollen (CEO, ontwikkelaar, verkoop) en langetermijngeheugen bijhoudt tussen sessies via Qdrant vectorzoeken.
- Autonoom taken uitvoert via een heartbeat-planner, menselijke goedkeuring vraagt wanneer nodig (HITL) en elke externe mogelijkheid als MCP-server (Model Context Protocol) beschikbaar stelt.

Alles wordt geconfigureerd in YAML. Er zijn geen codewijzigingen nodig om modellen te wisselen, agents toe te voegen of nieuwe tools aan te sluiten.

---

## Snelle installatie

### Één regel (aanbevolen)

Het bootstrap-installatieprogramma controleert of Python 3 en Docker aanwezig zijn, installeert ze indien nodig en start daarna het interactieve QuorumAI-installatieprogramma.

**Linux / macOS:**
```bash
curl -fsSL https://raw.githubusercontent.com/FulopJozsi/QuorumAI/main/install.sh | bash
```

**Windows (PowerShell — uitvoeren als Administrator):**
```powershell
irm https://raw.githubusercontent.com/FulopJozsi/QuorumAI/main/install.ps1 | iex
```

Of download `install.bat` / `install.ps1` uit de repository en dubbelklik erop.

> **Opmerking:** Op Linux installeert bootstrap Docker Engine vanuit de officiële Docker-repository (apt/dnf/yum afhankelijk van de distributie) en voegt uw gebruiker toe aan de groep `docker`. Daarna is opnieuw inloggen vereist. Op macOS en Windows installeert het Docker Desktop en vraagt u dit te starten voordat u verdergaat.

---

### Heeft u Python 3 en Docker al?

Kloon de repository en voer het interactieve installatieprogramma direct uit — pip of extra afhankelijkheden zijn niet nodig:

```bash
git clone https://github.com/FulopJozsi/QuorumAI.git
cd QuorumAI
python3 install.py
```

Het installatieprogramma:
- Biedt een interactieve modulekiezer (orchestrator, bridges, spraak, GUI en meer).
- Schrijft `.env` op basis van uw antwoorden, maakt `data/` bind-mount-mappen aan en voert `docker compose up -d` uit.
- De interface van het installatieprogramma is beschikbaar in 16 talen.

**Satellite-modus** — microfoon, bridges of MCP-servers uitvoeren op een aparte machine:
```bash
python3 install.py   # kies "Satellite" wanneer gevraagd
```

---

## Snel starten

```bash
git clone https://github.com/FulopJozsi/QuorumAI.git
cd QuorumAI
python3 install.py
```

Controleer of de orkestrator actief is:

```bash
curl http://localhost:8000/health
```

Testbericht sturen:

```bash
curl -X POST http://localhost:8000/invoke \
  -H 'Content-Type: application/json' \
  -d '{"message": "Hello, introduce yourself."}'
```

GUI beschikbaar op: `http://localhost:3000`

---

## Architectuur

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

Elke laag bevindt zich in zijn eigen map met eigen `compose.yml`. De root-`compose.yml` bundelt alle lagen via `include:` en Docker Compose-profielen — u start alleen wat u nodig heeft.

---

## Functies

### Kernorkestratie

- **LangGraph-runtime** — toestandsmachine-agentgraph, native HITL-checkpointing, `AsyncPostgresSaver`.
- **FastAPI HTTP API** — `POST /invoke`, `GET /health`, streaming, webhook-ontvanger, pushmeldingdoorschakeling.
- **agents.yaml** — declareer agents in YAML: naam, rol, provider, model, systeempromptpad, tools.
- **Hot-reload** — `POST /agents/reload` herlaadt `agents.yaml` zonder containerherstart.
- **MCP-toolprotocol** — elke externe mogelijkheid is een MCP-server; agents ontdekken tools automatisch.
- **Qdrant vectorgeheugen** — hybride semantisch + BM42 lexicaal zoeken, meertalige E5-Large-embeddings, agentspecifieke collecties, cosinus-deduplicatie, MMR-gediversifieerd ophalen.
- **Nachtelijke geheugenconsolidatie** — geplande droomtaak destilleert PostgreSQL-sessiegeschiedenis naar langetermijn Qdrant-feiten; samenvoegen van progressies, verwijderen van verouderde vluchtige vermeldingen; toestand bijgehouden in PostgreSQL.
- **PostgreSQL** — `AsyncPostgresSaver`-checkpointer + taken- en commentaartabellen.
- **Kennisgraaf** — FalkorDB (Redis-compatibel), gebruikersspecifieke Cypher-query's, automatische entiteitsextractie.

### LLM-providers (per agent, geconfigureerd in agents.yaml)

| Lokaal | Cloud |
|---|---|
| Ollama (standaard, geen sleutel nodig) | Anthropic Claude |
| llama.cpp | OpenAI |
| LM Studio | OpenRouter |
| vLLM | Google Gemini |
| Docker Model Runner | Grok (xAI) |
| Unsloth Studio | DeepSeek |
| | Mistral AI |
| | Together AI |
| | Fireworks AI |
| | Zhipu AI / Z.AI |
| | Eden AI (aggregator) |
| | NVIDIA NIM (gratis niveau beschikbaar) |

Er is geen API-sleutel nodig om te beginnen — Ollama draait lokaal en gratis.

**Provider-pools** — meerdere identieke lokale servers (bijv. zes Ollama-machines) kunnen worden gegroepeerd in een benoemde pool. De orkestrator verdeelt verzoeken via least-connections taakverdeling; als alle poolleden falen, valt het terug op de normale fallback-keten. Geconfigureerd in `providers.yaml` en beheersbaar via het tabblad Providers van de GUI.

### Multi-agent bedrijfssimulatie

- Rolgebaseerde agents: CEO, ontwikkelaar, verkoop en elke aangepaste rol.
- De dispatcher-agent stuurt inkomende verzoeken automatisch naar de juiste specialist.
- Pipeline-agents: planner → uitvoerder → beoordelaar-lussen met gedeelde toestand.
- **Autonome (Deep) agents** — stel `deep: true` in op een agent of pipeline-fase om de ingebouwde LangGraph ReAct-lus te activeren. De agent plant, voert uit en itereert autonoom — hij roept tools herhaaldelijk aan totdat de taak klaar is of de optionele limiet voor toolaanroepen bereikt is (`deep_max_steps`, 0 = onbeperkt). Instelbaar per agent en per fase; schakelaar beschikbaar in de GUI Agent Builder.
- Vaardighedenbibliotheek: Markdown-vaardigheidsbestanden, lazy-load per agent, gemeenschapsmarktplaats voor delen.
- Gedeelde werkruimte: agents kunnen een gedeeld bestandsgebied lezen en schrijven.
- **Beheerhulpmiddelen** — agents met de rol `admin` kunnen agents, skills, MCP-servers, cron-jobs en heartbeat-planningen aanmaken en verwijderen tijdens runtime via `system-admin`-hulpmiddelen. Elke schrijfactie vereist HITL-goedkeuring voor uitvoering.

### Taakbeheer en autonomie

- Kanban-takenbord met subtaken en opmerkingen (PostgreSQL-gebaseerd).
- Heartbeat-planner: agents nemen automatisch lopende taken op (standaard elke 5 minuten).
- Autonome uitvoering met HITL-goedkeuringspoorten (Telegram `/approve`, GUI-knoppen).
- Pushmeldingen: Telegram, Home Assistant `notify`, web push (VAPID). Taken kunnen een `notify_channel`-veld opgeven zodat de voltooiingsmelding altijd naar de juiste bridge gaat, ongeacht welke sessie de taak heeft aangemaakt. Agents kunnen `list_notify_channels()` aanroepen om beschikbare kanalen tijdens runtime te ontdekken.

**Meerdaagse taken** — het aanbevolen patroon voor langdurig werk dat uren of dagen beslaat:
1. Maak een taak aan met een titel en beschrijving (via chat, Telegram of het GUI Kanban-bord).
2. De agent (of jij) roept `set_subtasks` aan om het op te splitsen in benoemde stappen.
3. Elke heartbeat-run pakt de volgende openstaande subtaak op, voltooit deze en stopt — individuele LLM-sessies blijven kort en gefocust.
4. Voortgang, beslissingen en tussenresultaten worden opgeslagen als taakopmerkingen zodat elke volgende run volledige context heeft van wat eerder is gebeurd.
5. Wanneer alle subtaken klaar zijn, sluit de agent de taak en stuurt een voltooiingsmelding.

Dit patroon werkt zonder codewijzigingen — het is gebouwd op de bestaande taaktools (`set_subtasks`, `get_next_subtask`, `complete_subtask`) waartoe elke agent met de `tasks`-toolbron toegang heeft.

### Veiligheidstoezicht (Quadrumviraat)

Een optionele per-agent laag die elke risicovolle gereedschapsaanroep controleert voordat deze wordt uitgevoerd. Activeer met `guardian: true` in `agents.yaml`; agenten zonder deze vlag worden niet beïnvloed.

- **Guardian** — een geïsoleerde LLM-aanroep (zonder gereedschappen) die de naam en argumenten van het gereedschap beoordeelt en teruggeeft: `NONE` (doorgaan), `SOFT VETO: reden` (menselijke beslissing vereist) of `HARD VETO: reden` (onmiddellijke blokkering).
- **Arbiter** — geactiveerd bij SOFT VETO; genereert een Markdown-analyserapport en onderbreekt de graph via LangGraph `interrupt()`. De operator keurt goed of weigert via Telegram `/approve` of de GUI — dezelfde stroom als HITL.
- **Historicus** — een heartbeat-taak die het Guardian-auditlog in het geheugen leest en een gestructureerd rapport schrijft naar de PostgreSQL-tabel `historian_reports`.
- **Risicoclassificatie** — MCP-servers worden in `mcps.yaml` gelabeld met `risk: low` of `risk: high`. Geheugen-, taak- en goedkeuringsgereedschappen zijn altijd uitgesloten van controle.

```yaml
# agents.yaml
agents:
  - name: ceo
    guardian: true
    guardian_provider: anthropic        # optioneel — erft provider van agent als leeg
    guardian_model: claude-haiku-4-5-20251001
    arbiter_provider: anthropic
    arbiter_model: claude-sonnet-4-6
```

```yaml
# mcps.yaml
servers:
  - name: playwright
    risk: high        # alle playwright-gereedschappen vereisen Guardian-goedkeuring
  - name: hu-tools
    risk: low         # weer, nieuws — doorgestuurd zonder controle
```

Het `/guardian/log`-endpoint retourneert het live auditlog (laatste 1.000 beslissingen).

### Authenticatie en multi-tenancy

| Modus | Beschrijving |
|---|---|
| `AUTH_MODE=none` | Open — geen authenticatie (standaard, geschikt voor lokaal gebruik) |
| `AUTH_MODE=local` | Bearer-token; gebruikers gedefinieerd in `LOCAL_USERS=gebruiker1:wachtwoord1,...` |
| `AUTH_MODE=sso` | Keycloak OIDC/JWT, of elke OIDC-provider (Auth0, Okta, Authelia, …) |

**Isolatie per gebruiker.** In multi-usermodus zijn het geheugen en de
kennisgraaf van elke gebruiker gescheiden: het langetermijngeheugen komt in de
eigen Qdrant-collectie en de graaf in de eigen `scope` — een leesactie ziet de
eigen gegevens en de door de beheerder samengestelde gedeelde laag, nooit die van
een andere gebruiker. Ook het nachtelijke onderhoud loopt **per gebruiker**.

### Observeerbaarheid

- Pipeline-traces met token- en kostenregistratie per beurt.
- Watervalweergave in het tabblad Monitoring van de GUI.
- Automatische opschoning van traces via `TRACE_RETENTION_DAYS`.

### Webhook-ontvanger

Accepteert ondertekende webhooks van: GitHub, Gitea, Drone CI, Grafana, n8n, Slack, ERPNext, Twenty CRM, Zammad, Tiledesk, Uptime Kuma, Wekan, Umami, Duplicati, BorgWarehouse.

### Back-up en configuratiepersistentie

Alle runtime-gegevens staan als bind mounts in `data/`; alle configuratie in YAML-bestanden — geen verborgen toestand in containers.

**Back-up maken** (inclusief `.env` + `data/`):

```bash
sudo python3 backup.py backup                 # interactief, automatische bestandsnaam
sudo python3 backup.py backup /srv/backup.tgz # expliciet uitvoerpad
```

**Herstellen**:

```bash
python3 backup.py restore /srv/backup.tgz          # herstel naar huidige map
python3 backup.py restore /srv/backup.tgz /opt/qai # herstel naar specifieke map
```

Voer op Linux / macOS uit met `sudo` om bestandseigendom te bewaren. Op Windows is dit niet nodig.

---

## Bridges

| Bridge | Transport | Compose-profiel |
|---|---|---|
| Telegram | Bot API, async (python-telegram-bot) | `telegram` |
| Matrix | matrix-nio, kamer-niveau | `matrix` |
| Discord | discord.py, slash commands | `discord` |
| IRC | irc3 asyncio, meerdere kanalen | `irc` |
| WhatsApp | Meta Cloud API webhook | `whatsapp` |
| Slack | slack-bolt Socket Mode | `slack` |
| Signal | signal-cli REST API polling | `signal` |
| Viber | FastAPI webhook, toetsenbordknoppen | `viber` |

Elke bridge biedt `/notify` (pushmeldingen van de orkestrator) en `/health` (liveness-controle), en ondersteunt toestemmingslijsten voor afzenders en kanalen. Telegram en de GUI ondersteunen ook de HITL `/approve`-stroom. Alle bridges ondersteunen het wisselen van taal per gebruiker via het commando `/language`; de voorkeur wordt opgeslagen in PostgreSQL en blijft behouden na herstart van containers.

---

## Spraak

### Microfoonbrug (lokale microfoon)

Compose-profiel: `mic`

- openWakeWord — instelbaar activeringswoord (standaard: "Ok Szif").
- Wyoming Whisper — lokale STT, geen cloud vereist.
- Wyoming Piper — lokale TTS.
- PulseAudio-socketkoppeling voor Linux-desktops.

**Platformopmerkingen:**

- **Linux** — het installatieprogramma detecteert uw UID en koppelt automatisch de juiste PulseAudio-socket (`/run/user/<uid>/pulse`).
- **macOS / Windows** — Docker Desktop geeft geen audioapparaten door. Het installatieprogramma schrijft in plaats daarvan een PulseAudio TCP-configuratie. Stel PulseAudio in TCP-modus in voordat u de mic-container start:
  - macOS: `brew install pulseaudio && pulseaudio --load=module-native-protocol-tcp --exit-idle-time=-1 --daemon`
  - Windows (WSL2): `sudo apt install pulseaudio && pulseaudio --load=module-native-protocol-tcp --exit-idle-time=-1 --start`
  - Windows (native): download PulseAudio voor Windows, verwijder het commentaar bij `module-native-protocol-tcp` in `default.pa`, sta poort 4713 toe in de firewall.

### Home Assistant Voice PE

Compose-profiel: `ha`

QuorumAI registreert zich als gesprekagent in Home Assistant. HA Assist verwerkt activeringswoorddetectie, Whisper STT en Piper TTS aan de HA-kant; QuorumAI verwerkt redenering en toolaanroepen.

### STT en TTS tools (agentoproepbaar)

Compose-profiel: `stt-tts`

Stelt Whisper en Piper beschikbaar als HTTP-API's die agents kunnen aanroepen als `system-stt`- en `system-tts`-tools.

---

## GUI

Compose-profiel: `gui` — beschikbaar op `http://localhost:3000`

Gebouwd met React, Vite en Tailwind CSS.

| Tabblad | Beschrijving |
|---|---|
| Chat | Berichten sturen naar elke agent; gestreamde antwoorden bekijken |
| Agent Builder | Visueel bedrijfsdiagram; agents en rollen aanmaken en bewerken |
| Vaardigheidseditor | Markdown-vaardigheidsbestanden aanmaken en beheren |
| Taken | Kanban-bord; subtaakboom; opmerkingen; goedkeuringsknoppen |
| Providers | Realtime providerstatus en beschikbare modellenlijst |
| Heartbeat | Plannerstatus; volgende uitvoertijden; handmatige trigger |
| Observeerbaarheid | Pipeline-traces; token- en kostenwaterval |

- 16 talen in de UI, 14 thema's.
- HITL-goedkeuringsknoppen geïntegreerd in de tabbladen Chat en Taken.

---

## Installatiedetails

### Vereisten

- Docker Engine 24+ en Docker Compose v2.
- Python 3.8+ voor `install.py` — geen pip of virtualenv vereist.
- Voor lokale modellen: Ollama actief op de host op poort 11434.

### Gedeeld netwerk aanmaken (eenmalig per host)

```bash
docker network create quorum-net
```

### Profielen selecteren

Stel profielen in `.env` in zodat gewoon `docker compose up -d` werkt:

```env
COMPOSE_PROFILES=orchestrator,memory,mcp,postgres,telegram,gui
```

Of geef ze expliciet op:

```bash
docker compose --profile orchestrator --profile memory --profile gui up -d
```

Beschikbare profielen: `orchestrator`, `memory`, `mcp`, `postgres`, `telegram`, `ha`, `mic`, `gui`, `stt-tts`, `mcp-manager`, `playwright`, `joplin`, `auth`, `email`, `matrix`, `discord`, `irc`, `whatsapp`, `slack`, `signal`, `viber`, `graph`

### Gegevensmap indeling

```
data/
  qdrant/        # Qdrant-vectoren
  postgres/      # PostgreSQL-gegevens
  workspace/     # per-agent bestandswerkruimte
  whisper/       # Whisper-modelcache
  piper/         # Piper-spraakbestanden
  ...
```

Alles onder `data/` is gegitignored. Het maken van een back-up van deze map bewaart alle persistente toestand.

---

## Configuratie

Kopieer `.env.example` naar `.env` en vul in wat u nodig heeft. Het bestand `.env.example` bevat inline documentatie voor elke sleutel.

### Belangrijkste sleutels

| Sleutel | Standaard | Beschrijving |
|---|---|---|
| `COMPOSE_PROFILES` | — | Door komma's gescheiden profielen om te starten |
| `AUTH_MODE` | `none` | `none` / `local` / `sso` |
| `ORCHESTRATOR_PORT` | `8000` | Orkestrator FastAPI-poort |
| `GUI_PORT` | `3000` | GUI-poort |
| `QDRANT_HTTP_PORT` | `6333` | Qdrant REST-poort |
| `POSTGRES_PORT` | `5433` | PostgreSQL-poort |
| `POSTGRES_PASSWORD` | `changeme` | PostgreSQL-wachtwoord — wijzig dit! |
| `TRACE_RETENTION_DAYS` | `14` | Automatisch verwijderen van traces ouder dan N dagen |
| `ANTHROPIC_API_KEY` | — | Vereist voor Anthropic-provider |
| `OPENROUTER_API_KEY` | — | Vereist voor OpenRouter |
| `OPENAI_API_KEY` | — | Vereist voor OpenAI |
| `GOOGLE_API_KEY` | — | Vereist voor Google Gemini |
| `TELEGRAM_BOT_TOKEN` | — | Vereist voor Telegram-bridge |
| `TELEGRAM_CHAT_ID` | — | Telegram-chat-ID om berichten van te ontvangen |
| `NOTIFY_TELEGRAM_CHAT_ID` | — | Chat-ID voor voltooiingsmeldingen van taken (gelijk aan `TELEGRAM_CHAT_ID` indien hetzelfde) |
| `MATRIX_HOMESERVER` | — | Matrix-server-URL |
| `MATRIX_ACCESS_TOKEN` | — | Matrix-bot-toegangstoken |
| `DISCORD_BOT_TOKEN` | — | Vereist voor Discord-bridge |
| `SLACK_BOT_TOKEN` | — | Vereist voor Slack-bridge |
| `SLACK_APP_TOKEN` | — | Vereist voor Slack Socket Mode |
| `SIGNAL_PHONE` | — | Telefoonnummer voor Signal-bridge |
| `VIBER_AUTH_TOKEN` | — | Vereist voor Viber-bridge |
| `HA_URL` | `http://homeassistant:8123` | Home Assistant basis-URL |
| `HA_TOKEN` | — | HA langlevendige toegangstoken |
| `IMAP_HOST` | — | IMAP-server voor E-mail MCP |
| `SMTP_HOST` | — | SMTP-server voor E-mail MCP |
| `FALKORDB_URL` | — | Stel in om de kennisgraaf te activeren |
| `VAPID_EMAIL` | — | Vereist voor web-pushmeldingen |
| `VAPID_PRIVATE_KEY` | — | Automatisch gegenereerd door het installatieprogramma (vereist het Python-pakket `cryptography`); anders: `docker compose exec orchestrator python3 webpush.py` |
| `VAPID_PUBLIC_KEY` | — | Gegenereerd samen met de privésleutel |
| `HU_TOOLS_PORT` | `4300` | Poort voor hu-tools MCP |
| `WHISPER_URL` | `http://whisper-http:8000` | STT-service-URL |
| `PIPER_URL` | `http://piper-http:5000` | TTS-service-URL |
| `ORCHESTRATOR_API_KEY` | — | Automatisch gegenereerd door het installatieprogramma; service-naar-service-token voor bridges (vereist in `AUTH_MODE=local/sso`) |
| `CONVERSATION_API_KEY` | — | Automatisch gegenereerd door het installatieprogramma; beschermt het HA-eindpunt `/conversation` (leeg = open) |

Agentconfiguratie: `orchestrator/agents.yaml`. Volledige documentatie: `.env.example`.

---

## Branchepakketten

Kant-en-klare verticale pakketten voor specifieke sectoren. Elk pakket bevat vaardigheidsbestanden, voorgestelde agentconfiguraties en MCP-verwijzingen. Te installeren via `install.py` of handmatig.

| Pakket | Doelgroep | Kernfuncties |
|---|---|---|
| `legal` | Advocatenkantoren | Documentzoeken, contractanalyse, Hongaars juridisch onderzoek |
| `devops` | IT/DevOps-bedrijven | Incidenttriage, runbook zoeken, AIOps met HITL |
| `agency` | Marketing- en PR-bureaus | Projectstatus, leadkwalificatie, briefanalyse, klantenrapportage |

**Handmatige installatie:**
```bash
cp industry-packs/legal/skills/*.md data/skills/
cat industry-packs/legal/agents.yaml
```

**Via installer:** `python3 install.py` opnieuw uitvoeren → Aanpassen → pakket selecteren.

Maak uw eigen pakket door `industry-packs/_template/` te kopiëren en `pack.yaml` in te vullen.

---

## CRM-integratie

De CRM-MCP (`mcps/crm/`) biedt een uniforme interface voor meerdere CRM-systemen via een uitwisselbare adapterarchitectuur. Agents gebruiken dezelfde tools ongeacht de backend.

**Ondersteunde adapters:**

| Adapter | Systeem | Type |
|---|---|---|
| `minicrm` | MiniCRM (Hongaarse marktleider) | Volledig |
| `hubspot` | HubSpot CRM | Volledig |
| `pipedrive` | Pipedrive | Volledig |
| `billingo` | Billingo facturering | Alleen-lezen |
| `szamlazzhu` | Számlázz.hu facturering | Alleen-lezen |
| `salesautopilot` | SalesAutopilot (HU marketingautomatisering) | Volledig |

**Beschikbare tools:** `search_entities`, `get_entity`, `create_entity`, `update_entity`, `add_note`, `get_timeline`, `link_entities`, `get_related`, `emit_event`, `list_entity_types`

**Snel starten:**
```env
CRM_ADAPTER=minicrm
MINICRM_SYSTEM_ID=12345
MINICRM_API_KEY=uw-sleutel
```

```bash
docker compose --profile crm up -d
```

Voeg `crm` toe aan de `tools:`-lijst van een agent in `agents.yaml` om die agent CRM-toegang te geven.

---

## jog.gov.hu MCP — Hongaarse juridische zoekfunctie

De jog.gov.hu MCP (`mcps/jog-hu/`) biedt Hongaarse juridische informatie aan AI-agents in twee implementatiemodi:

**Docker-modus** (werkt altijd, geen Playwright vereist):

| Tool | Beschrijving |
|---|---|
| `search_njt_laws(keywords)` | Trefwoordzoeken op njt.jog.gov.hu — geeft overeenkomende wettitels en URL's terug |
| `get_law_text(law_id, section)` | Volledige of gedeeltelijke wettekst van njt.hu (bijv. `"2012. évi I. törvény"`, sectie `"69"`) |
| `list_recent_laws(category, days)` | Recente wetten uit de Magyar Közlöny RSS-feed |

**Hostmodus** (AI-gestuurde zoekfunctie, vereist dat `host_server.py` op de hostmachine draait):

| Tool | Beschrijving |
|---|---|
| `search_law(question)` | Natuurlijke taalvraag → AI-antwoord + geciteerde wetsverwijzingen (jog.gov.hu) |

reCAPTCHA v3 beoordeelt sessies primair op **IP-reputatie**. Docker-container-IP's en cloud-/VPS-server-IP's worden geclassificeerd als datacenterbereiken en krijgen een lage vertrouwensscore — ongeacht aanpassingen aan de browser-fingerprint. Een thuis- of kantoorapparaat op een **residentieel IP** scoort hoog genoeg om de controle te doorstaan. Een grafische weergave is **niet vereist** — de browser draait headless; de weergave is irrelevant.

**Snel starten (Docker-tools — werkt altijd):**
```bash
docker compose --profile jog-hu up -d
```

**Hostserver starten (AI-zoekfunctie — residentieel IP vereist):**
```bash
# Werkt op: thuis-/kantoordesktop of laptop (Windows, macOS, Linux)
# Werkt NIET op: cloud-/VPS-servers (datacentrum-IP's geblokkeerd door reCAPTCHA)
# Grafische weergave is NIET vereist — draait headless

pip install mcp fastmcp httpx playwright playwright-stealth
playwright install chromium

python3 mcps/jog-hu/host_server.py --background   # daemon starten, poort 4312
python3 mcps/jog-hu/host_server.py --stop          # daemon stoppen
```

**Toevoegen aan `mcps.yaml`:**
```yaml
- name: jog-hu
  url: http://jog-hu-mcp:4302/mcp/
  description: Hongaarse juridische zoekfunctie (njt.hu)

# Optioneel — alleen als host_server.py actief is:
- name: jog-hu-host
  url: http://host.docker.internal:4312/mcp/
  description: Hongaarse juridische AI-zoekfunctie (jog.gov.hu)
```

Voeg `jog-hu` (en optioneel `jog-hu-host`) toe aan de `tools:`-lijst van een agent in `agents.yaml`.
