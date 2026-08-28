[English](README.md) | [Magyar](README.hu.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Русский](README.ru.md) | [Nederlands](README.nl.md) | [Polski](README.pl.md) | [Українська](README.uk.md) | [Svenska](README.sv.md) | [Italiano](README.it.md) | [日本語](README.ja.md) | [中文](README.zh.md) | [한국어](README.ko.md) | [Kiswahili](README.sw.md)

# QuorumAI

QuorumAI to modularny, samodzielnie hostowany system orkiestracji wielu agentów AI zbudowany na LangGraph. Działa w całości w Dockerze, łączy się ze wszystkimi głównymi platformami komunikacyjnymi, obsługuje interakcję głosową, sterowanie inteligentnym domem i symuluje wielorolową „firmę" AI z długoterminową pamięcią i autonomicznym wykonywaniem zadań.

![Python 3.11](https://img.shields.io/badge/Python-3.11-blue.svg) ![Docker](https://img.shields.io/badge/Docker-Compose-2496ED.svg)

---

## Czym jest QuorumAI?

QuorumAI zamienia jeden lub więcej LLM w zespół agentów AI, który potrafi:

- Odpowiadać na pytania, czytać wiadomości i sterować urządzeniami inteligentnego domu — uruchamiany przez mikrofon, Telegram, Matrix, Discord, Slack, Signal, WhatsApp, Viber lub IRC.
- Delegować pracę między wyspecjalizowanymi rolami (CEO, deweloper, sprzedaż) i utrzymywać długoterminową pamięć między sesjami dzięki wyszukiwaniu wektorowemu Qdrant.
- Autonomicznie wykonywać zadania przez planista heartbeat, żądać zatwierdzenia przez człowieka w razie potrzeby (HITL) i udostępniać każdą zewnętrzną możliwość jako serwer MCP (Model Context Protocol).

Wszystko konfiguruje się w YAML. Nie są potrzebne żadne zmiany w kodzie, aby zmienić modele, dodać agentów lub podłączyć nowe narzędzia.

---

## Szybka instalacja

### Jedna komenda (zalecane)

Skrypt bootstrap sprawdza, czy Python 3 i Docker są zainstalowane, instaluje je w razie potrzeby, a następnie uruchamia interaktywny instalator QuorumAI.

**Linux / macOS:**
```bash
curl -fsSL https://raw.githubusercontent.com/fulopjozsef86/QuorumAI/main/install.sh | bash
```

**Windows (PowerShell — uruchom jako Administrator):**
```powershell
irm https://raw.githubusercontent.com/fulopjozsef86/QuorumAI/main/install.ps1 | iex
```

Lub pobierz `install.bat` / `install.ps1` z repozytorium i kliknij dwukrotnie.

> **Uwaga:** Na Linuksie skrypt bootstrap instaluje Docker Engine z oficjalnego repozytorium Docker (apt/dnf/yum w zależności od dystrybucji) i dodaje użytkownika do grupy `docker`. Wymagane jest wylogowanie i ponowne zalogowanie. Na macOS i Windows instaluje Docker Desktop i prosi o jego uruchomienie przed kontynuacją.

---

### Masz już Python 3 i Docker?

Sklonuj repozytorium i uruchom interaktywny instalator bezpośrednio — pip ani dodatkowe zależności nie są wymagane:

```bash
git clone https://github.com/fulopjozsef86/QuorumAI.git
cd QuorumAI
python3 install.py
```

Instalator:
- Oferuje interaktywny selektor modułów (orchestrator, mosty, głos, GUI i więcej).
- Zapisuje `.env` z Twoich odpowiedzi, tworzy katalogi bind-mount `data/` i uruchamia `docker compose up -d`.
- Interfejs instalatora jest dostępny w 16 językach.

**Tryb Satellite** — uruchamianie mikrofonu, mostów lub serwerów MCP na osobnej maszynie:
```bash
python3 install.py   # wybierz "Satellite" gdy zapytany
```

---

## Szybki start (ręcznie)

```bash
git clone https://github.com/your-org/QuorumAI.git
cd QuorumAI

# Utwórz wspólną sieć Docker (raz na hosta):
docker network create quorum-net

cp .env.example .env
# Edytuj .env — ustaw COMPOSE_PROFILES i potrzebne klucze API

docker compose up -d
```

Sprawdź, czy orkiestrator działa:

```bash
curl http://localhost:8000/health
```

Wyślij wiadomość testową:

```bash
curl -X POST http://localhost:8000/invoke \
  -H 'Content-Type: application/json' \
  -d '{"message": "Hello, introduce yourself."}'
```

GUI dostępne pod adresem: `http://localhost:3000`

---

## Architektura

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

Każda warstwa znajduje się we własnym katalogu z własnym `compose.yml`. Główny `compose.yml` agreguje wszystkie warstwy przez `include:` i profile Docker Compose — uruchamiasz tylko to, czego potrzebujesz.

---

## Funkcje

### Podstawowa orkiestracja

- **Środowisko uruchomieniowe LangGraph** — graf agentów maszyny stanów, natywny checkpointing HITL, `AsyncPostgresSaver`.
- **FastAPI HTTP API** — `POST /invoke`, `GET /health`, streaming, odbiornik webhooków, przekaźnik powiadomień push.
- **agents.yaml** — deklaruj agentów w YAML: nazwa, rola, dostawca, model, ścieżka do promptu systemowego, narzędzia.
- **Gorące przeładowanie** — `POST /agents/reload` przeładowuje `agents.yaml` bez restartu kontenera.
- **Protokół narzędzi MCP** — każda zewnętrzna możliwość jest serwerem MCP; agenci wykrywają narzędzia automatycznie.
- **Pamięć wektorowa Qdrant** — hybrydowe wyszukiwanie semantyczne + BM42 leksykalne, wielojęzyczne embeddingi multilingual-e5-large, kolekcje per agent, deduplikacja kosinusowa, zróżnicowane wyszukiwanie MMR.
- **Nocna konsolidacja pamięci** — zaplanowane zadanie „snu" destyluje historię sesji PostgreSQL w długoterminowe fakty Qdrant; scala postępy, usuwa przestarzałe efemeryczne wpisy; stan śledzony w PostgreSQL.
- **PostgreSQL** — checkpointer `AsyncPostgresSaver` + tabele zadań i komentarzy.
- **Graf wiedzy** — FalkorDB (kompatybilny z Redis), zapytania Cypher na użytkownika, automatyczna ekstrakcja encji.

### Dostawcy LLM (na agenta, konfigurowane w agents.yaml)

| Lokalni | Chmura |
|---|---|
| Ollama (domyślny, bez klucza) | Anthropic Claude |
| llama.cpp | OpenAI |
| LM Studio | OpenRouter |
| vLLM | Google Gemini |
| Docker Model Runner | Grok (xAI) |
| Unsloth Studio | DeepSeek |
| | Mistral AI |
| | Together AI |
| | Fireworks AI |
| | Zhipu AI / Z.AI |
| | Eden AI (agregator) |
| | NVIDIA NIM (dostępny bezpłatny tier) |

Klucz API nie jest potrzebny na start — Ollama działa lokalnie i bezpłatnie.

**Pule dostawców** — wiele identycznych serwerów lokalnych (np. sześć maszyn Ollama) można zgrupować w nazwaną pulę. Orkiestrator rozdziela żądania algorytmem least-connections; jeśli wszyscy członkowie puli zawiodą, przechodzi do zwykłego łańcucha fallback. Konfigurowane w `providers.yaml`, zarządzane z zakładki Dostawcy w GUI.

### Symulacja firmy wieloagentowej

- Agenci oparci na rolach: CEO, deweloper, sprzedaż i dowolna rola niestandardowa.
- Agent dispatcher automatycznie kieruje przychodzące żądania do właściwego specjalisty.
- Agenci potokowi: pętle planista → wykonawca → recenzent ze współdzielonym stanem.
- **Agenci autonomiczni (Deep)** — ustaw `deep: true` na dowolnym agencie lub etapie potoku, aby aktywować wbudowaną pętlę ReAct LangGraph. Agent planuje, wykonuje i iteruje autonomicznie — wywołuje narzędzia wielokrotnie, aż zadanie zostanie wykonane lub osiągnięty zostanie opcjonalny limit wywołań narzędzi (`deep_max_steps`, 0 = bez limitu). Konfigurowalny na poziomie agenta i etapu; przełącznik dostępny w GUI Agent Builder.
- Biblioteka umiejętności: pliki Markdown umiejętności, leniwe ładowanie na agenta, społecznościowy rynek.
- Współdzielony obszar roboczy: agenci mogą czytać i zapisywać we wspólnym obszarze plików.
- **Narzędzia administracyjne** — agenci z rolą `admin` mogą w czasie wykonania tworzyć i usuwać agentów, umiejętności, serwery MCP, zadania cron i harmonogramy heartbeat za pomocą narzędzi `system-admin`. Każda operacja zapisu wymaga zatwierdzenia HITL.

### Zarządzanie zadaniami i autonomia

- Tablica Kanban z podzadaniami i komentarzami (oparta na PostgreSQL).
- Planista heartbeat: agenci automatycznie pobierają oczekujące zadania (domyślnie co 5 minut).
- Autonomiczne wykonywanie z bramkami zatwierdzania HITL (Telegram `/approve`, przyciski GUI).
- Powiadomienia push: Telegram, Home Assistant `notify`, web push (VAPID). Zadania mogą określać pole `notify_channel`, dzięki czemu wiadomość o zakończeniu trafia zawsze do właściwego mostu, niezależnie od tego, która sesja utworzyła zadanie. Agenci mogą wywołać `list_notify_channels()`, aby w czasie wykonania odkryć dostępne kanały.

**Wielodniowe zadania** — zalecany wzorzec dla długotrwałych prac obejmujących godziny lub dni:
1. Utwórz zadanie z tytułem i opisem (przez czat, Telegram lub tablicę Kanban w GUI).
2. Agent (lub ty) wywołuje `set_subtasks`, aby podzielić je na nazwane kroki.
3. Każde uruchomienie heartbeat pobiera następne oczekujące podzadanie, wykonuje je i zatrzymuje się — pojedyncze sesje LLM pozostają krótkie i skupione.
4. Postęp, decyzje i wyniki pośrednie są zapisywane jako komentarze do zadania, dzięki czemu każde kolejne uruchomienie ma pełny kontekst tego, co wydarzyło się wcześniej.
5. Gdy wszystkie podzadania są gotowe, agent zamyka zadanie i wysyła powiadomienie o ukończeniu.

Ten wzorzec działa bez zmian w kodzie — jest oparty na istniejących narzędziach zadań (`set_subtasks`, `get_next_subtask`, `complete_subtask`), do których dostęp ma każdy agent ze źródłem narzędzi `tasks`.

### Nadzór bezpieczeństwa (Quadrumwiratus)

Opcjonalna warstwa na poziomie agenta, która sprawdza każde ryzykowne wywołanie narzędzia przed jego wykonaniem. Aktywowana przez `guardian: true` w `agents.yaml`; agenci bez tej flagi nie są dotknięci.

- **Guardian** — izolowane wywołanie LLM (bez narzędzi), które ocenia nazwę i argumenty narzędzia i zwraca: `NONE` (kontynuuj), `SOFT VETO: powód` (wymagana decyzja człowieka) lub `HARD VETO: powód` (natychmiastowe zablokowanie).
- **Arbiter** — aktywowany przy SOFT VETO; generuje raport analizy Markdown i zawiesza graf przez LangGraph `interrupt()`. Operator zatwierdza lub odrzuca przez Telegram `/approve` lub GUI — ten sam przepływ co HITL.
- **Historyk** — zadanie heartbeat, które odczytuje log audytu Guardian z pamięci i zapisuje ustrukturyzowany raport do tabeli PostgreSQL `historian_reports`.
- **Klasyfikacja ryzyka** — serwery MCP są oznaczone `risk: low` lub `risk: high` w `mcps.yaml`. Narzędzia pamięci, zadań i zatwierdzania są zawsze wykluczone z kontroli.

```yaml
# agents.yaml
agents:
  - name: ceo
    guardian: true
    guardian_provider: anthropic        # opcjonalne — dziedziczy dostawcę agenta jeśli puste
    guardian_model: claude-haiku-4-5-20251001
    arbiter_provider: anthropic
    arbiter_model: claude-sonnet-4-6
```

```yaml
# mcps.yaml
servers:
  - name: playwright
    risk: high        # wszystkie narzędzia playwright wymagają zatwierdzenia Guardiana
  - name: hu-tools
    risk: low         # pogoda, wiadomości — przesyłane bez kontroli
```

Endpoint `/guardian/log` zwraca live log audytu (ostatnie 1 000 decyzji).

### Uwierzytelnianie i wielodostępność

| Tryb | Opis |
|---|---|
| `AUTH_MODE=none` | Otwarty — bez uwierzytelniania (domyślny, do użytku lokalnego) |
| `AUTH_MODE=local` | Token Bearer; użytkownicy w `LOCAL_USERS=user1:haslo1,...` |
| `AUTH_MODE=sso` | Keycloak OIDC/JWT lub dowolny dostawca OIDC (Auth0, Okta, Authelia, …) |

**Izolacja na użytkownika.** W trybie wielu użytkowników pamięć i graf
wiedzy każdego użytkownika są rozdzielone: pamięć długoterminowa trafia do jego
własnej kolekcji Qdrant, a graf do własnego `scope` — odczyt widzi dane własne
oraz wspólną warstwę przygotowaną przez administratora, nigdy dane innego
użytkownika. Nocna konserwacja również działa **per użytkownik**.

### Obserwowalność

- Ślady potoku z logowaniem tokenów i kosztów na turę.
- Widok wodospadu w zakładce Obserwowalność w GUI.
- Automatyczne czyszczenie śladów kontrolowane przez `TRACE_RETENTION_DAYS`.

### Odbiornik webhooków

Przyjmuje podpisane webhooki z: GitHub, Gitea, Drone CI, Grafana, n8n, Slack, ERPNext, Twenty CRM, Zammad, Tiledesk, Uptime Kuma, Wekan, Umami, Duplicati, BorgWarehouse.

### Kopia zapasowa i przechowywanie konfiguracji

Wszystkie dane środowiska uruchomieniowego znajdują się w `data/` jako bind mounts; cała konfiguracja w plikach YAML — brak ukrytego stanu wewnątrz kontenerów.

**Tworzenie kopii zapasowej** (zawiera `.env` + `data/`):

```bash
sudo python3 backup.py backup                 # interaktywnie, automatyczna nazwa pliku
sudo python3 backup.py backup /srv/backup.tgz # jawna ścieżka wyjściowa
```

**Przywracanie**:

```bash
python3 backup.py restore /srv/backup.tgz          # przywróć do bieżącego katalogu
python3 backup.py restore /srv/backup.tgz /opt/qai # przywróć do wybranego katalogu
```

Na Linux / macOS uruchom z `sudo`, aby zachować właścicieli plików. Na Windows nie jest to wymagane.

---

## Mosty

| Most | Transport | Profil Compose |
|---|---|---|
| Telegram | Bot API, async (python-telegram-bot) | `telegram` |
| Matrix | matrix-nio, poziom pokoju | `matrix` |
| Discord | discord.py, slash commands | `discord` |
| IRC | irc3 asyncio, wielokanałowy | `irc` |
| WhatsApp | Meta Cloud API webhook | `whatsapp` |
| Slack | slack-bolt Socket Mode | `slack` |
| Signal | signal-cli REST API polling | `signal` |
| Viber | FastAPI webhook, przyciski klawiatury | `viber` |

Każdy most udostępnia `/notify` (powiadomienia push z orkiestratora) i `/health` (sprawdzenie aktywności) oraz obsługuje listy dozwolonych nadawców i kanałów. Telegram i GUI obsługują również przepływ HITL `/approve`. Wszystkie mosty obsługują przełączanie języka per użytkownik za pomocą polecenia `/language`; preferencja jest przechowywana w PostgreSQL i przeżywa ponowne uruchomienia kontenerów.

---

## Głos

### Most mikrofonu (lokalny mikrofon)

Profil Compose: `mic`

- openWakeWord — konfigurowalne słowo budzące (domyślnie: "Ok Szif").
- Wyoming Whisper — lokalny STT, bez chmury.
- Wyoming Piper — lokalny TTS.
- Montowanie socketu PulseAudio dla komputerów Linux.

**Uwagi dotyczące platform:**

- **Linux** — instalator wykrywa Twój UID i automatycznie montuje właściwy socket PulseAudio (`/run/user/<uid>/pulse`).
- **macOS / Windows** — Docker Desktop nie przekazuje urządzeń audio. Instalator zapisuje zamiast tego konfigurację PulseAudio TCP. Skonfiguruj PulseAudio w trybie TCP przed uruchomieniem kontenera mic:
  - macOS: `brew install pulseaudio && pulseaudio --load=module-native-protocol-tcp --exit-idle-time=-1 --daemon`
  - Windows (WSL2): `sudo apt install pulseaudio && pulseaudio --load=module-native-protocol-tcp --exit-idle-time=-1 --start`
  - Windows (natywny): pobierz PulseAudio dla Windows, odkomentuj `module-native-protocol-tcp` w `default.pa`, zezwól na port 4713 w zaporze sieciowej.

### Home Assistant Voice PE

Profil Compose: `ha`

QuorumAI rejestruje się jako agent konwersacyjny w Home Assistant. HA Assist obsługuje wykrywanie słów budzących, Whisper STT i Piper TTS po stronie HA; QuorumAI obsługuje wnioskowanie i wywołania narzędzi.

### Narzędzia STT i TTS (wywoływalne przez agenta)

Profil Compose: `stt-tts`

Udostępnia Whisper i Piper jako API HTTP, które agenci mogą wywoływać jako narzędzia `system-stt` i `system-tts`.

---

## GUI

Profil Compose: `gui` — dostępne pod adresem `http://localhost:3000`

Zbudowane z React, Vite i Tailwind CSS.

| Zakładka | Opis |
|---|---|
| Chat | Wysyłaj wiadomości do dowolnego agenta; przeglądaj przesyłane strumieniowo odpowiedzi |
| Agent Builder | Wizualny diagram firmy; twórz i edytuj agentów oraz ich role |
| Skill Editor | Twórz pliki umiejętności Markdown i zarządzaj nimi |
| Tasks | Tablica Kanban; drzewo podzadań; komentarze; przyciski zatwierdzania |
| Providers | Status dostawców w czasie rzeczywistym i lista dostępnych modeli |
| Heartbeat | Stan planisty; czasy następnego uruchomienia; ręczne wyzwalanie |
| Observability | Ślady potoku; widok wodospadu tokenów i kosztów |

- 16 języków interfejsu, 14 motywów.
- Przyciski zatwierdzania HITL zintegrowane w zakładkach Chat i Tasks.

---

## Szczegóły instalacji

### Wymagania wstępne

- Docker Engine 24+ i Docker Compose v2.
- Python 3.8+ dla `install.py` — bez pip ani virtualenv.
- Dla modeli lokalnych: Ollama uruchomiony na hoście na porcie 11434.

### Tworzenie wspólnej sieci (raz na hosta)

```bash
docker network create quorum-net
```

### Wybieranie profili

Ustaw profile w `.env`, aby plain `docker compose up -d` działał:

```env
COMPOSE_PROFILES=orchestrator,memory,mcp,postgres,telegram,gui
```

Lub podaj je jawnie:

```bash
docker compose --profile orchestrator --profile memory --profile gui up -d
```

Dostępne profile: `orchestrator`, `memory`, `mcp`, `postgres`, `telegram`, `ha`, `mic`, `gui`, `stt-tts`, `mcp-manager`, `playwright`, `joplin`, `auth`, `email`, `matrix`, `discord`, `irc`, `whatsapp`, `slack`, `signal`, `viber`, `graph`

### Przebudowywanie po zmianach w kodzie źródłowym

```bash
# Przebuduj tylko zmieniony serwis:
docker compose build orchestrator

# Zrestartuj bez dotykania innych kontenerów:
docker compose up -d --no-deps orchestrator
```

### Układ katalogu data

```
data/
  qdrant/        # Wektory Qdrant
  postgres/      # Dane PostgreSQL
  workspace/     # Współdzielony obszar roboczy agentów
  whisper/       # Cache modelu Whisper
  piper/         # Pliki głosowe Piper
  ...
```

Wszystko w `data/` jest gitignored. Kopia zapasowa tego katalogu zachowuje cały stan trwały.

---

## Konfiguracja

Skopiuj `.env.example` do `.env` i wypełnij to, czego potrzebujesz. Plik `.env.example` zawiera wbudowaną dokumentację każdego klucza.

### Najważniejsze klucze

| Klucz | Domyślny | Opis |
|---|---|---|
| `COMPOSE_PROFILES` | — | Profile do uruchomienia, oddzielone przecinkami |
| `AUTH_MODE` | `none` | `none` / `local` / `sso` |
| `ORCHESTRATOR_PORT` | `8000` | Port FastAPI orkiestratora |
| `GUI_PORT` | `3000` | Port GUI |
| `QDRANT_HTTP_PORT` | `6333` | Port REST Qdrant |
| `POSTGRES_PORT` | `5433` | Port PostgreSQL |
| `POSTGRES_PASSWORD` | `changeme` | Hasło PostgreSQL — zmień to! |
| `TRACE_RETENTION_DAYS` | `14` | Automatyczne usuwanie śladów starszych niż N dni |
| `ANTHROPIC_API_KEY` | — | Wymagany dla dostawcy Anthropic |
| `OPENROUTER_API_KEY` | — | Wymagany dla OpenRouter |
| `OPENAI_API_KEY` | — | Wymagany dla OpenAI |
| `GOOGLE_API_KEY` | — | Wymagany dla Google Gemini |
| `TELEGRAM_BOT_TOKEN` | — | Wymagany dla mostu Telegram |
| `TELEGRAM_CHAT_ID` | — | ID czatu Telegram do akceptowania wiadomości |
| `NOTIFY_TELEGRAM_CHAT_ID` | — | ID czatu dla powiadomień o ukończeniu zadania (taki sam jak `TELEGRAM_CHAT_ID` jeśli identyczny) |
| `MATRIX_HOMESERVER` | — | URL serwera Matrix |
| `MATRIX_ACCESS_TOKEN` | — | Token dostępu bota Matrix |
| `DISCORD_BOT_TOKEN` | — | Wymagany dla mostu Discord |
| `SLACK_BOT_TOKEN` | — | Wymagany dla mostu Slack |
| `SLACK_APP_TOKEN` | — | Wymagany dla Slack Socket Mode |
| `SIGNAL_PHONE` | — | Numer telefonu dla mostu Signal |
| `VIBER_AUTH_TOKEN` | — | Wymagany dla mostu Viber |
| `HA_URL` | `http://homeassistant:8123` | Bazowy URL Home Assistant |
| `HA_TOKEN` | — | Długożyjący token dostępu HA |
| `IMAP_HOST` | — | Serwer IMAP dla Email MCP |
| `SMTP_HOST` | — | Serwer SMTP dla Email MCP |
| `FALKORDB_URL` | — | Ustaw, aby włączyć graf wiedzy |
| `VAPID_EMAIL` | — | Wymagany dla powiadomień web push |
| `VAPID_PRIVATE_KEY` | — | Automatycznie generowany przez instalator (wymaga pakietu Python `cryptography`); w przeciwnym razie: `docker compose exec orchestrator python3 webpush.py` |
| `VAPID_PUBLIC_KEY` | — | Generowany razem z kluczem prywatnym |
| `HU_TOOLS_PORT` | `4300` | Port MCP hu-tools |
| `WHISPER_URL` | `http://whisper-http:8000` | URL serwisu STT |
| `PIPER_URL` | `http://piper-http:5000` | URL serwisu TTS |
| `ORCHESTRATOR_API_KEY` | — | Automatycznie generowany przez instalator; token service-to-service dla mostów (wymagany przy `AUTH_MODE=local/sso`) |
| `CONVERSATION_API_KEY` | — | Automatycznie generowany przez instalator; chroni endpoint HA `/conversation` (pusty = otwarty) |

Konfiguracja agentów w `orchestrator/agents.yaml` — nie w `.env`.

---

## Pakiety branżowe

Gotowe pakiety wertykalne dla konkretnych branż. Każdy pakiet zawiera pliki umiejętności, sugerowane konfiguracje agentów i odniesienia do MCP. Instalowane przez `install.py` lub ręcznie.

| Pakiet | Cel | Kluczowe umiejętności |
|---|---|---|
| `legal` | Kancelarie prawne | Wyszukiwanie dokumentów, analiza umów, wyszukiwanie prawa węgierskiego |
| `devops` | Firmy IT/DevOps | Triage incydentów, wyszukiwanie runbook, AIOps z HITL |
| `agency` | Agencje marketingowe i PR | Status projektu, kwalifikacja leadów, analiza briefów, raportowanie klienta |

**Instalacja ręczna:**
```bash
cp industry-packs/legal/skills/*.md data/skills/
cat industry-packs/legal/agents.yaml
```

**Przez instalator:** `python3 install.py` → Modyfikuj → wybierz pakiet branżowy.

Utwórz własny pakiet, kopiując `industry-packs/_template/` i wypełniając `pack.yaml`.

---

## Integracja CRM

CRM MCP (`mcps/crm/`) zapewnia ujednolicony interfejs do wielu systemów CRM poprzez wymienną architekturę adapterów. Agenci używają tych samych narzędzi niezależnie od backendu.

**Obsługiwane adaptery:**

| Adapter | System | Typ |
|---|---|---|
| `minicrm` | MiniCRM (lider rynku węgierskiego) | Pełny |
| `hubspot` | HubSpot CRM | Pełny |
| `pipedrive` | Pipedrive | Pełny |
| `billingo` | Fakturowanie Billingo | Tylko odczyt |
| `szamlazzhu` | Fakturowanie Számlázz.hu | Tylko odczyt |
| `salesautopilot` | SalesAutopilot (HU marketing automation) | Pełny |

**Dostępne narzędzia:** `search_entities`, `get_entity`, `create_entity`, `update_entity`, `add_note`, `get_timeline`, `link_entities`, `get_related`, `emit_event`, `list_entity_types`

**Szybki start:**
```env
CRM_ADAPTER=minicrm
MINICRM_SYSTEM_ID=12345
MINICRM_API_KEY=your-key
```

```bash
docker compose --profile crm up -d
```

Dodaj `crm` do listy `tools:` agenta w `agents.yaml`, aby dać mu dostęp do CRM.

---

## jog.gov.hu MCP — Wyszukiwanie prawa węgierskiego

MCP jog.gov.hu (`mcps/jog-hu/`) udostępnia agentom AI węgierskie informacje prawne w dwóch trybach wdrożenia:

**Tryb Docker** (zawsze działa, bez Playwright):

| Narzędzie | Opis |
|---|---|
| `search_njt_laws(keywords)` | Wyszukiwanie słów kluczowych na njt.jog.gov.hu — zwraca pasujące tytuły ustaw i URL-e |
| `get_law_text(law_id, section)` | Pełny lub częściowy tekst ustawy z njt.hu (np. `"2012. évi I. törvény"`, sekcja `"69"`) |
| `list_recent_laws(category, days)` | Najnowsze ustawy z kanału RSS Magyar Közlöny |

**Tryb hosta** (wyszukiwanie oparte na AI, wymaga uruchomienia `host_server.py` na maszynie hosta):

| Narzędzie | Opis |
|---|---|
| `search_law(question)` | Pytanie w języku naturalnym → odpowiedź AI + cytowane odniesienia do ustaw (jog.gov.hu) |

reCAPTCHA v3 ocenia sesje przede wszystkim na podstawie **reputacji adresu IP**. Adresy IP kontenerów Docker oraz serwerów chmurowych/VPS są klasyfikowane jako zakresy datacenter i otrzymują niski wynik zaufania — niezależnie od poprawek odcisku palca przeglądarki. Maszyna domowa lub biurowa z **adresem IP sieci domowej** uzyskuje wystarczająco wysoki wynik, aby przejść weryfikację. Graficzny ekran **nie jest wymagany** — przeglądarka działa w trybie bezgłowym; środowisko graficzne nie ma znaczenia.

**Szybki start (narzędzia Docker — zawsze działa):**
```bash
docker compose --profile jog-hu up -d
```

**Uruchomienie serwera hosta (wyszukiwanie AI — wymagany domowy adres IP):**
```bash
# Działa na: domowym/biurowym komputerze stacjonarnym lub laptopie (Windows, macOS, Linux)
# NIE działa na: serwerach chmurowych/VPS (adresy IP datacenter blokowane przez reCAPTCHA)
# Graficzny ekran NIE jest wymagany — działa bezgłowo

pip install mcp fastmcp httpx playwright playwright-stealth
playwright install chromium

python3 mcps/jog-hu/host_server.py --background   # uruchom jako daemon, port 4312
python3 mcps/jog-hu/host_server.py --stop          # zatrzymaj daemon
```

**Dodaj do `mcps.yaml`:**
```yaml
- name: jog-hu
  url: http://jog-hu-mcp:4302/mcp/
  description: Hungarian legal search (njt.hu)

# Opcjonalnie — tylko jeśli host_server.py jest uruchomiony:
- name: jog-hu-host
  url: http://host.docker.internal:4312/mcp/
  description: Hungarian legal AI search (jog.gov.hu)
```

Dodaj `jog-hu` (i opcjonalnie `jog-hu-host`) do listy `tools:` agenta w `agents.yaml`.

---

## Współtworzenie

1. Sforkuj repozytorium i utwórz gałąź funkcji.
2. Postępuj zgodnie z konwencjami warstw i compose w `CLAUDE.md`.
3. Dodaj lub zaktualizuj odpowiedni blok testów w `tests.sh`.
4. Otwórz pull request z opisem dodawanej fazy lub funkcji.

---

## Licencja
