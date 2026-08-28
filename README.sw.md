[English](README.md) | [Magyar](README.hu.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Русский](README.ru.md) | [Nederlands](README.nl.md) | [Polski](README.pl.md) | [Українська](README.uk.md) | [Svenska](README.sv.md) | [Italiano](README.it.md) | [日本語](README.ja.md) | [中文](README.zh.md) | [한국어](README.ko.md) | [Kiswahili](README.sw.md)

# QuorumAI

QuorumAI ni mfumo wa kupanga mawakala wengi wa AI, unaoweza kujihifadhi mwenyewe, uliojengwa juu ya LangGraph. Unafanya kazi kabisa ndani ya Docker, unaunganika na majukwaa yote makuu ya ujumbe, unasaidia mazungumzo ya sauti, udhibiti wa nyumba mahiri, na kuiga "kampuni" ya AI yenye majukumu mengi yenye kumbukumbu ya muda mrefu na utekelezaji wa kazi kwa kujitegemea.

![Python 3.11](https://img.shields.io/badge/Python-3.11-blue.svg) ![Docker](https://img.shields.io/badge/Docker-Compose-2496ED.svg)

---

## QuorumAI ni nini

QuorumAI hubadilisha LLM moja au zaidi kuwa timu ya mawakala wa AI ambao wanaweza:

- Kujibu maswali, kusoma habari, na kudhibiti vifaa vya nyumba mahiri — ikianzishwa kupitia kipaza sauti, Telegram, Matrix, Discord, Slack, Signal, WhatsApp, Viber, au IRC.
- Kukabidhi kazi kati ya majukumu maalum (Mkurugenzi Mkuu, msanidi programu, mauzo) na kudumisha kumbukumbu ya muda mrefu kati ya vikao kwa kutumia utafutaji wa vektori wa Qdrant.
- Kutekeleza kazi kwa kujitegemea kupitia kipanga ratiba cha moyo, kuomba idhini ya binadamu inapohitajika (HITL), na kuonyesha uwezo wote wa nje kama seva ya MCP (Itifaki ya Muktadha wa Mfano).

Kila kitu kimewekwa katika YAML. Hakuna mabadiliko ya msimbo yanayohitajika kubadilisha mifano, kuongeza mawakala, au kuunganisha zana mpya.

---

## Usakinishaji wa Haraka

### Amri moja (inayopendekezwa)

Kisanikisha cha bootstrap huangalia kama Python 3 na Docker zipo, huzisanikisha zikosekanapo, kisha huendesha kisanikisha cha QuorumAI cha mwingiliano.

**Linux / macOS:**
```bash
curl -fsSL https://raw.githubusercontent.com/FulopJozsi/QuorumAI/main/install.sh | bash
```

**Windows (PowerShell — endesha kama Msimamizi):**
```powershell
irm https://raw.githubusercontent.com/FulopJozsi/QuorumAI/main/install.ps1 | iex
```

Au pakua `install.bat` / `install.ps1` kutoka kwenye hazina na bonyeza mara mbili.

> **Kumbuka:** Kwenye Linux, bootstrap husanikisha Docker Engine kutoka kwenye hazina rasmi ya Docker (apt/dnf/yum kulingana na usambazaji) na kuongeza mtumiaji wako kwenye kikundi cha `docker`. Kutoka nje na kuingia tena kunahitajika baadaye. Kwenye macOS na Windows, husanikisha Docker Desktop na kukuomba uianzishe kabla ya kuendelea.

---

### Una Python 3 na Docker tayari?

Nakili hazina na endesha kisanikisha cha mwingiliano moja kwa moja — pip wala utegemezi wa ziada hauhitajiki:

```bash
git clone https://github.com/FulopJozsi/QuorumAI.git
cd QuorumAI
python3 install.py
```

Kisanikisha:
- Kinawasilisha kichaguzi cha moduli cha mwingiliano (orchestrator, madaraja, sauti, GUI na zaidi).
- Kinaandika `.env` kutoka majibu yako, kinaunda saraka za bind-mount za `data/` na kuendesha `docker compose up -d`.
- Kiolesura cha kisanikisha kinapatikana katika lugha 16.

**Hali ya Satellite** — kuendesha kipaza sauti, madaraja au seva za MCP kwenye mashine tofauti:
```bash
python3 install.py   # chagua "Satellite" unapoulizwa
```

---

## Kuanza Haraka

```bash
git clone https://github.com/FulopJozsi/QuorumAI.git
cd QuorumAI
python3 install.py
```

Thibitisha kwamba mpanga anafanya kazi:

```bash
curl http://localhost:8000/health
```

Tuma ujumbe wa majaribio:

```bash
curl -X POST http://localhost:8000/invoke \
  -H 'Content-Type: application/json' \
  -d '{"message": "Hello, introduce yourself."}'
```

Fungua GUI kwenye `http://localhost:3000`.

---

## Usanifu

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

Kila tabaka lipo katika saraka yake mwenyewe yenye `compose.yml` yake mwenyewe. `compose.yml` ya mzizi inaunganisha tabaka zote kupitia `include:` na wasifu wa Docker Compose — unaanzisha tu unachohitaji.

---

## Vipengele

### Upangaji wa Msingi

- **Mazingira ya utekelezaji ya LangGraph** — grafu ya mawakala wa mashine ya hali, ukaguzi wa hali wa HITL asilia, `AsyncPostgresSaver`.
- **FastAPI HTTP API** — `POST /invoke`, `GET /health`, utiririshaji, kipokezi cha webhook, uwasilishaji wa arifa za kusukuma.
- **agents.yaml** — tangaza mawakala katika YAML: jina, jukumu, mtoa huduma, mfano, njia ya ombi la mfumo, zana.
- **Upakiaji moto** — `POST /agents/reload` huhuisha `agents.yaml` bila kuanzisha upya chombo.
- **Itifaki ya zana ya MCP** — kila uwezo wa nje ni seva ya MCP; mawakala hugundua zana kiotomatiki.
- **Kumbukumbu ya vektori ya Qdrant** — utafutaji mseto wa kisemantiki + BM42 wa kileksika, vipachikwaji vya lugha nyingi multilingual-e5-large, makusanyo ya kila wakala, uondoaji nakala kwa kosini, ukumbushaji ulioanuwaiwa kwa MMR.
- **Ujumuishaji wa kumbukumbu wa usiku** — kazi ya «ndoto» iliyopangwa inayochuja historia ya vikao vya PostgreSQL kuwa ukweli wa muda mrefu wa Qdrant; inaunganisha maendeleo, huondoa maingizo ya muda mfupi yaliyopitwa na wakati; hali inafuatiliwa katika PostgreSQL.
- **PostgreSQL** — kikaguzi cha `AsyncPostgresSaver` cha LangGraph + jedwali za kazi na maoni.
- **Grafu ya maarifa** — FalkorDB (inayooana na Redis), maswali ya Cypher ya mtumiaji, uchimbaji wa moja kwa moja wa taasisi.

### Watoa huduma wa LLM (kwa kila wakala, umewekwa katika agents.yaml)

| Za Ndani | Wingu |
|---|---|
| Ollama (chaguo-msingi, bila ufunguo) | Anthropic Claude |
| llama.cpp | OpenAI |
| LM Studio | OpenRouter |
| vLLM | Google Gemini |
| Docker Model Runner | Grok (xAI) |
| Unsloth Studio | DeepSeek |
| | Mistral AI |
| | Together AI |
| | Fireworks AI |
| | Zhipu AI / Z.AI |
| | Eden AI (mkusanyaji) |
| | NVIDIA NIM (kiwango cha bure kinapatikana) |

Hakuna ufunguo wa API unaohitajika kuanza — Ollama inafanya kazi ndani ya nchi bila malipo.

**Madimbwi ya watoa huduma** — seva nyingi za ndani zinazofanana (k.m. mashine sita za Ollama) zinaweza kukusanywa kwenye dimbwi lenye jina. Mpanga njia hugawanya maombi kwa usawazishaji wa mzigo wa least-connections; iwapo wanachama wote wa dimbwi wameshindwa, inarudi kwenye mnyororo wa kawaida wa fallback. Imesanidiwa katika `providers.yaml` na inaweza kusimamiwa kutoka kichupo cha Watoa Huduma kwenye GUI.

### Uigizaji wa kampuni ya mawakala wengi

- Mawakala kulingana na majukumu: Mkurugenzi Mkuu, msanidi programu, wakala wa mauzo, na jukumu lolote la kibinafsi.
- Wakala wa kuelekeza huelekeza maombi yanayoingia kwa mtaalamu sahihi kiotomatiki.
- Mawakala wa mstari wa bomba: vitanzi vya mpangaji → mtekelezaji → mkaguzi yenye hali inayoshirikiwa.
- **Mawakala wa kujitegemea (Deep)** — weka `deep: true` kwenye wakala yoyote au hatua ya mstari wa bomba ili kuwezesha mzunguko wa LangGraph ReAct uliojengwa ndani. Wakala hupanga, hutekeleza na kurudia kwa uhuru — huita zana mara kwa mara hadi kazi ikamilike au kikomo cha hiari cha simu za zana kifikiwe (`deep_max_steps`, 0 = bila kikomo). Inaweza kusanidiwa kwa kila wakala na kwa kila hatua ya mstari wa bomba; kibonyezi kinapatikana kwenye GUI Agent Builder.
- Maktaba ya ujuzi: faili za ujuzi za Markdown, upakiaji wa uchawi kwa kila wakala, soko la jamii la kushirikiana.
- Eneo la kazi linaloshirikiwa: mawakala wanaweza kusoma na kuandika eneo la faili linaloshirikiwa.
- **Zana za utawala** — mawakala wenye jukumu la `admin` wanaweza kuunda na kufuta mawakala, ujuzi, seva za MCP, kazi za cron na ratiba za moyo wakati wa utekelezaji kupitia zana za `system-admin`. Kila kitendo cha kuandika kinahitaji idhini ya HITL kabla ya utekelezaji.

### Usimamizi wa kazi na uhuru

- Ubao wa Kanban wenye kazi ndogo na maoni (inayotokana na PostgreSQL).
- Kipanga ratiba cha moyo: mawakala huchukua kazi zinazongoja kiotomatiki (kila dakika 5 kwa chaguo-msingi).
- Utekelezaji wa kujitegemea na malango ya idhini ya HITL (Telegram `/approve`, vitufe vya GUI).
- Arifa za kusukuma: Telegram, Home Assistant `notify`, kusukuma wavuti (VAPID). Kazi zinaweza kubainisha uga wa `notify_channel` ili ujumbe wa kukamilika uwasilishwe kwa daraja sahihi bila kujali kikao kilichounda kazi hiyo. Mawakala wanaweza kuita `list_notify_channels()` kupata orodha ya njia zinazopatikana wakati wa utekelezaji.

**Kazi za siku nyingi** — mfano unaopendekezwa kwa kazi ndefu inayochukua masaa au siku:
1. Unda kazi yenye kichwa na maelezo (kupitia gumzo, Telegram, au ubao wa Kanban wa GUI).
2. Wakala (au wewe) huita `set_subtasks` kuigawanya katika hatua zilizo na majina.
3. Kila uendeshaji wa heartbeat huchukua kazi ndogo inayofuata inayosubiri, kuikamilisha, na kusimama — vikao vya LLM vya kibinafsi hubaki vifupi na vilivyolenga.
4. Maendeleo, maamuzi, na matokeo ya kati huhifadhiwa kama maoni ya kazi ili kila uendeshaji unaofuata uwe na muktadha kamili wa kilichotokea kabla.
5. Kazi zote ndogo zinapokamilika, wakala hufunga kazi na kutuma arifa ya ukamilishaji.

Mfano huu unafanya kazi bila mabadiliko ya msimbo — umejengwa juu ya zana za kazi zilizopo (`set_subtasks`, `get_next_subtask`, `complete_subtask`) ambazo wakala yeyote mwenye chanzo cha zana `tasks` tayari ana ufikiaji wake.

### Usimamizi wa usalama (Quadrumviratus)

Tabaka la hiari kwa kila wakala ambalo linakagua kila simu ya zana yenye hatari kabla ya kutekelezwa. Imewezeshwa kwa `guardian: true` katika `agents.yaml`; mawakala bila bendera hii hawathiriwa.

- **Guardian** — simu ya LLM iliyotengwa (bila zana) inayotathmini jina la zana na hoja na kurudisha: `NONE` (endelea), `SOFT VETO: sababu` (uamuzi wa binadamu unahitajika) au `HARD VETO: sababu` (kizuizi cha haraka).
- **Msuluhishi (Arbiter)** — anawashwa kwenye SOFT VETO; anazalisha ripoti ya uchambuzi wa Markdown na kusimamisha grafu kupitia LangGraph `interrupt()`. Opereta anaidhinisha au kukataa kupitia Telegram `/approve` au GUI — mtiririko sawa na HITL.
- **Mwanahistoria (Historian)** — kazi ya mapigo ya moyo inayosoma kumbukumbu ya ukaguzi ya Guardian kutoka kwa kumbukumbu na kuandika ripoti iliyoandaliwa kwenye jedwali la PostgreSQL `historian_reports`.
- **Uainishaji wa hatari** — seva za MCP zimewekwa alama `risk: low` au `risk: high` katika `mcps.yaml`. Zana za kumbukumbu, kazi, na idhini zimewekwa kando kila wakati bila kujali kiwango cha hatari.

```yaml
# agents.yaml
agents:
  - name: ceo
    guardian: true
    guardian_provider: anthropic        # si lazima — inarithi mtoa huduma wa wakala ikiwa tupu
    guardian_model: claude-haiku-4-5-20251001
    arbiter_provider: anthropic
    arbiter_model: claude-sonnet-4-6
```

```yaml
# mcps.yaml
servers:
  - name: playwright
    risk: high        # zana zote za playwright zinahitaji idhini ya Guardian
  - name: hu-tools
    risk: low         # hali ya hewa, habari — zinapitishwa bila ukaguzi
```

Mwisho wa `/guardian/log` unarejesha kumbukumbu ya ukaguzi ya moja kwa moja (maamuzi 1,000 ya hivi karibuni).

### Uthibitishaji na usimamizi wa wakala wengi

| Hali | Maelezo |
|---|---|
| `AUTH_MODE=none` | Wazi — bila uthibitishaji (chaguo-msingi, inafaa kwa matumizi ya ndani ya nchi) |
| `AUTH_MODE=local` | Tokeni ya Bearer; watumiaji wamewekwa katika `LOCAL_USERS=mtumiaji1:nywila1,...` |
| `AUTH_MODE=sso` | Keycloak OIDC/JWT, au mtoa huduma wowote wa OIDC (Auth0, Okta, Authelia, …) |

**Utenganisho kwa kila mtumiaji.** Katika hali ya watumiaji wengi, kumbukumbu
na grafu ya maarifa ya kila mtumiaji zimetenganishwa: kumbukumbu ya muda mrefu
huingia katika mkusanyo wake wa Qdrant na grafu katika `scope` yake — kusoma
huona data yake mwenyewe na safu ya pamoja iliyoandaliwa na msimamizi, kamwe si
ya mtumiaji mwingine. Matengenezo ya usiku pia hufanyika **kwa kila
mtumiaji**.

### Uangalizi

- Nyayo za mstari wa bomba zenye kumbukumbu ya tokeni na gharama kwa kila zamu.
- Mwonekano wa maporomoko ya maji kwenye kichupo cha Uangalizi cha GUI.
- Usafishaji wa nyayo kiotomatiki unaodhibitiwa na `TRACE_RETENTION_DAYS`.

### Kipokezi cha webhook

Inakubali webhooks zilizosainiwa kutoka: GitHub, Gitea, Drone CI, Grafana, n8n, Slack, ERPNext, Twenty CRM, Zammad, Tiledesk, Uptime Kuma, Wekan, Umami, Duplicati, BorgWarehouse.

### Hifadhi nakala na kudumisha usanidi

Data yote ya wakati wa utekelezaji iko katika `data/` kama bind mounts; usanidi wote katika faili za YAML — hakuna hali iliyofichwa ndani ya kontena.

**Tengeneza nakala ya hifadhi** (inajumuisha `.env` + `data/`):

```bash
sudo python3 backup.py backup                 # mwingiliano, jina la faili otomatiki
sudo python3 backup.py backup /srv/backup.tgz # njia ya matokeo wazi
```

**Rejesha**:

```bash
python3 backup.py restore /srv/backup.tgz          # rejesha kwenye saraka ya sasa
python3 backup.py restore /srv/backup.tgz /opt/qai # rejesha kwenye saraka maalum
```

Kwenye Linux / macOS endesha na `sudo` kuhifadhi umiliki wa faili. Kwenye Windows si lazima.

---

## Madaraja

| Daraja | Usafirishaji | Wasifu wa Compose |
|---|---|---|
| Telegram | Bot API, async (python-telegram-bot) | `telegram` |
| Matrix | matrix-nio, kiwango cha chumba | `matrix` |
| Discord | discord.py, amri za slash | `discord` |
| IRC | irc3 asyncio, njia nyingi | `irc` |
| WhatsApp | Meta Cloud API webhook | `whatsapp` |
| Slack | slack-bolt Socket Mode | `slack` |
| Signal | signal-cli REST API polling | `signal` |
| Viber | FastAPI webhook, vitufe vya kibodi | `viber` |

Kila daraja linaonyesha `/notify` (arifa za kusukuma kutoka kwa mpanga) na `/health` (uhai), na linasaidia orodha nyeupe za watumaji na njia. Telegram na GUI pia zinasaidia mtiririko wa HITL wa `/approve`. Madaraja yote yanasaidia kubadilisha lugha kwa kila mtumiaji kupitia amri ya `/language`; upendeleo huhifadhiwa kwenye PostgreSQL na unabaki baada ya kuanzisha upya kontena.

---

## Sauti

### Daraja la Kipaza Sauti (kipaza sauti cha ndani ya nchi)

Wasifu wa Compose: `mic`

- openWakeWord — neno la kuamsha linaloweza kusanidiwa (chaguo-msingi: "Ok Szif").
- Wyoming Whisper — STT ya ndani ya nchi, bila wingu.
- Wyoming Piper — TTS ya ndani ya nchi.
- Muunganiko wa socket ya PulseAudio kwa kompyuta za Linux.

**Maelezo ya jukwaa:**

- **Linux** — kisakinishi hugundua UID yako na kuunganisha socket sahihi ya PulseAudio (`/run/user/<uid>/pulse`) kiotomatiki.
- **macOS / Windows** — Docker Desktop haipitishi vifaa vya sauti. Kisakinishi huandika usanidi wa PulseAudio TCP badala yake. Sanidi PulseAudio katika hali ya TCP kabla ya kuanzisha chombo cha mic:
  - macOS: `brew install pulseaudio && pulseaudio --load=module-native-protocol-tcp --exit-idle-time=-1 --daemon`
  - Windows (WSL2): `sudo apt install pulseaudio && pulseaudio --load=module-native-protocol-tcp --exit-idle-time=-1 --start`
  - Windows (asili): pakua PulseAudio kwa Windows, ondoa maoni ya `module-native-protocol-tcp` katika `default.pa`, ruhusu bandari 4713 kwenye ngome ya moto.

### Home Assistant Voice PE

Wasifu wa Compose: `ha`

QuorumAI inajisajili kama wakala wa mazungumzo ndani ya Home Assistant. HA Assist inashughulikia ugunduzaji wa neno la kuamsha, Whisper STT, na Piper TTS upande wa HA; QuorumAI inashughulikia fikira na simu za zana.

### Zana za STT na TTS (zinazoweza kuitwa na wakala)

Wasifu wa Compose: `stt-tts`

Inaonyesha Whisper na Piper kama APIs za HTTP ambazo mawakala wanaweza kuziita kama zana za `system-stt` na `system-tts`.

---

## GUI

Wasifu wa Compose: `gui` — inapatikana kwenye `http://localhost:3000`

Imejengwa kwa React, Vite, na Tailwind CSS.

| Kichupo | Maelezo |
|---|---|
| Gumzo | Tuma ujumbe kwa wakala yoyote; angalia majibu yanayotiririka |
| Kijenzi cha Wakala | Mchoro wa kampuni wa kuona; unda na hariri mawakala na majukumu yao |
| Kihariri cha Ujuzi | Unda na simamia faili za ujuzi za Markdown |
| Kazi | Ubao wa Kanban; mti wa kazi ndogo; maoni; vitufe vya idhini |
| Watoa Huduma | Hali ya watoa huduma wakati halisi na orodha ya mifano inayopatikana |
| Moyo | Hali ya kipanga ratiba; nyakati za uendeshaji unaofuata; uchochezi wa mkono |
| Uangalizi | Nyayo za mstari wa bomba; mwonekano wa maporomoko ya maji ya tokeni na gharama |

- Lugha 16 za kiolesura, mandhari 14.
- Vitufe vya idhini vya HITL vilivyounganishwa kwenye vichupo vya Gumzo na Kazi.

---

## Maelezo ya Usakinishaji

### Mahitaji ya awali

- Docker Engine 24+ na Docker Compose v2.
- Python 3.8+ kwa `install.py` — bila pip au virtualenv.
- Kwa mifano ya ndani ya nchi: Ollama inayofanya kazi kwenye mwenyeji kwenye bandari 11434.

### Unda mtandao ulioshirikiwa (mara moja kwa kila mwenyeji)

```bash
docker network create quorum-net
```

### Kuchagua wasifu

Weka wasifu katika `.env` ili `docker compose up -d` safi ifanye kazi:

```env
COMPOSE_PROFILES=orchestrator,memory,mcp,postgres,telegram,gui
```

Au wapitishe wazi:

```bash
docker compose --profile orchestrator --profile memory --profile gui up -d
```

Wasifu unaopatikana: `orchestrator`, `memory`, `mcp`, `postgres`, `telegram`, `ha`, `mic`, `gui`, `stt-tts`, `mcp-manager`, `playwright`, `joplin`, `auth`, `email`, `matrix`, `discord`, `irc`, `whatsapp`, `slack`, `signal`, `viber`, `graph`

### Mpangilio wa saraka ya data

```
data/
  qdrant/        # Vektori za Qdrant
  postgres/      # Data ya PostgreSQL
  workspace/     # Eneo la faili la kila wakala
  whisper/       # Hifadhi ya mfano wa Whisper
  piper/         # Faili za sauti za Piper
  ...
```

Kila kitu chini ya `data/` kimewekwa kwenye gitignore. Kuhifadhi nakala ya saraka hii kunalinda hali yote inayoendelea.

---

## Usanidi

Nakili `.env.example` kwenda `.env` na jaza unachohitaji. Faili ya `.env.example` ina hati za ndani kwa kila ufunguo.

### Funguo muhimu zaidi

| Ufunguo | Chaguo-msingi | Maelezo |
|---|---|---|
| `COMPOSE_PROFILES` | — | Wasifu ulioanishwa kwa koma wa kuanzisha |
| `AUTH_MODE` | `none` | `none` / `local` / `sso` |
| `ORCHESTRATOR_PORT` | `8000` | Bandari ya FastAPI ya mpanga |
| `GUI_PORT` | `3000` | Bandari ya GUI |
| `QDRANT_HTTP_PORT` | `6333` | Bandari ya REST ya Qdrant |
| `POSTGRES_PORT` | `5433` | Bandari ya PostgreSQL |
| `POSTGRES_PASSWORD` | `changeme` | Nywila ya PostgreSQL — ibadilishe! |
| `TRACE_RETENTION_DAYS` | `14` | Futa kiotomatiki nyayo za zamani kuliko siku N |
| `ANTHROPIC_API_KEY` | — | Inahitajika kwa mtoa huduma wa Anthropic |
| `OPENROUTER_API_KEY` | — | Inahitajika kwa OpenRouter |
| `OPENAI_API_KEY` | — | Inahitajika kwa OpenAI |
| `GOOGLE_API_KEY` | — | Inahitajika kwa Google Gemini |
| `TELEGRAM_BOT_TOKEN` | — | Inahitajika kwa daraja la Telegram |
| `TELEGRAM_CHAT_ID` | — | Kitambulisho cha gumzo la Telegram cha kukubali ujumbe |
| `NOTIFY_TELEGRAM_CHAT_ID` | — | Kitambulisho cha gumzo kwa arifa za ukamilishaji wa kazi (sawa na `TELEGRAM_CHAT_ID` kama ni moja) |
| `MATRIX_HOMESERVER` | — | URL ya seva ya Matrix |
| `MATRIX_ACCESS_TOKEN` | — | Tokeni ya ufikiaji ya boti ya Matrix |
| `DISCORD_BOT_TOKEN` | — | Inahitajika kwa daraja la Discord |
| `SLACK_BOT_TOKEN` | — | Inahitajika kwa daraja la Slack |
| `SLACK_APP_TOKEN` | — | Inahitajika kwa Slack Socket Mode |
| `SIGNAL_PHONE` | — | Nambari ya simu kwa daraja la Signal |
| `VIBER_AUTH_TOKEN` | — | Inahitajika kwa daraja la Viber |
| `HA_URL` | `http://homeassistant:8123` | URL ya msingi ya Home Assistant |
| `HA_TOKEN` | — | Tokeni ya ufikiaji ya muda mrefu ya HA |
| `IMAP_HOST` | — | Seva ya IMAP kwa Email MCP |
| `SMTP_HOST` | — | Seva ya SMTP kwa Email MCP |
| `FALKORDB_URL` | — | Weka ili kuwezesha grafu ya maarifa |
| `VAPID_EMAIL` | — | Inahitajika kwa arifa za kusukuma wavuti |
| `VAPID_PRIVATE_KEY` | — | Inazalishwa kiotomatiki na kisakinishi (inahitaji kifurushi cha Python `cryptography`); vinginevyo endesha `docker compose exec orchestrator python3 webpush.py` |
| `VAPID_PUBLIC_KEY` | — | Inazalishwa pamoja na ufunguo wa siri |
| `HU_TOOLS_PORT` | `4300` | Bandari ya MCP ya hu-tools |
| `WHISPER_URL` | `http://whisper-http:8000` | URL ya huduma ya STT |
| `PIPER_URL` | `http://piper-http:5000` | URL ya huduma ya TTS |
| `ORCHESTRATOR_API_KEY` | — | Inazalishwa kiotomatiki na kisakinishi; tokeni ya huduma-kwa-huduma kwa madaraja (inahitajika katika `AUTH_MODE=local/sso`) |
| `CONVERSATION_API_KEY` | — | Inazalishwa kiotomatiki na kisakinishi; inalinda mwisho wa HA `/conversation` (tupu = wazi) |

Mawakala yanasanidiwa katika `orchestrator/agents.yaml` — si katika `.env`.

---

## Pakiti za Sekta

Pakiti za wima zilizojengwa awali kwa sekta maalum. Kila pakiti ina faili za ujuzi, mapendekezo ya usanidi wa mawakala na marejeo ya MCP. Zinasakinishwa kupitia `install.py` au kwa mkono.

| Pakiti | Lengo | Ujuzi Mkuu |
|---|---|---|
| `legal` | Ofisi za Kisheria | Utafutaji wa hati, uchambuzi wa mikataba, utafutaji wa sheria ya Hungaria |
| `devops` | Makampuni ya IT / DevOps | Uchunguzi wa matukio, utafutaji wa runbook, AIOps na HITL |
| `agency` | Wakala wa Uuzaji na Mahusiano ya Umma | Hali ya mradi, sifa za viongozi, uchambuzi wa brief, ripoti za wateja |

**Usakinishaji wa mkono:**
```bash
cp industry-packs/legal/skills/*.md data/skills/
cat industry-packs/legal/agents.yaml
```

**Kupitia kisakinishi:** endesha tena `python3 install.py` → Badilisha → chagua pakiti ya sekta.

Unda pakiti yako mwenyewe kwa kunakili `industry-packs/_template/` na kujaza `pack.yaml`.

---

## Ujumuishaji wa CRM

CRM MCP (`mcps/crm/`) hutoa kiolesura cha pamoja kwa mifumo mingi ya CRM kupitia usanifu wa adapta unaobadilishwa. Mawakala hutumia zana sawa bila kujali mfumo wa nyuma.

**Adapta zinazoungwa mkono:**

| Adapta | Mfumo | Aina |
|---|---|---|
| `minicrm` | MiniCRM (kiongozi wa soko la Hungaria) | Kamili |
| `hubspot` | HubSpot CRM | Kamili |
| `pipedrive` | Pipedrive | Kamili |
| `billingo` | Billingo invoicing | Kusoma tu |
| `szamlazzhu` | Számlázz.hu invoicing | Kusoma tu |
| `salesautopilot` | SalesAutopilot (uendeshaji wa masoko wa HU) | Kamili |

**Zana zinazopatikana:** `search_entities`, `get_entity`, `create_entity`, `update_entity`, `add_note`, `get_timeline`, `link_entities`, `get_related`, `emit_event`, `list_entity_types`

**Kuanza haraka:**
```env
CRM_ADAPTER=minicrm
MINICRM_SYSTEM_ID=12345
MINICRM_API_KEY=your-key
```

```bash
docker compose --profile crm up -d
```

Ongeza `crm` kwenye orodha ya `tools:` ya wakala katika `agents.yaml` ili kumpa ufikiaji wa CRM.

---

## jog.gov.hu MCP — Utafutaji wa Sheria ya Hungaria

MCP ya jog.gov.hu (`mcps/jog-hu/`) hutoa taarifa za kisheria za Hungaria kwa mawakala ya AI katika hali mbili za utumiaji:

**Hali ya Docker** (inafanya kazi daima, Playwright haihitajiki):

| Zana | Maelezo |
|---|---|
| `search_njt_laws(keywords)` | Utafutaji wa maneno muhimu kwenye njt.jog.gov.hu — inarudisha majina ya sheria yanayolingana na URL |
| `get_law_text(law_id, section)` | Maandishi kamili au sehemu ya sheria kutoka njt.hu (k.m. `"2012. évi I. törvény"`, sehemu `"69"`) |
| `list_recent_laws(category, days)` | Sheria za hivi karibuni kutoka kipengele cha RSS cha Magyar Közlöny |

**Hali ya Mwenyeji** (utafutaji wa AI, inahitaji kuendesha `host_server.py` kwenye mashine ya mwenyeji):

| Zana | Maelezo |
|---|---|
| `search_law(question)` | Swali la lugha ya kawaida → jibu la AI + marejeo ya sheria yaliyonukuliwa (jog.gov.hu) |

reCAPTCHA v3 hupima vikao kwa msingi wa **sifa ya IP**, si uonyeshaji wa picha. Anwani za IP za kontena za Docker na seva za wingu/VPS zinaainishwa kama masafa ya kituo cha data na kupata alama ya chini ya uaminifu — bila kujali maboresho ya alama ya kidole cha kivinjari. Mashine ya nyumbani au ofisini yenye **IP ya makazi** inapata alama ya juu ya kutosha kupita. Onyeshaji wa picha **hauhitajiki** — kivinjari hufanya kazi bila kichwa; onyeshaji hana umuhimu.

**Kuanza haraka (zana za Docker — zinafanya kazi daima):**
```bash
docker compose --profile jog-hu up -d
```

**Anzisha seva ya mwenyeji (utafutaji wa AI — IP ya makazi inahitajika):**
```bash
# Inafanya kazi kwenye: kompyuta ya mezani au kompyuta ya mkononi ya nyumbani/ofisini (Windows, macOS, Linux)
# HAIFANYI KAZI kwenye: seva za wingu/VPS (anwani za IP za kituo cha data zimezuiwa na reCAPTCHA)
# Onyeshaji wa picha HAUHITAJIKI — hufanya kazi bila kichwa

pip install mcp fastmcp httpx playwright playwright-stealth
playwright install chromium

python3 mcps/jog-hu/host_server.py --background   # anzisha daemon, bandari 4312
python3 mcps/jog-hu/host_server.py --stop          # simamisha daemon
```

**Ongeza kwenye `mcps.yaml`:**
```yaml
- name: jog-hu
  url: http://jog-hu-mcp:4302/mcp/
  description: Hungarian legal search (njt.hu)

# Hiari — tu iwapo host_server.py inafanya kazi:
- name: jog-hu-host
  url: http://host.docker.internal:4312/mcp/
  description: Hungarian legal AI search (jog.gov.hu)
```

Ongeza `jog-hu` (na hiari `jog-hu-host`) kwenye orodha ya `tools:` ya wakala katika `agents.yaml`.
