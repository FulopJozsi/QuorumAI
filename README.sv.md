[English](README.md) | [Magyar](README.hu.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Русский](README.ru.md) | [Nederlands](README.nl.md) | [Polski](README.pl.md) | [Українська](README.uk.md) | [Svenska](README.sv.md) | [Italiano](README.it.md) | [日本語](README.ja.md) | [中文](README.zh.md) | [한국어](README.ko.md) | [Kiswahili](README.sw.md)

# QuorumAI

QuorumAI är ett modulärt, självhostat multi-agent AI-orkestreringssystem byggt på LangGraph. Det körs helt i Docker, ansluter till alla större meddelandeplattformar, stöder röstinteraktion, smart hem-styrning och simulerar ett AI-"företag" med flera roller, långtidsminne och autonom uppgiftsutförning.

![Python 3.11](https://img.shields.io/badge/Python-3.11-blue.svg) ![Docker](https://img.shields.io/badge/Docker-Compose-2496ED.svg)

---

<div align="center">
  <video src="https://github.com/user-attachments/assets/7bd072b6-75cd-4345-9fe0-fa2f3ee0566e" controls width="800"></video>

  <p><b><a href="https://license.quorumai.eu/portal/register">Kom igång — registrera dig för en 30 dagars gratis provperiod »</a></b></p>
</div>

---

## Vad är QuorumAI?

QuorumAI omvandlar en eller flera LLM:er till ett team av AI-agenter som kan:

- Svara på frågor, läsa nyheter och styra smarta hemenheter — utlöst via mikrofon, Telegram, Matrix, Discord, Slack, Signal, WhatsApp, Viber eller IRC.
- Delegera arbete mellan specialiserade roller (VD, utvecklare, försäljning) och upprätthålla långtidsminne mellan sessioner med Qdrant vektorsökning.
- Utföra uppgifter autonomt via en heartbeat-schemaläggare, begära mänskligt godkännande vid behov (HITL) och exponera varje extern förmåga som en MCP-server (Model Context Protocol).

Allt konfigureras i YAML. Inga kodändringar behövs för att byta modeller, lägga till agenter eller ansluta nya verktyg.

---

## Snabbinstallation

### En rad (rekommenderas)

Bootstrap-installationsprogrammet kontrollerar om Python 3 och Docker finns, installerar dem vid behov och kör sedan det interaktiva QuorumAI-installationsprogrammet.

**Linux / macOS:**
```bash
curl -fsSL https://raw.githubusercontent.com/FulopJozsi/QuorumAI/main/install.sh | bash
```

**Windows (PowerShell — kör som Administratör):**
```powershell
irm https://raw.githubusercontent.com/FulopJozsi/QuorumAI/main/install.ps1 | iex
```

Eller ladda ner `install.bat` / `install.ps1` från repositoryt och dubbelklicka.

> **Obs:** På Linux installerar bootstrap Docker Engine från det officiella Docker-repositoryt (apt/dnf/yum beroende på distribution) och lägger till din användare i gruppen `docker`. Du måste logga ut och in igen efteråt. På macOS och Windows installeras Docker Desktop och du uppmanas att starta det innan du fortsätter.

---

### Har du redan Python 3 och Docker?

Klona repositoryt och kör det interaktiva installationsprogrammet direkt — pip eller extra beroenden krävs inte:

```bash
git clone https://github.com/FulopJozsi/QuorumAI.git
cd QuorumAI
python3 install.py
```

Installationsprogrammet:
- Presenterar en interaktiv modulväljare (orkestrator, bryggor, röst, GUI med mera).
- Skriver `.env` från dina svar, skapar `data/` bind-mount-kataloger och kör `docker compose up -d`.
- Installationsprogrammets gränssnitt är tillgängligt på 16 språk.

**Satellite-läge** — kör mikrofon, bryggor eller MCP-servrar på en separat maskin:
```bash
python3 install.py   # välj "Satellite" när du tillfrågas
```

---

## Snabbstart

```bash
git clone https://github.com/FulopJozsi/QuorumAI.git
cd QuorumAI
python3 install.py
```

Kontrollera att orkestratorn körs:

```bash
curl http://localhost:8000/health
```

Skicka ett testmeddelande:

```bash
curl -X POST http://localhost:8000/invoke \
  -H 'Content-Type: application/json' \
  -d '{"message": "Hello, introduce yourself."}'
```

Öppna GUI:t på `http://localhost:3000`.

---

## Arkitektur

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

Varje lager finns i sin egen katalog med sin egen `compose.yml`. Root-`compose.yml` samlar alla lager via `include:` och Docker Compose-profiler — du startar bara det du behöver.

---

## Funktioner

### Kärnokestrering

- **LangGraph-körningsmiljö** — tillståndsmaskin-agentgraf, inbyggt HITL-checkpointing, `AsyncPostgresSaver`.
- **FastAPI HTTP API** — `POST /invoke`, `GET /health`, streaming, webhook-mottagare, push-notifieringsrelä.
- **agents.yaml** — deklarera agenter i YAML: namn, roll, leverantör, modell, systemprompt-sökväg, verktyg.
- **Varm omladdning** — `POST /agents/reload` laddar om `agents.yaml` utan containeromstart.
- **MCP-verktygsprotokoll** — varje extern förmåga är en MCP-server; agenter upptäcker verktyg automatiskt.
- **Qdrant vektorminne** — hybrid semantisk + BM42 lexikal sökning, flerspråkiga multilingual-e5-large-embeddings, agentspecifika samlingar, kosinus-deduplicering, MMR-diversifierad återhämtning.
- **Nattlig minneskonsolidering** — schemalagt dröm-jobb destillerar PostgreSQL-sessionshistorik till långsiktiga Qdrant-fakta; slår samman progressioner, tar bort inaktuella flyktiga poster; tillstånd spåras i PostgreSQL.
- **PostgreSQL** — LangGraph `AsyncPostgresSaver`-checkpointer + uppgifts- och kommentarstabeller.
- **Kunskapsgraf** — FalkorDB (Redis-kompatibel), användarspecifika Cypher-frågor, automatisk enhetsextraktion.

### LLM-leverantörer (per agent, konfigurerade i agents.yaml)

| Lokalt | Moln |
|---|---|
| Ollama (standard, ingen nyckel) | Anthropic Claude |
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
| | NVIDIA NIM (gratis nivå tillgänglig) |

Ingen API-nyckel behövs för att komma igång — Ollama körs lokalt och kostnadsfritt.

**Leverantörspooler** — flera identiska lokala servrar (t.ex. sex Ollama-maskiner) kan grupperas i en namngiven pool. Orkestratorn fördelar förfrågningar med least-connections-algoritmen; om alla poolmedlemmar misslyckas faller den tillbaka på den vanliga fallback-kedjan. Konfigureras i `providers.yaml` och hanteras via fliken Leverantörer i GUI.

### Multi-agent företagssimulering

- Rollbaserade agenter: VD, utvecklare, försäljning och valfri anpassad roll.
- Dispatcher-agenten dirigerar automatiskt inkommande förfrågningar till rätt specialist.
- Pipeline-agenter: planerare → utförare → granskare-slingor med delat tillstånd.
- **Autonoma (Deep) agenter** — ange `deep: true` på valfri agent eller pipeline-fas för att aktivera den inbyggda LangGraph ReAct-loopen. Agenten planerar, utför och itererar autonomt — anropar verktyg upprepade gånger tills uppgiften är klar eller den valfria gränsen för verktygsanrop nås (`deep_max_steps`, 0 = obegränsat). Konfigurerbart per agent och fas; växel tillgänglig i GUI Agent Builder.
- Kompetensbibliotek: Markdown-kompetensfiler, lat inläsning per agent, gemenskapsmarknadsplats för delning.
- Delat arbetsområde: agenter kan läsa och skriva till ett gemensamt filområde.
- **Administrationsverktyg** — agenter med rollen `admin` kan skapa och ta bort agenter, kompetenser, MCP-servrar, cron-jobb och heartbeat-scheman vid körning via `system-admin`-verktyg. Varje skrivåtgärd kräver HITL-godkännande innan den utförs.

### Uppgiftshantering och autonomi

- Kanban-uppgiftstavla med deluppgifter och kommentarer (PostgreSQL-baserad).
- Heartbeat-schemaläggare: agenter tar automatiskt upp väntande uppgifter (var 5:e minut som standard).
- Autonom körning med HITL-godkännandeportar (Telegram `/approve`, GUI-knappar).
- Push-notifieringar: Telegram, Home Assistant `notify`, web push (VAPID). Uppgifter kan ange ett `notify_channel`-fält så att slutförandemeddelandet alltid skickas till rätt brygga, oavsett vilken session som skapade uppgiften. Agenter kan anropa `list_notify_channels()` för att vid körning hitta tillgängliga kanaler.

**Flerdagsuppgifter** — det rekommenderade mönstret för långvarigt arbete som sträcker sig över timmar eller dagar:
1. Skapa en uppgift med titel och beskrivning (via chatt, Telegram eller GUI:ns Kanban-tavla).
2. Agenten (eller du) anropar `set_subtasks` för att dela upp det i namngivna steg.
3. Varje heartbeat-körning tar nästa väntande deluppgift, slutför den och stoppar — enskilda LLM-sessioner förblir korta och fokuserade.
4. Framsteg, beslut och mellanresultat lagras som uppgiftskommentarer så att varje efterföljande körning har full kontext av vad som hänt innan.
5. När alla deluppgifter är klara stänger agenten uppgiften och skickar ett slutförandemeddelande.

Det här mönstret fungerar utan kodändringar — det bygger på de befintliga uppgiftsverktygen (`set_subtasks`, `get_next_subtask`, `complete_subtask`) som varje agent med verktygskällan `tasks` redan har tillgång till.

### Säkerhetstillsyn (Quadrumviratus)

Ett valfritt lager per agent som granskar varje riskabelt verktygsanrop innan det körs. Aktiveras med `guardian: true` i `agents.yaml`; agenter utan denna flagga påverkas inte.

- **Guardian** — ett isolerat LLM-anrop (utan verktyg) som utvärderar verktygets namn och argument och returnerar: `NONE` (fortsätt), `SOFT VETO: anledning` (mänskligt beslut krävs) eller `HARD VETO: anledning` (omedelbar blockering).
- **Skiljedomare (Arbiter)** — aktiveras vid SOFT VETO; genererar en Markdown-analysrapport och pausar grafen via LangGraph `interrupt()`. Operatören godkänner eller avvisar via Telegram `/approve` eller GUI — samma flöde som HITL.
- **Historiker** — ett heartbeat-jobb som läser Guardian-granskningsloggen i minnet och skriver en strukturerad rapport till PostgreSQL-tabellen `historian_reports`.
- **Riskklassificering** — MCP-servrar märks i `mcps.yaml` med `risk: low` eller `risk: high`. Minnes-, uppgifts- och godkännandeverktyg är alltid undantagna från granskning.

```yaml
# agents.yaml
agents:
  - name: ceo
    guardian: true
    guardian_provider: anthropic        # valfritt — ärver agentens leverantör om tomt
    guardian_model: claude-haiku-4-5-20251001
    arbiter_provider: anthropic
    arbiter_model: claude-sonnet-4-6
```

```yaml
# mcps.yaml
servers:
  - name: playwright
    risk: high        # alla playwright-verktyg kräver Guardian-godkännande
  - name: hu-tools
    risk: low         # väder, nyheter — vidarebefordras utan granskning
```

Endpointen `/guardian/log` returnerar den live granskningsloggen (senaste 1 000 beslut).

### Autentisering och multitenancy

| Läge | Beskrivning |
|---|---|
| `AUTH_MODE=none` | Öppet — ingen autentisering (standard, lämpligt för lokal användning) |
| `AUTH_MODE=local` | Bearer-token; användare definierade i `LOCAL_USERS=user1:pass1,...` |
| `AUTH_MODE=sso` | Keycloak OIDC/JWT, eller valfri OIDC-leverantör (Auth0, Okta, Authelia, …) |

**Isolering per användare.** I fleranvändarläge är varje användares minne
och kunskapsgraf separerade: långtidsminnet hamnar i användarens egen
Qdrant-collection och grafen i dess egen `scope` — en läsning ser de egna
uppgifterna och det administratörskurerade gemensamma lagret, aldrig en annan
användares. Även det nattliga underhållet körs **per användare**.

### Observerbarhet

- Pipeline-spår med token- och kostnadsloggning per tur.
- Vattenfallsvy i fliken Observerbarhet i GUI.
- Automatisk rensning av spår styrd av `TRACE_RETENTION_DAYS`.

### Webhook-mottagare

Tar emot signerade webhooks från: GitHub, Gitea, Drone CI, Grafana, n8n, Slack, ERPNext, Twenty CRM, Zammad, Tiledesk, Uptime Kuma, Wekan, Umami, Duplicati, BorgWarehouse.

### Säkerhetskopiering och konfigurationspersistens

All körningsdata finns i `data/` som bind-monteringar; all konfiguration i YAML-filer — inget dolt tillstånd inuti containrar.

**Skapa säkerhetskopia** (inkluderar `.env` + `data/`):

```bash
sudo python3 backup.py backup                 # interaktivt, automatiskt filnamn
sudo python3 backup.py backup /srv/backup.tgz # explicit utdatasökväg
```

**Återställ**:

```bash
python3 backup.py restore /srv/backup.tgz          # återställ till aktuell katalog
python3 backup.py restore /srv/backup.tgz /opt/qai # återställ till specifik katalog
```

På Linux / macOS kör med `sudo` för att bevara filägare. På Windows behövs det inte.

---

## Bryggor

| Brygga | Transport | Compose-profil |
|---|---|---|
| Telegram | Bot API, async (python-telegram-bot) | `telegram` |
| Matrix | matrix-nio, rumsnivå | `matrix` |
| Discord | discord.py, slash-kommandon | `discord` |
| IRC | irc3 asyncio, multi-kanal | `irc` |
| WhatsApp | Meta Cloud API webhook | `whatsapp` |
| Slack | slack-bolt Socket Mode | `slack` |
| Signal | signal-cli REST API polling | `signal` |
| Viber | FastAPI webhook, tangentbordsknappar | `viber` |

Varje brygga exponerar `/notify` (för push-notifieringar från orkestratorn) och `/health` (livstidskontroll), och stöder tillåtlistor för avsändare och kanaler. Telegram och GUI stöder även HITL `/approve`-flödet. Alla bryggor stöder per-användare språkbyte via kommandot `/language`; inställningen sparas i PostgreSQL och överlever omstart av containrar.

---

## Röst

### Mikrofonsbrygga (lokal mikrofon)

Compose-profil: `mic`

- openWakeWord — konfigurerbart aktiveringsord (standard: "Ok Szif").
- Wyoming Whisper — lokal STT, ingen molntjänst krävs.
- Wyoming Piper — lokal TTS.
- PulseAudio-socket-montering för Linux-skrivbord.

**Plattformsnoteringar:**

- **Linux** — installationsprogrammet identifierar ditt UID och monterar automatiskt rätt PulseAudio-socket (`/run/user/<uid>/pulse`).
- **macOS / Windows** — Docker Desktop vidarebefordrar inte ljudenheter. Installationsprogrammet skriver istället en PulseAudio TCP-konfiguration. Konfigurera PulseAudio i TCP-läge innan du startar mic-containern:
  - macOS: `brew install pulseaudio && pulseaudio --load=module-native-protocol-tcp --exit-idle-time=-1 --daemon`
  - Windows (WSL2): `sudo apt install pulseaudio && pulseaudio --load=module-native-protocol-tcp --exit-idle-time=-1 --start`
  - Windows (native): ladda ned PulseAudio för Windows, avkommentera `module-native-protocol-tcp` i `default.pa`, tillåt port 4713 i brandväggen.

### Home Assistant Voice PE

Compose-profil: `ha`

QuorumAI registrerar sig som konversationsagent i Home Assistant. HA Assist hanterar aktiveringsorddetektering, Whisper STT och Piper TTS på HA-sidan; QuorumAI hanterar resonemang och verktygsanrop.

### STT- och TTS-verktyg (agentanropbara)

Compose-profil: `stt-tts`

Exponerar Whisper och Piper som HTTP-API:er som agenter kan anropa som `system-stt`- och `system-tts`-verktyg.

---

## GUI

Compose-profil: `gui` — tillgängligt på `http://localhost:3000`

Byggt med React, Vite och Tailwind CSS.

| Flik | Beskrivning |
|---|---|
| Chatt | Skicka meddelanden till valfri agent; visa streamade svar |
| Agentbyggare | Visuellt företagsdiagram; skapa och redigera agenter och deras roller |
| Kompetensredigerare | Skapa och hantera Markdown-kompetensfiler |
| Uppgifter | Kanban-tavla; deluppgiftsträd; kommentarer; godkännandeknappar |
| Leverantörer | Leverantörsstatus i realtid och tillgänglig modelllista |
| Heartbeat | Schemaläggartillstånd; nästa körtider; manuell utlösning |
| Observerbarhet | Pipeline-spår; token- och kostnadsvattenfallsvy |

- 16 gränssnittsspråk, 14 teman.
- HITL-godkännandeknappar integrerade i Chatt- och Uppgifts-flikarna.

---

## Installationsdetaljer

### Förutsättningar

- Docker Engine 24+ och Docker Compose v2.
- Python 3.8+ för `install.py` — ingen pip eller virtualenv krävs.
- För lokala modeller: Ollama körs på värden på port 11434.

### Skapa det delade nätverket (en gång per värd)

```bash
docker network create quorum-net
```

### Välja profiler

Ange profiler i `.env` så att vanlig `docker compose up -d` fungerar:

```env
COMPOSE_PROFILES=orchestrator,memory,mcp,postgres,telegram,gui
```

Eller ange dem explicit:

```bash
docker compose --profile orchestrator --profile memory --profile gui up -d
```

Tillgängliga profiler: `orchestrator`, `memory`, `mcp`, `postgres`, `telegram`, `ha`, `mic`, `gui`, `stt-tts`, `mcp-manager`, `playwright`, `joplin`, `auth`, `email`, `matrix`, `discord`, `irc`, `whatsapp`, `slack`, `signal`, `viber`, `graph`

### Datakatalogstruktur

```
data/
  qdrant/        # Qdrant-vektorer
  postgres/      # PostgreSQL-data
  workspace/     # per-agent filarbetsyta
  whisper/       # Whisper-modellcache
  piper/         # Piper röstfiler
  ...
```

Allt under `data/` är gitignorerat. Att säkerhetskopiera den här katalogen bevarar alla beständiga tillstånd.

---

## Konfiguration

Kopiera `.env.example` till `.env` och fyll i det du behöver. `.env.example`-filen innehåller inline-dokumentation för varje nyckel.

### Viktigaste nycklar

| Nyckel | Standard | Beskrivning |
|---|---|---|
| `COMPOSE_PROFILES` | — | Kommaseparerade profiler att starta |
| `AUTH_MODE` | `none` | `none` / `local` / `sso` |
| `ORCHESTRATOR_PORT` | `8000` | Orchestrator FastAPI-port |
| `GUI_PORT` | `3000` | GUI-port |
| `QDRANT_HTTP_PORT` | `6333` | Qdrant REST-port |
| `POSTGRES_PORT` | `5433` | PostgreSQL-port |
| `POSTGRES_PASSWORD` | `changeme` | PostgreSQL-lösenord — ändra detta |
| `TRACE_RETENTION_DAYS` | `14` | Automatisk borttagning av spår äldre än N dagar |
| `ANTHROPIC_API_KEY` | — | Krävs för Anthropic-leverantör |
| `OPENROUTER_API_KEY` | — | Krävs för OpenRouter |
| `OPENAI_API_KEY` | — | Krävs för OpenAI |
| `GOOGLE_API_KEY` | — | Krävs för Google Gemini |
| `TELEGRAM_BOT_TOKEN` | — | Krävs för Telegram-brygga |
| `TELEGRAM_CHAT_ID` | — | Telegram-chatt-ID att ta emot meddelanden från |
| `NOTIFY_TELEGRAM_CHAT_ID` | — | Chatt-ID för uppgiftsslutförandenotifieringar (samma som `TELEGRAM_CHAT_ID` om identiskt) |
| `MATRIX_HOMESERVER` | — | Matrix-server-URL |
| `MATRIX_ACCESS_TOKEN` | — | Matrix-bot-åtkomsttoken |
| `DISCORD_BOT_TOKEN` | — | Krävs för Discord-brygga |
| `SLACK_BOT_TOKEN` | — | Krävs för Slack-brygga |
| `SLACK_APP_TOKEN` | — | Krävs för Slack Socket Mode |
| `SIGNAL_PHONE` | — | Telefonnummer för Signal-brygga |
| `VIBER_AUTH_TOKEN` | — | Krävs för Viber-brygga |
| `HA_URL` | `http://homeassistant:8123` | Home Assistant bas-URL |
| `HA_TOKEN` | — | HA långlivad åtkomsttoken |
| `IMAP_HOST` | — | IMAP-server för Email MCP |
| `SMTP_HOST` | — | SMTP-server för Email MCP |
| `FALKORDB_URL` | — | Ange för att aktivera kunskapsgrafen |
| `VAPID_EMAIL` | — | Krävs för web push-notifieringar |
| `VAPID_PRIVATE_KEY` | — | Genereras automatiskt av installationsprogrammet (kräver Python-paketet `cryptography`); annars kör `docker compose exec orchestrator python3 webpush.py` |
| `VAPID_PUBLIC_KEY` | — | Genereras tillsammans med den privata nyckeln |
| `HU_TOOLS_PORT` | `4300` | hu-tools MCP-port |
| `WHISPER_URL` | `http://whisper-http:8000` | STT-tjänst-URL |
| `PIPER_URL` | `http://piper-http:5000` | TTS-tjänst-URL |
| `ORCHESTRATOR_API_KEY` | — | Genereras automatiskt av installationsprogrammet; tjänst-till-tjänst-token för bryggor (krävs vid `AUTH_MODE=local/sso`) |
| `CONVERSATION_API_KEY` | — | Genereras automatiskt av installationsprogrammet; skyddar HA-slutpunkten `/conversation` (tom = öppen) |

Agenter konfigureras i `orchestrator/agents.yaml` — inte i `.env`.

---

## Branschpaket

Färdigbyggda vertikala paket för specifika branscher. Varje paket innehåller kompetensfiler, föreslagna agentkonfigurationer och MCP-referenser. Installeras via `install.py` eller manuellt.

| Paket | Målgrupp | Nyckelkompetenser |
|---|---|---|
| `legal` | Advokatbyråer | Dokumentsökning, kontraktsanalys, ungersk juridisk sökning |
| `devops` | IT/DevOps-företag | Incidenttriagering, runbook-sökning, AIOps med HITL |
| `agency` | Marknadsförings- och PR-byråer | Projektstatus, leadkvalificering, briefanalys, klientrapportering |

**Manuell installation:**
```bash
cp industry-packs/legal/skills/*.md data/skills/
cat industry-packs/legal/agents.yaml
```

**Via installationsprogrammet:** kör `python3 install.py` → Ändra → välj ett branschpaket.

Skapa ett eget paket genom att kopiera `industry-packs/_template/` och fylla i `pack.yaml`.

---

## CRM-integration

CRM-MCP:n (`mcps/crm/`) tillhandahåller ett enhetligt gränssnitt för flera CRM-system via en utbytbar adapterarkitektur. Agenter använder samma verktyg oavsett vilket system som ligger bakom.

**Stödda adaptrar:**

| Adapter | System | Typ |
|---|---|---|
| `minicrm` | MiniCRM (ungersk marknadsledare) | Full |
| `hubspot` | HubSpot CRM | Full |
| `pipedrive` | Pipedrive | Full |
| `billingo` | Billingo fakturering | Skrivskyddad |
| `szamlazzhu` | Számlázz.hu fakturering | Skrivskyddad |
| `salesautopilot` | SalesAutopilot (ungersk marknadsautomatisering) | Full |

**Tillgängliga verktyg:** `search_entities`, `get_entity`, `create_entity`, `update_entity`, `add_note`, `get_timeline`, `link_entities`, `get_related`, `emit_event`, `list_entity_types`

**Snabbstart:**
```env
CRM_ADAPTER=minicrm
MINICRM_SYSTEM_ID=12345
MINICRM_API_KEY=your-key
```

```bash
docker compose --profile crm up -d
```

Lägg till `crm` i en agents `tools:`-lista i `agents.yaml` för att ge den CRM-åtkomst.

---

## jog.gov.hu MCP — Ungersk juridisk sökning

jog.gov.hu MCP (`mcps/jog-hu/`) ger AI-agenter tillgång till ungersk juridisk information i två driftslägen:

**Docker-läge** (fungerar alltid, Playwright krävs inte):

| Verktyg | Beskrivning |
|---|---|
| `search_njt_laws(keywords)` | Nyckelordssökning på njt.jog.gov.hu — returnerar matchande lagtitlar och URL:er |
| `get_law_text(law_id, section)` | Fullständig eller partiell lagtext från njt.hu (t.ex. `"2012. évi I. törvény"`, avsnitt `"69"`) |
| `list_recent_laws(category, days)` | Senaste lagar från Magyar Közlöny RSS-flöde |

**Värdläge** (AI-driven sökning, kräver att `host_server.py` körs på värdmaskinen):

| Verktyg | Beskrivning |
|---|---|
| `search_law(question)` | Fråga på naturligt språk → AI-svar + citerade lagreferenser (jog.gov.hu) |

reCAPTCHA v3 bedömer sessioner primärt utifrån **IP-rykte**. IP-adresser från Docker-containers och moln-/VPS-servrar klassificeras som datacenter-intervall och får ett lågt förtroendevärde — oavsett eventuella webbläsar-fingerprint-justeringar. En hem- eller kontorsmaskin med en **bostads-IP** får tillräckligt högt poäng för att passera. Grafisk skärm **krävs inte** — webbläsaren körs i headless-läge; skärmen är irrelevant.

**Snabbstart (Docker-verktyg — fungerar alltid):**
```bash
docker compose --profile jog-hu up -d
```

**Starta värdservern (AI-sökning — bostads-IP krävs):**
```bash
# Fungerar på: hem- eller kontorsdator eller bärbar dator (Windows, macOS, Linux)
# Fungerar INTE på: moln-/VPS-servrar (datacenter-IP:er blockeras av reCAPTCHA)
# Grafisk skärm krävs INTE — körs i headless-läge

pip install mcp fastmcp httpx playwright playwright-stealth
playwright install chromium

python3 mcps/jog-hu/host_server.py --background   # starta daemon, port 4312
python3 mcps/jog-hu/host_server.py --stop          # stoppa daemon
```

**Lägg till i `mcps.yaml`:**
```yaml
- name: jog-hu
  url: http://jog-hu-mcp:4302/mcp/
  description: Hungarian legal search (njt.hu)

# Valfritt — endast om host_server.py körs:
- name: jog-hu-host
  url: http://host.docker.internal:4312/mcp/
  description: Hungarian legal AI search (jog.gov.hu)
```

Lägg till `jog-hu` (och valfritt `jog-hu-host`) i en agents `tools:`-lista i `agents.yaml`.
