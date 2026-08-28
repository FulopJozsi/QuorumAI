[English](README.md) | [Magyar](README.hu.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Русский](README.ru.md) | [Nederlands](README.nl.md) | [Polski](README.pl.md) | [Українська](README.uk.md) | [Svenska](README.sv.md) | [Italiano](README.it.md) | [日本語](README.ja.md) | [中文](README.zh.md) | [한국어](README.ko.md) | [Kiswahili](README.sw.md)

# QuorumAI

A QuorumAI egy moduláris, saját szerveren futtatható, multi-agent AI orchestrációs rendszer, amelyet LangGraph alapokra építettünk. Teljes egészében Docker-ben fut, csatlakozik a legelterjedtebb üzenetküldő platformokhoz, támogatja a hangvezérlést és az okosotthon-irányítást, és képes egy több szerepkörű AI „céget" szimulálni hosszú távú memóriával és autonóm feladatvégrehajtással.

![Python 3.11](https://img.shields.io/badge/Python-3.11-blue.svg) ![Docker](https://img.shields.io/badge/Docker-Compose-2496ED.svg)

---

## Mi az a QuorumAI?

A QuorumAI egy vagy több LLM-ből épít AI-agent csapatot, amely képes beszélgetni, eszközöket használni, emlékezni a történtekre és önállóan cselekedni — teljes egészében saját szerveren, Docker-ben futtatva, egyetlen AI-szolgáltatóhoz sem kötve. Az agensek, skillek, MCP szerverek és ütemezések a háttérben YAML konfigban élnek, de semmit nem kell kézzel szerkeszteni: a GUI Agent Buildere, Skill Editora és MCP Managere mindezt futásidőben, kódmódosítás és újraindítás nélkül létrehozza és módosítja.

**Bárhonnan elérhető.** Az agenseket eléred helyi mikrofonról (openWakeWord ébresztőszó-felismerés, helyi Whisper STT, helyi Piper TTS, természetes szünetfelismeréssel és válasz közbeni megszakítással), Home Assistant Voice PE-ről, vagy nyolc üzenetküldő platformról — Telegram, Matrix, Discord, IRC, WhatsApp, Slack, Signal, Viber —, mindegyiken ugyanazzal az emberi jóváhagyási (HITL) folyamattal, felhasználónkénti nyelvváltással és 33 nyelvű felülettel. Egy saját fejlesztésű React/Vite/Tailwind GUI fedi le mindazt, ami nem chat: Agent Builder, Company Diagram élő cégdiagrammal, Skill Editor saját piactérrel, Kanban feladattábla, Szívverés-ütemező nézet cron job kezeléssel, Tudásbázis, Hang Stúdió, MCP Manager, valamint Megfigyelhetőség/Beállítások képernyők (providerek, observability trace-ek, tudásgráf, AI Act megfelelőségi állapot, licenc szint). Egy OpenAI-kompatibilis `POST /v1/chat/completions` végpont is elérhető, amellyel bármelyik meglévő OpenAI kliens közvetlenül tud beszélni egy QuorumAI agenssel.

**Bármilyen LLM, agentenként.** Minden agens providere és modellje külön-külön, az `agents.yaml`-ban van beállítva. A helyi futtatókörnyezetekhez (Ollama, llama.cpp, LM Studio, vLLM, Docker Model Runner, Unsloth Studio) egyáltalán nem kell API kulcs; az Anthropic, OpenAI, Google Gemini, OpenRouter, Grok, DeepSeek, Mistral, Together AI, Fireworks AI, Zhipu/Z.AI, Eden AI és NVIDIA NIM cserélhető felhő-providerként támogatott. A provider poolok terhelést osztanak el azonos helyi szerverek között, egy konfigurálható fallback lánc pedig cooldown-nal életben tartja a beszélgetést, ha az egyik provider meghibásodik.

**Cég, nem csak chatbot.** Az agensek szerepköröket vehetnek fel (vezérigazgató, fejlesztő, értékesítő, …), delegálhatnak egymásnak egy dispatcher agenten keresztül, futtathatnak tervező → végrehajtó → ellenőrző pipeline-okat, vagy — `deep: true` beállítással — teljesen önállóan működhetnek egy ReAct hurokban, egymás után hívva az eszközöket, amíg a feladat el nem készül. Közös Markdown skill könyvtárat (közösségi piactérrel) és közös fájl-munkaterületet osztanak meg. Az `admin` jelölésű agensek futásidőben tudnak más agenteket, skilleket, MCP szervereket és ütemezéseket létrehozni vagy törölni, mindig emberi jóváhagyási kapun keresztül.

**Memória és tudás.** A hosszú távú memória Qdrantban él — hibrid szemantikus + lexikális (BM42) kereséssel, deduplikálva, és éjszakánként konszolidálva a session-előzményekből tartós tényekké. Egy FalkorDB tudásgráf felhasználónként követi az entitásokat és kapcsolataikat, így az agensek tudják, kivel beszélnek. Egy tudásbázis PDF-eket, DOCX-eket, táblázatokat és egyebeket dolgoz fel, amelyeket bármelyik agens visszakereshet.

**Autonómia felügyelettel.** Egy Kanban feladattábla alfeladatokkal és megjegyzésekkel lehetővé teszi, hogy a munka napokon átívelhessen: minden szívverés-futás felveszi a következő alfeladatot, elvégzi, majd megjegyzésként hagyja a haladást a következő futásnak. Egy opcionális Guardian/Arbiter/Historian réteg ("Quadrumvirátus") ellenőrzi a kockázatos eszközhívásokat, megvétózva, emberi döntésre eszkalálva, vagy naplózva azokat. Egy külön AI Act mód teljes eszközhívás-audit naplózást, hamisítás ellen védett (hash-lánc) naplót és automatikus PII-maszkolást ad hozzá szabályozási kontextusokhoz.

**Eszközök, mind MCP-n keresztül.** Minden külső képesség MCP (Model Context Protocol) szerverként érhető el, amelyet az agensek automatikusan felismernek: magyar hírek/időjárás/webkeresés, globális időjárás és hírek, magyar jogi keresés (njt.hu), CRM MiniCRM, HubSpot, Pipedrive, Billingo, Számlázz.hu, SalesAutopilot és Twenty adapterekkel, e-mail (IMAP/SMTP), Google Workspace (Gmail, Drive, Naptár, Docs, Sheets, Slides, Chat), Jira/Confluence, Home Assistant eszközvezérlés, Grafana, Uptime Kuma, távoli bash/Python futtatás, böngésző-automatizálás (Playwright), Joplin jegyzetek, AI videógenerálás (HyperFrames), valamint egy MCP Manager további szerverek piactérről történő, futásidejű telepítéséhez.

**Kész iparági csomagok, egyetlen telepítő.** Az iparági csomagok (jogi, DevOps, marketing ügynökség) skilleket, agenteket és MCP-bekötést csomagolnak egy adott iparágra szabva. Minden az interaktív `install.py`-n keresztül telepíthető (vagy egy egysoros bootstrap szkripttel), amely a licencszinteket (Personal-tól Enterprise-ig, mindegyik 30 napos trial-lel), a hitelesítési módot (nincs / helyi / SSO Keycloak-kal), és a perzisztens állapot teljes mentését/visszaállítását is kezeli.

---

## Gyors telepítés

### Egysoros telepítő (ajánlott)

A bootstrap telepítő ellenőrzi, hogy megvan-e Python 3 és Docker, szükség esetén telepíti őket, majd elindítja az interaktív QuorumAI telepítőt.

**Linux / macOS:**
```bash
curl -fsSL https://raw.githubusercontent.com/fulopjozsef86/QuorumAI/main/install.sh | bash
```

**Windows (PowerShell — rendszergazdaként futtatva):**
```powershell
irm https://raw.githubusercontent.com/fulopjozsef86/QuorumAI/main/install.ps1 | iex
```

Vagy töltsd le az `install.bat` / `install.ps1` fájlt a repóból és dupla kattintással futtasd.

> **Megjegyzés:** Linuxon a bootstrap a hivatalos Docker repository-ból telepíti a Docker Engine-t (apt/dnf/yum a disztrótól függően) és hozzáadja a felhasználót a `docker` csoporthoz. Ehhez ki- és újra be kell jelentkezni. macOS és Windows esetén Docker Desktop telepítésére irányít és megvárja, hogy elindítsd, mielőtt folytatja.

---

### Már megvan Python 3 és Docker?

Klónozd a repót és futtasd az interaktív telepítőt közvetlenül — pip vagy extra függőség nem szükséges:

```bash
git clone https://github.com/fulopjozsef86/QuorumAI.git
cd QuorumAI
python3 install.py
```

A telepítő:
- Interaktív modulválasztót kínál (orchestrator, bridge-ek, hang, GUI stb.).
- A válaszaidból megírja a `.env` fájlt, létrehozza a `data/` bind-mount könyvtárakat, és elindítja a `docker compose up -d` parancsot.
- A telepítő felülete 33 nyelven érhető el.

**Satellite mód** — futtass mikrofont, bridge-eket vagy MCP szervereket egy külön gépen, amely egy távoli QuorumAI orchestratorhoz csatlakozik:

```bash
python3 install.py   # válaszd a "Satellite" opciót a kérdésnél
```

---

## Gyors indítás (manuálisan)

```bash
git clone https://github.com/your-org/QuorumAI.git
cd QuorumAI

# Megosztott Docker hálózat létrehozása (egyszer, gépenként):
docker network create quorum-net

cp .env.example .env
# Szerkeszd a .env-t — állítsd be a COMPOSE_PROFILES-t és a szükséges API kulcsokat

docker compose up -d
```

Ellenőrzés, hogy az orchestrator fut-e:

```bash
curl http://localhost:8000/health
```

Teszt üzenet küldése:

```bash
curl -X POST http://localhost:8000/invoke \
  -H 'Content-Type: application/json' \
  -d '{"message": "Hello, introduce yourself."}'
```

A GUI elérhető: `http://localhost:3000`

---

## Architektúra

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

Minden réteg saját könyvtárban és saját `compose.yml`-ben él. A gyökér `compose.yml` az összes réteget `include:`-dal és Docker Compose profilokon keresztül fogja össze — csak azt indítod el, amire szükséged van.

---

## Funkciók

### Alap orchestráció

- **LangGraph futtatókörnyezet** — state-machine agent gráf, natív HITL checkpointing, `AsyncPostgresSaver`.
- **FastAPI HTTP API** — `POST /invoke`, `GET /health`, streamelés, webhook fogadó, push értesítés relay.
- **agents.yaml** — agenteket YAML-ban deklarálsz: név, szerepkör, provider, modell, rendszerüzenet útvonala, eszközök.
- **Hot reload** — `POST /agents/reload` újratölti az `agents.yaml`-t konténer újraindítás nélkül.
- **MCP eszközprotokoll** — minden külső képesség MCP szerver; az agensek automatikusan felveszik az eszközöket.
- **Qdrant vektoros memória** — hibrid szemantikus + BM42 lexikális keresés, multilingual-e5-large embeddingekkel, agent-szintű kollekcióval, koszinusz-alapú deduplikációval, MMR-diverzifikált visszakeresssel.
- **Éjszakai memóriakonszolidáció** — ütemezett „álom-feladat" a PostgreSQL session-előzményeket hosszú távú Qdrant tényekké desztillálja; összevonja a fejlődési lépéseket, törli az elavult ideiglenes bejegyzéseket; állapota PostgreSQL-ben nyomon követve.
- **PostgreSQL** — LangGraph `AsyncPostgresSaver` checkpointer + feladatok és megjegyzések táblák.
- **Tudásgráf** — FalkorDB (Redis-kompatibilis), felhasználó-szintű Cypher lekérdezések. Az entitások és kapcsolatok minden kör végén automatikusan kinyerődnek, vagy az agens explicit módon írhatja őket a `graph_remember_entity`/`graph_remember_relation` eszközökkel; a gráf-kontextus automatikusan bekerül a rendszerüzenetbe (`memory_graph: true` alapértelmezetten), és megjelenik a GUI Megfigyelhetőség fülén.
- **OpenAI-kompatibilis API** — `POST /v1/chat/completions` + `GET /v1/models` (a `model` mező választja ki az agentet név szerint); Bearer hitelesítés `OPENAI_COMPAT_API_KEY`-jal, streamelés (SSE) támogatott. Bármelyik meglévő OpenAI kliens vagy SDK módosítás nélkül tud beszélni egy QuorumAI agenssel.

### LLM providerek (per-agent, agents.yaml-ban konfigurálva)

| Helyi | Felhő |
|---|---|
| Ollama (alapértelmezett, kulcs nélkül) | Anthropic Claude |
| llama.cpp | OpenAI |
| LM Studio | OpenRouter |
| vLLM | Google Gemini |
| Docker Model Runner | Grok (xAI) |
| Unsloth Studio | DeepSeek |
| | Mistral AI |
| | Together AI |
| | Fireworks AI |
| | Zhipu AI / Z.AI |
| | Eden AI (aggregátor) |
| | NVIDIA NIM (ingyenes tier is elérhető) |

Induláshoz nem szükséges API kulcs — az Ollama helyileg fut, ingyenesen.

**Provider poolok** — több azonos típusú lokális szerver (pl. hat Ollama gép) egyetlen névvel ellátott poolba csoportosítható. Az orchestrator least-connections algoritmussal osztja el a kéréseket; ha minden pool-tag meghibásodik, visszaesik a normál fallback láncra. `providers.yaml`-ban konfigurálható, a GUI Providerek fülén kezelhető.

### Multi-agent cégszimulúció

- Szerepkör-alapú agensek: vezérigazgató, fejlesztő, értékesítő és bármilyen egyéni szerepkör.
- A dispatcher agent automatikusan a megfelelő specialistához irányítja a bejövő kéréseket.
- Pipeline agensek: tervező → végrehajtó → ellenőrző körök megosztott állapottal.
- **Autonóm (Deep) agensek** — bármely agensen vagy pipeline stage-en beállítható `deep: true`, amely bekapcsolja a beépített LangGraph ReAct hurkot. Az agens önállóan tervez, hajt végre és iterál — eszközöket hív egymás után, amíg a feladat el nem készül, vagy el nem éri az opcionális eszközhívás-korlátot (`deep_max_steps`, 0 = korlátlan). Agent és pipeline stage szinten egyaránt állítható; kapcsoló a GUI Agent Builderben.
- **Company Diagram** — élő, automatikusan elrendezett cégdiagram (React Flow + dagre), amely a dispatcher → beosztott kapcsolatokat DAG-ként jeleníti meg (egy agensnek több szülője is lehet), zoom, pásztázás és minitérkép támogatással.
- **Skill könyvtár** — Markdown skill fájlok, lazy-load per agent. A Skill Piactér 6 forrásból böngészhető/kereshető/telepíthető, GitHub URL-ből rekurzív importtal is; admin agensek futásidőben maguk is kereshetnek és telepíthetnek skilleket a `search_skill_marketplace`/`install_skill_from_marketplace` eszközökkel, HITL jóváhagyással.
- Megosztott munkaterület: az agensek olvashatnak és írhatnak egy közös fájlterületet.
- **Admin eszközök** — `admin` szerepkörű agensek futásidőben tudnak agenteket, skill-eket, MCP szervereket, cron jobokat és szívverés-ütemezéseket létrehozni és törölni a `system-admin` eszközökön keresztül. Minden írási művelet HITL jóváhagyást igényel végrehajtás előtt.

### Feladatkezelés és autonómia

- Kanban feladattábla részfeladatokkal és megjegyzésekkel (PostgreSQL alapú).
- Szívverés-ütemező: az agensek automatikusan felveszik a függő feladatokat (alapértelmezetten 5 percenként). A szívverés-jobok (cron ütemezések) REST API-n vagy a GUI Szívverés fülén hozhatók létre, szerkeszthetők és törölhetők — YAML szerkesztés nélkül.
- Autonóm feladatvégrehajtás HITL jóváhagyási kapuval (Telegram `/approve`, GUI gombok).
- Push értesítések: Telegram, Home Assistant `notify`, web push (VAPID). A feladatokon megadható `notify_channel` mező, így a kész-értesítés mindig a megfelelő bridge-re kerül, függetlenül attól, melyik session hozta létre a feladatot. Az agensek futásidőben lekérdezhetik az elérhető csatornákat a `list_notify_channels()` hívással.

**Több napos feladatok** — az ajánlott minta hosszú, órákon vagy napokon átívelő munkához:
1. Hozz létre egy feladatot címmel és leírással (chaten, Telegramon vagy a GUI Kanban táblán keresztül).
2. Az agens (vagy te) meghívja a `set_subtasks` eszközt, hogy elnevezett lépésekre bontsa.
3. Minden szívverés-futás felveszi a következő függőben lévő alfeladatot, elvégzi, majd leáll — az egyes LLM-munkamenetek rövidek és fókuszáltak maradnak.
4. A haladás, döntések és köztes eredmények feladat-kommentekként tárolódnak, így minden következő futás teljes kontextussal rendelkezik az előzményekről.
5. Ha minden alfeladat kész, az agens lezárja a feladatot és elküldi a befejezési értesítést.

Ez a minta kódmódosítás nélkül működik — a meglévő feladat-eszközökre épül (`set_subtasks`, `get_next_subtask`, `complete_subtask`), amelyekhez minden `tasks` tool source-szal rendelkező agens hozzáfér.

### Biztonsági felügyelet (Quadrumvirátus)

Opcionális, agent-szintű réteg, amely minden kockázatos eszközhívást ellenőriz, mielőtt lefut. Az `agents.yaml`-ban a `guardian: true` kapcsolóval engedélyezhető; az azt nem tartalmazó agensek viselkedése nem változik.

- **Guardian** — izolált LLM-hívás (eszközök nélkül), amely kiértékeli az eszköz nevét és argumentumait, majd visszaad egyet: `NONE` (folytatás), `SOFT VETO: indok` (emberi döntés szükséges) vagy `HARD VETO: indok` (azonnali blokkolás).
- **Arbiter** — SOFT VETO esetén aktiválódik; Markdown elemző riportot készít, majd LangGraph `interrupt()`-tal felfüggeszti a gráfot. Az operátor Telegram `/approve` paranccsal vagy a GUI-n jóváhagyja vagy elutasítja — ugyanaz a folyamat, mint a HITL.
- **Históriás (Historian)** — szívverés-ütemezett feladat, amely beolvassa a memóriabeli Guardian audit logot, és strukturált riportot ír a `historian_reports` PostgreSQL táblába konfigurálható ütemezéssel.
- **Kockázati besorolás** — az MCP szerverek `risk: low` vagy `risk: high` jelölést kapnak az `mcps.yaml`-ban. A memória-, feladat- és jóváhagyás-eszközök mindig ki vannak zárva az ellenőrzésből, kockázati szinttől függetlenül.

```yaml
# agents.yaml
agents:
  - name: ceo
    guardian: true
    guardian_provider: anthropic        # opcionális — ha üres, örökli az agent providerét
    guardian_model: claude-haiku-4-5-20251001
    arbiter_provider: anthropic
    arbiter_model: claude-sonnet-4-6
```

```yaml
# mcps.yaml
servers:
  - name: playwright
    risk: high        # minden playwright eszköz Guardian jóváhagyást igényel
  - name: hu-tools
    risk: low         # időjárás, hírek — átmennek ellenőrzés nélkül
```

A `/guardian/log` endpoint visszaadja az élő audit logot (utolsó 1 000 döntés).

### AI Act megfelelőségi mód

Egy önálló nyomon-követhetőségi/audit réteg az EU AI Act követelményeihez — független a fenti Quadrumvirátustól, és annak nélküle is használható (nem igényli a Guardian LLM-hívást).

- **Teljes eszközhívás-naplózás** — minden eszközhívás bemenete és kimenete rögzítve a `tool_events` táblában; a konfigurációs változások a `config_audit_log`-ba kerülnek.
- **`ai_act_mode`** — minden eszközhíváshoz emberi jóváhagyási (HITL) kaput ad, a Guardian-ellenőrzéstől függetlenül.
- **Hamisítás ellen védett audit lánc** — az `audit_chain_log` minden bejegyzést hash-lánccal köt az előzőhöz, így az utólagos manipuláció kimutatható; egy opcionális RFC 3161 időbélyegző hatóság (TSA) horgony külső, ellenőrizhető időbizonyítékot ad hozzá.
- **PII-maszkolás** — Presidio-alapú automatikus személyesadat-maszkolás (magyar nyelvi támogatással), mielőtt a napló íródik.
- **Megőrzés** — az audit adatok 6 hónap után automatikusan törlődnek.
- **GUI** — a Beállítások → AI Act fülön látható a lánc állapota, itt lehet horgonyozni és ellenőrizni a láncot, valamint exportálni a bejegyzéseket.

### Hitelesítés és multi-tenancy

| Mód | Leírás |
|---|---|
| `AUTH_MODE=none` | Nyílt — nincs hitelesítés (alapértelmezett, helyi használatra) |
| `AUTH_MODE=local` | Bearer token; felhasználók: `LOCAL_USERS=user1:jelszo1,...` |
| `AUTH_MODE=sso` | Keycloak OIDC/JWT, vagy bármely OIDC provider (Auth0, Okta, Authelia, …) |

**Felhasználónkénti elkülönítés.** Többfelhasználós módban minden felhasználó
memóriája és tudásgráfja elkülönített: a hosszú távú memória saját Qdrant
collection-be kerül, a tudásgráf pedig saját `scope`-ba — az olvasás a sajátot és
az admin által kurált közös réteget látja, más felhasználóét soha. Az éjszakai
memória-karbantartás is **felhasználónként** fut, a sajátjában.

### Megfigyelhetőség

- Pipeline trace-ek token- és költséglogolással.
- Waterfall nézet a GUI Megfigyelhetőség fülén.
- Automatikus trace-törlés (`TRACE_RETENTION_DAYS`).

### Webhook fogadó

Aláírt webhookokat fogad a következőktől: GitHub, Gitea, Drone CI, Grafana, n8n, Slack, ERPNext, Twenty CRM, Zammad, Tiledesk, Uptime Kuma, Wekan, Umami, Duplicati, BorgWarehouse.

### Backup és konfiguráció-perzisztencia

Minden futásidejű adat a `data/` könyvtárban él bind mount-ként; minden konfig YAML fájlban — konténeren belül nincs rejtett állapot.

**Backup készítése** (tartalmazza: `.env` + `data/`):

```bash
sudo python3 backup.py backup                    # interaktív, automatikus fájlnév
sudo python3 backup.py backup /srv/backup.tgz    # megadott kimeneti útvonal
```

**Visszaállítás**:

```bash
python3 backup.py restore /srv/backup.tgz           # visszaállítás az aktuális mappába
python3 backup.py restore /srv/backup.tgz /opt/qai  # visszaállítás adott mappába
```

Linux / macOS rendszeren `sudo`-val futtasd a fájljogosultságok megőrzéséhez. Windowson nincs szükség erre.

---

## Bridge-ek

| Bridge | Transport | Compose profil |
|---|---|---|
| Telegram | Bot API, async (python-telegram-bot) | `telegram` |
| Matrix | matrix-nio, szoba-szintű | `matrix` |
| Discord | discord.py, slash commandok | `discord` |
| IRC | irc3 asyncio, több csatorna | `irc` |
| WhatsApp | Meta Cloud API webhook | `whatsapp` |
| Slack | slack-bolt Socket Mode | `slack` |
| Signal | signal-cli REST API polling | `signal` |
| Viber | FastAPI webhook, billentyűzet gombok | `viber` |

Minden bridge rendelkezik `/notify` (push értesítések az orchestratortól) és `/health` (életjel) végponttal, és támogatja a küldők és csatornák engedélylistáját. A Telegram és a GUI egyaránt támogatja a HITL `/approve` folyamatot. Az összes bridge támogatja a felhasználónkénti nyelvváltást a `/language` paranccsal; a beállítás PostgreSQL-ben tárolódik és container-újraindítás után is megmarad.

---

## Hang

### Mic bridge (saját mikrofon)

Compose profil: `mic`

- openWakeWord — konfigurálható ébresztőszó (alapértelmezett: "Ok Szif").
- Silero VAD — természetes szünetfelismerés (800ms+ csend jelzi a mondat végét) egy fix felvételi ablak helyett.
- Wyoming Whisper — helyi STT, felhő nélkül.
- Wyoming Piper — helyi TTS, mondatonként streamelve (SSE), ahogy a válasz generálódik.
- Megszakítás (barge-in) — az agens beszélő válaszába bele lehet szólni, vagy a "Stop" paranccsal teljesen leállítható.
- PulseAudio socket mount Linux desktopokhoz.

**Platformmegjegyzések:**

- **Linux** — a telepítő automatikusan felismeri a UID-odat és becsatolja a megfelelő PulseAudio socketet (`/run/user/<uid>/pulse`).
- **macOS / Windows** — a Docker Desktop nem továbbítja a hangeszközöket. A telepítő ekkor PulseAudio TCP konfigurációt ír. Állítsd be a PulseAudio-t TCP módban, mielőtt elindítod a mic konténert:
  - macOS: `brew install pulseaudio && pulseaudio --load=module-native-protocol-tcp --exit-idle-time=-1 --daemon`
  - Windows (WSL2): `sudo apt install pulseaudio && pulseaudio --load=module-native-protocol-tcp --exit-idle-time=-1 --start`
  - Windows (natív): töltsd le a PulseAudio for Windows-t, kommenteld ki a `module-native-protocol-tcp` sort a `default.pa` fájlban, engedélyezd a 4713-as portot a tűzfalban.

### Home Assistant Voice PE

Compose profil: `ha`

A QuorumAI konverzációs agentként regisztrál a Home Assistantban. A HA Assist kezeli az ébresztőszó-felismerést, a Whisper STT-t és a Piper TTS-t a HA oldalán; a QuorumAI végzi az AI érvelést és az eszközhívásokat.

### STT és TTS eszközök (agens által hívható)

Compose profil: `stt-tts`

Whispert és Pipert HTTP API-ként teszi elérhetővé, amelyeket az agensek `system-stt` és `system-tts` eszközként hívhatnak.

### OmniVoice TTS (hangklónozás)

Compose profil: `stt-tts`

PyTorch-alapú neurális TTS szolgáltatás (`POST /synthesize`, `/clone`, `/voices`), amelyet az orchestrator `/tts/*` proxyja tesz elérhetővé. 8 beépített magyar hanggal érkezik, és feltöltött hangmintából új hangot tud klónozni. Az agensek `tts_speak_omnivoice` eszközként hívhatják; a GUI Chat fülén is felolvastatható vele a válasz (🔊 gomb, Piper↔OmniVoice backend váltóval, hang- és sebességválasztóval, mondatonkénti auto-streameléssel). A **Hang Stúdió** GUI fül a dedikált hely a hangok kezeléséhez és a szintézis/klónozás kipróbálásához.

---

## GUI

Compose profil: `gui` — elérhető: `http://localhost:3000`

React, Vite és Tailwind CSS alapon.

| Fül | Leírás |
|---|---|
| Chat | Üzenetek küldése bármely agensnek; szavankénti streamelt válasz élő gondolkodás-nézettel és eszközhívás-jelzéssel |
| Feladatok | Kanban tábla; alfeladat-fa; megjegyzések; jóváhagyás gombok |
| Szívverés | Ütemező állapota; következő futási idők; manuális indítás; cron jobok létrehozása/szerkesztése/törlése |
| Agent Builder | Agensek létrehozása és szerkesztése: provider, modell, eszközök, promptok, Guardian, autonóm (deep) mód |
| Company Diagram | Élő cégdiagram — dispatcher → beosztottak automatikusan elrendezett DAG-ként, több szülős csomópontok, zoom/pásztázás, minitérkép |
| Skill Editor | Markdown skill szerkesztő eszköztárral és élő előnézettel; Skill Piactér (böngészés/keresés/telepítés 6 forrásból, GitHub URL importtal is) |
| Megfigyelhetőség | Élő állapotnézet; pipeline trace-ek token/költség-waterfall nézete; tudásgráf vizualizáció |
| Tudásbázis | Tudásbázis-dokumentumok (PDF, DOCX, táblázatok, …) feltöltése és kezelése, bármely agens visszakeresheti |
| Hang Stúdió | OmniVoice szövegfelolvasás: szintézis, hangklónozás audio mintából, a 8 beépített hang kezelése |
| MCP Manager | MCP szerverek telepítése/eltávolítása piactérről futásidőben; agentenkénti eszközbekötés kezelése |
| Beállítások | Providerek, push értesítések, webhookok, Home Assistant, OpenAI-kompatibilis API kulcs, felhasználók/SSO, AI Act megfelelőségi állapot, licenc szint |

- 33 felhasználói felület nyelv, 14 téma.
- HITL jóváhagyás gombok integrálva a Chat és Feladatok füleken.

---

## Telepítési részletek

### Előfeltételek

- Docker Engine 24+ és Docker Compose v2.
- Python 3.8+ az `install.py`-hoz — pip vagy virtualenv nem szükséges.
- Helyi modelleknél: Ollama a host gépen, 11434-es porton.

### Megosztott hálózat létrehozása (egyszer, gépenként)

```bash
docker network create quorum-net
```

### Profilok kiválasztása

A `.env`-ben beállítva, hogy a sima `docker compose up -d` is működjön:

```env
COMPOSE_PROFILES=orchestrator,memory,mcp,postgres,telegram,gui
```

Vagy explicit megadással:

```bash
docker compose --profile orchestrator --profile memory --profile gui up -d
```

Elérhető profilok: `orchestrator`, `memory`, `mcp`, `postgres`, `telegram`, `ha`, `mic`, `gui`, `stt-tts`, `mcp-manager`, `playwright`, `joplin`, `auth`, `email`, `matrix`, `discord`, `irc`, `whatsapp`, `slack`, `signal`, `viber`, `graph`

### Újraépítés forráskód-változás után

```bash
# Csak a módosított service újraépítése:
docker compose build orchestrator

# Újraindítás a többi konténer érintése nélkül:
docker compose up -d --no-deps orchestrator
```

### Data könyvtár felépítése

```
data/
  qdrant/        # Qdrant vektorok
  postgres/      # PostgreSQL adatok
  workspace/     # per-agent fájl munkaterület
  whisper/       # Whisper modell cache
  piper/         # Piper hangfájlok
  ...
```

A `data/` alatti minden gitignorált. Ennek a könyvtárnak a mentése az összes perzisztens állapotot megőrzi.

### Felügyelet nélküli telepítés (Ansible / CI)

Az `install.py` alapból interaktív, de minden kérdés előre megválaszolható környezeti változóval, így egy frissen bérelt/felhúzott VM felügyelet nélkül is telepíthető (Ansible `command`/`shell` modul, cloud-init, CI). Ha a stdin nem terminál (Ansible alatt ez mindig igaz), a telepítő sosem akad be — minden olyan kérdés, amihez nincs megfelelő környezeti változó, egyszerűen a normál alapértékére esik vissza, nem vár bemenetre.

Támogatott felülíró változók:

| Változó | Hatás |
|---|---|
| `QUORUM_LANG` | Nyelvkód (pl. `en`, `hu`) — kihagyja a nyelvválasztó menüt. |
| `QUORUM_MODE` | `full` vagy `satellite` — kihagyja a telepítési mód menüt. |
| `QUORUM_INSTALL_DIR` | Célkönyvtár — kihagyja a könyvtár-választó kérdést. |
| `QUORUM_MODULES` | Vesszővel elválasztott modul-id-k — teljesen kihagyja a modulválasztó checkbox-ot. A teljes id-listát lásd lent. |
| `QUORUM_LICENSE_KEY` | A kötelező licenckulcs (30 napos ingyenes trial: https://license.quorumai.eu). |
| `QUORUM_INDUSTRY_PACK` | Csomag id (`agency`, `devops`, `legal`) vagy `none`. |
| `QUORUM_ORCHESTRATOR_URL` | Csak satellite módban — a távoli orchestrator URL-je. |
| Bármelyik másik `.env` kulcs (pl. `POSTGRES_PASSWORD`, `TELEGRAM_BOT_TOKEN`, `ANTHROPIC_API_KEY`, `ORCHESTRATOR_API_KEY`, …) | Ha a `.env`-ben szereplő **pontosan ugyanolyan nevű** változót exportálod, az kitölti azt a kérdést — ez minden modul env-változójára és minden LLM provider-kulcsra igaz, nem csak a fent felsoroltakra. |

Modul-id-k a `QUORUM_MODULES`-hez: `orchestrator`, `memory`, `mcp`, `postgres`, `gui`, `stt-tts`, `telegram`, `matrix`, `discord`, `irc`, `whatsapp`, `slack`, `signal`, `viber`, `mic`, `ha`, `email`, `graph`, `auth`, `mcp-manager`, `playwright`, `joplin`, `atlassian`, `google-workspace`, `crm`, `jog-hu`, `jog-hu-host`, `grafana-mcp`, `uptime-kuma-mcp`, `hyperframes`, `global-news`, `world-weather`, `bash-mcp`, `bash-mcp-host`.

Példa Ansible task egy vadonatúj VM-en:

```yaml
- name: QuorumAI telepítése felügyelet nélkül
  command: python3 install.py
  args:
    chdir: /opt/quorumai-src
  environment:
    QUORUM_INSTALL_DIR: /opt/quorum
    QUORUM_MODE: full
    QUORUM_MODULES: "orchestrator,memory,mcp,postgres,gui,telegram"
    QUORUM_LICENSE_KEY: "{{ quorum_license_key }}"
    POSTGRES_PASSWORD: "{{ quorum_postgres_password }}"
    ANTHROPIC_API_KEY: "{{ quorum_anthropic_api_key }}"
    TELEGRAM_BOT_TOKEN: "{{ quorum_telegram_bot_token }}"
    TELEGRAM_CHAT_ID: "{{ quorum_telegram_chat_id }}"
    QUORUM_INDUSTRY_PACK: none
```

A telepítő sosem futtatja le saját magától a `docker compose up -d`-t, ha a stdin nem terminál — helyette kiírja a fájlokat és a pontos, kézi indítási parancsot, tehát egy rákövetkező Ansible tasknak kell explicit módon lefuttatnia a `docker network create quorum-net` és `docker compose up -d` parancsokat a telepítési könyvtárban.

---

## Konfiguráció

Másold a `.env.example`-t `.env`-be és töltsd ki, amire szükséged van. A `.env.example` fájl minden kulcshoz tartalmaz inline dokumentációt.

### Legfontosabb kulcsok

| Kulcs | Alapértelmezett | Leírás |
|---|---|---|
| `COMPOSE_PROFILES` | — | Indítandó profilok vesszővel elválasztva |
| `AUTH_MODE` | `none` | `none` / `local` / `sso` |
| `ORCHESTRATOR_PORT` | `8000` | Orchestrator FastAPI port |
| `GUI_PORT` | `3000` | GUI port |
| `QDRANT_HTTP_PORT` | `6333` | Qdrant REST port |
| `POSTGRES_PORT` | `5433` | PostgreSQL port |
| `POSTGRES_PASSWORD` | `changeme` | PostgreSQL jelszó — változtasd meg! |
| `TRACE_RETENTION_DAYS` | `14` | Trace-ek automatikus törlése N nap után |
| `ANTHROPIC_API_KEY` | — | Anthropic provider esetén szükséges |
| `OPENROUTER_API_KEY` | — | OpenRouter esetén szükséges |
| `OPENAI_API_KEY` | — | OpenAI esetén szükséges |
| `GOOGLE_API_KEY` | — | Google Gemini esetén szükséges |
| `TELEGRAM_BOT_TOKEN` | — | Telegram bridge-hez szükséges |
| `TELEGRAM_CHAT_ID` | — | Fogadott üzenetek chat ID-ja |
| `NOTIFY_TELEGRAM_CHAT_ID` | — | Chat ID feladat-kész értesítésekhez (ha ugyanaz, mint `TELEGRAM_CHAT_ID`) |
| `MATRIX_HOMESERVER` | — | Matrix szerver URL |
| `MATRIX_ACCESS_TOKEN` | — | Matrix bot hozzáférési token |
| `DISCORD_BOT_TOKEN` | — | Discord bridge-hez szükséges |
| `SLACK_BOT_TOKEN` | — | Slack bridge-hez szükséges |
| `SLACK_APP_TOKEN` | — | Slack Socket Mode-hoz szükséges |
| `SIGNAL_PHONE` | — | Telefonszám a Signal bridge-hez |
| `VIBER_AUTH_TOKEN` | — | Viber bridge-hez szükséges |
| `HA_URL` | `http://homeassistant:8123` | Home Assistant alap URL |
| `HA_TOKEN` | — | HA Long-Lived Access Token |
| `IMAP_HOST` | — | IMAP szerver az Email MCP-hez |
| `SMTP_HOST` | — | SMTP szerver az Email MCP-hez |
| `FALKORDB_URL` | — | Tudásgráf engedélyezéséhez |
| `VAPID_EMAIL` | — | Web push értesítésekhez szükséges |
| `VAPID_PRIVATE_KEY` | — | A telepítő automatikusan generálja (szükséges a `cryptography` Python csomag); egyébként: `docker compose exec orchestrator python3 webpush.py` |
| `VAPID_PUBLIC_KEY` | — | A privát kulccsal együtt generálódik |
| `HU_TOOLS_PORT` | `4300` | hu-tools MCP port |
| `WHISPER_URL` | `http://whisper-http:8000` | STT service URL |
| `PIPER_URL` | `http://piper-http:5000` | TTS service URL |
| `ORCHESTRATOR_API_KEY` | — | A telepítő automatikusan generálja; service-to-service token bridge-ekhez (szükséges `AUTH_MODE=local/sso` esetén) |
| `CONVERSATION_API_KEY` | — | A telepítő automatikusan generálja; védi a HA `/conversation` végpontot (üres = nyílt) |

Az agensek konfigurációja az `orchestrator/agents.yaml` fájlban történik — nem a `.env`-ben.

---

## Iparági csomagok

Előre elkészített vertikális csomagok iparág-specifikus felhasználóknak. Minden csomag skill fájlokat, javasolt agent konfigurációt és MCP hivatkozásokat tartalmaz. Telepíthető az `install.py`-n keresztül vagy manuálisan.

| Csomag | Célcsoport | Főbb skill-ek |
|---|---|---|
| `legal` | Jogi irodák | Dokumentumkeresés, szerződéselemzés, magyar jogi kutatás |
| `devops` | IT/DevOps cégek | Incidenskezelés, runbook keresés, AIOps HITL-lel |
| `agency` | Marketing és PR ügynökségek | Projekt státusz, lead kvalifikáció, brief elemzés, ügyfélriporting |

**Kézi telepítés:**
```bash
cp industry-packs/legal/skills/*.md data/skills/
cat industry-packs/legal/agents.yaml
```

**Telepítőn keresztül:** `python3 install.py` → Módosítás → válassz iparági csomagot.

Saját csomag létrehozása: másold az `industry-packs/_template/` könyvtárat és töltsd ki a `pack.yaml`-t.

---

## CRM integráció

A CRM MCP (`mcps/crm/`) egységes eszközfelületet biztosít több CRM rendszerhez cserélhető adapter architektúrán keresztül. Az agenseknek mindegy, melyik CRM van a háttérben.

**Támogatott adapterek:**

| Adapter | Rendszer | Típus |
|---|---|---|
| `minicrm` | MiniCRM (vezető HU CRM) | Teljes |
| `hubspot` | HubSpot CRM | Teljes |
| `pipedrive` | Pipedrive | Teljes |
| `billingo` | Billingo számlázás | Csak olvasás |
| `szamlazzhu` | Számlázz.hu számlázás | Csak olvasás |
| `salesautopilot` | SalesAutopilot (HU marketing automation) | Teljes |
| `twenty` | Twenty CRM | Teljes |

**Elérhető tool-ok:** `search_entities`, `get_entity`, `create_entity`, `update_entity`, `add_note`, `get_timeline`, `link_entities`, `get_related`, `emit_event`, `list_entity_types`

**Gyors indítás:**
```env
CRM_ADAPTER=minicrm
MINICRM_SYSTEM_ID=12345
MINICRM_API_KEY=your-key
```

```bash
docker compose --profile crm up -d
```

Adj hozzá `crm`-t az agent `tools:` listájához az `agents.yaml`-ban, hogy CRM-hozzáférést kapjon.

---

## jog.gov.hu MCP — Magyar jogszabálykereső

A jog.gov.hu MCP (`mcps/jog-hu/`) magyar jogi információhoz ad hozzáférést az agenteknek, két üzembe helyezési módban:

**Docker mód** (mindig működik, Playwright nem szükséges):

| Tool | Leírás |
|---|---|
| `search_njt_laws(keywords)` | Kulcsszavas keresés az njt.jog.gov.hu-n — egyező törvénycímeket és URL-eket ad vissza |
| `get_law_text(law_id, section)` | Teljes vagy részleges törvényszöveg az njt.hu-ról (pl. `"2012. évi I. törvény"`, section `"69"`) |
| `list_recent_laws(category, days)` | Legújabb jogszabályok a Magyar Közlöny RSS feedből |

**Host mód** (AI-alapú keresés, a `host_server.py` futtatása szükséges a host gépen):

| Tool | Leírás |
|---|---|
| `search_law(question)` | Természetes nyelvű kérdés → AI válasz + hivatkozott jogszabályok (jog.gov.hu) |

A reCAPTCHA v3 elsősorban **IP-reputáció** alapján pontozza a munkameneteket. A Docker konténerek IP-címei és a felhős/VPS-szerverek IP-tartományai adatközponti tartománynak minősülnek, és alacsony megbízhatósági pontot kapnak — böngésző-fingerprint-módosítástól függetlenül. Egy otthoni vagy irodai gép **lakossági IP-n** elég magas pontot kap az átjutáshoz. Grafikus felületre **nincs szükség** — a böngésző headless módban fut; a kijelző nem számít.

**Gyors indítás (Docker eszközök — mindig működik):**
```bash
docker compose --profile jog-hu up -d
```

**Host szerver indítása (AI keresés — lakossági IP szükséges):**
```bash
# Működik: otthoni/irodai asztaligép vagy laptop (Windows, macOS, Linux)
# NEM működik: felhős/VPS-szervereken (az adatközponti IP-ket a reCAPTCHA blokkolja)
# Grafikus felület NEM szükséges — headless módban fut

pip install mcp fastmcp httpx playwright playwright-stealth
playwright install chromium

python3 mcps/jog-hu/host_server.py --background   # daemon indítása, 4312-es port
python3 mcps/jog-hu/host_server.py --stop          # daemon leállítása
```

**Hozzáadás az `mcps.yaml`-hoz:**
```yaml
- name: jog-hu
  url: http://jog-hu-mcp:4302/mcp/
  description: Magyar jogszabálykereső (njt.hu)

# Opcionális — csak ha a host_server.py fut:
- name: jog-hu-host
  url: http://host.docker.internal:4312/mcp/
  description: Magyar jogi AI keresés (jog.gov.hu)
```

Adj hozzá `jog-hu`-t (és opcionálisan `jog-hu-host`-ot) az agent `tools:` listájához az `agents.yaml`-ban.

---

## Közreműködés

1. Forkold a repót és hozz létre egy feature branch-et.
2. Kövesd a `CLAUDE.md`-ben leírt réteg- és compose-konvenciókat.
3. Add hozzá vagy frissítsd a megfelelő tesztblokkot a `tests.sh`-ban.
4. Nyiss pull requestet az adott fázis vagy funkció leírásával.

---

## Licenc
