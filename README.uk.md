[English](README.md) | [Magyar](README.hu.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Русский](README.ru.md) | [Nederlands](README.nl.md) | [Polski](README.pl.md) | [Українська](README.uk.md) | [Svenska](README.sv.md) | [Italiano](README.it.md) | [日本語](README.ja.md) | [中文](README.zh.md) | [한국어](README.ko.md) | [Kiswahili](README.sw.md)

# QuorumAI

QuorumAI — це модульна система оркестрації мультиагентного ШІ, що працює на власному сервері та побудована на LangGraph. Вона повністю працює у Docker, підключається до всіх основних платформ обміну повідомленнями, підтримує голосову взаємодію, керування розумним будинком і симулює багаторольову ШІ-«компанію» з довгостроковою пам'яттю та автономним виконанням завдань.

![Python 3.11](https://img.shields.io/badge/Python-3.11-blue.svg) ![Docker](https://img.shields.io/badge/Docker-Compose-2496ED.svg)

---

<div align="center">
  <video src="https://github.com/user-attachments/assets/7bd072b6-75cd-4345-9fe0-fa2f3ee0566e" controls width="800"></video>

  <p><b><a href="https://license.quorumai.eu/portal/register">Почніть тут — зареєструйтеся на 30-денний безкоштовний пробний період »</a></b></p>
</div>

---

## Що таке QuorumAI?

QuorumAI перетворює один або кілька LLM на команду ШІ-агентів, яка вміє:

- Відповідати на запитання, читати новини і керувати пристроями розумного будинку — через мікрофон, Telegram, Matrix, Discord, Slack, Signal, WhatsApp, Viber або IRC.
- Делегувати роботу між спеціалізованими ролями (CEO, розробник, продажі) та підтримувати довгострокову пам'ять між сесіями за допомогою векторного пошуку Qdrant.
- Автономно виконувати завдання через планувальник heartbeat, запитувати підтвердження від людини за необхідності (HITL) та надавати кожну зовнішню можливість як MCP-сервер (Model Context Protocol).

Усе налаштовується у YAML. Для зміни моделі, додавання агентів або підключення нових інструментів не потрібно змінювати код.

---

## Швидке встановлення

### Один рядок (рекомендовано)

Bootstrap-встановлювач перевіряє наявність Python 3 та Docker, встановлює їх за потреби, а потім запускає інтерактивний встановлювач QuorumAI.

**Linux / macOS:**
```bash
curl -fsSL https://raw.githubusercontent.com/FulopJozsi/QuorumAI/main/install.sh | bash
```

**Windows (PowerShell — запустити від імені Адміністратора):**
```powershell
irm https://raw.githubusercontent.com/FulopJozsi/QuorumAI/main/install.ps1 | iex
```

Або завантажте `install.bat` / `install.ps1` з репозиторію та двічі клацніть.

> **Примітка:** На Linux bootstrap встановлює Docker Engine з офіційного репозиторію Docker (apt/dnf/yum залежно від дистрибутиву) та додає користувача до групи `docker`. Потрібно вийти з системи та увійти знову. На macOS та Windows встановлює Docker Desktop та пропонує запустити його перед продовженням.

---

### Python 3 та Docker вже встановлені?

Клонуйте репозиторій та запустіть інтерактивний встановлювач безпосередньо — pip і додаткові залежності не потрібні:

```bash
git clone https://github.com/FulopJozsi/QuorumAI.git
cd QuorumAI
python3 install.py
```

Встановлювач:
- Надає інтерактивний вибір модулів (оркестратор, мости, голос, GUI тощо).
- Записує `.env` з ваших відповідей, створює каталоги bind-mount `data/` та запускає `docker compose up -d`.
- Інтерфейс встановлювача доступний 16 мовами.

**Режим Satellite** — запуск мікрофону, мостів або MCP-серверів на окремій машині:
```bash
python3 install.py   # виберіть "Satellite" при запиті
```

---

## Швидкий старт

```bash
git clone https://github.com/FulopJozsi/QuorumAI.git
cd QuorumAI
python3 install.py
```

Перевірка роботи оркестратора:

```bash
curl http://localhost:8000/health
```

Надсилання тестового повідомлення:

```bash
curl -X POST http://localhost:8000/invoke \
  -H 'Content-Type: application/json' \
  -d '{"message": "Hello, introduce yourself."}'
```

Вебінтерфейс: `http://localhost:3000`

---

## Архітектура

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

Кожен шар знаходиться у власному каталозі з власним `compose.yml`. Кореневий `compose.yml` об'єднує всі шари через `include:` і профілі Docker Compose — ви запускаєте лише те, що потрібно.

---

## Функції

### Основна оркестрація

- **Середовище виконання LangGraph** — граф агентів скінченного автомата, нативне HITL-чекпоінтування, `AsyncPostgresSaver`.
- **FastAPI HTTP API** — `POST /invoke`, `GET /health`, стримінг, приймач вебхуків, ретрансляція push-сповіщень.
- **agents.yaml** — оголошуйте агентів у YAML: ім'я, роль, провайдер, модель, шлях до системного промпту, інструменти.
- **Гаряче перезавантаження** — `POST /agents/reload` перезавантажує `agents.yaml` без перезапуску контейнера.
- **Протокол інструментів MCP** — кожна зовнішня можливість є MCP-сервером; агенти виявляють інструменти автоматично.
- **Векторна пам'ять Qdrant** — гібридний семантичний + BM42 лексичний пошук, багатомовні E5-Large-ембедінги, колекції в розрізі агентів, косинусна дедуплікація, MMR-диверсифікований пошук.
- **Нічна консолідація пам'яті** — заплановане «завдання-сон» дистилює історію сесій PostgreSQL у довгострокові факти Qdrant; об'єднує прогресії, видаляє застарілі ефемерні записи; стан відстежується у PostgreSQL.
- **PostgreSQL** — чекпоінтер `AsyncPostgresSaver` + таблиці завдань і коментарів.
- **Граф знань** — FalkorDB (сумісний з Redis), Cypher-запити в розрізі користувачів, автоматичне вилучення сутностей.

### LLM-провайдери (на агента, налаштовується в agents.yaml)

| Локальні | Хмарні |
|---|---|
| Ollama (за замовчуванням, без ключа) | Anthropic Claude |
| llama.cpp | OpenAI |
| LM Studio | OpenRouter |
| vLLM | Google Gemini |
| Docker Model Runner | Grok (xAI) |
| Unsloth Studio | DeepSeek |
| | Mistral AI |
| | Together AI |
| | Fireworks AI |
| | Zhipu AI / Z.AI |
| | Eden AI (агрегатор) |
| | NVIDIA NIM (безкоштовний рівень доступний) |

API-ключ для початку роботи не потрібен — Ollama працює локально та безкоштовно.

**Пули провайдерів** — кілька однакових локальних серверів (наприклад, шість машин Ollama) можна об'єднати в іменований пул. Оркестратор розподіляє запити за алгоритмом least-connections; якщо всі члени пулу недоступні, управління передається звичайному fallback-ланцюгу. Налаштовується в `providers.yaml`, керується через вкладку Провайдери в GUI.

### Симуляція мультиагентної компанії

- Ролеві агенти: CEO, розробник, продажі та будь-яка користувацька роль.
- Агент-диспетчер автоматично скеровує вхідні запити до потрібного спеціаліста.
- Конвеєрні агенти: цикли планувальник → виконавець → рецензент із спільним станом.
- **Автономні (Deep) агенти** — встановіть `deep: true` для будь-якого агента або стадії конвеєра, щоб активувати вбудований ReAct-цикл LangGraph. Агент самостійно планує, виконує та ітерує — викликає інструменти до завершення завдання або досягнення опціонального ліміту викликів (`deep_max_steps`, 0 = без обмежень). Налаштовується на рівні агента та стадії; перемикач доступний у GUI Agent Builder.
- Бібліотека навичок: Markdown-файли навичок, ліниве завантаження на агента, маркетплейс спільноти для обміну.
- Спільний робочий простір: агенти можуть читати та записувати у спільну файлову область.
- **Інструменти адміністрування** — агенти з роллю `admin` можуть створювати та видаляти агентів, навички, MCP-сервери, cron-завдання та розклади heartbeat у реальному часі через інструменти `system-admin`. Кожна операція запису вимагає підтвердження HITL.

### Управління завданнями та автономність

- Канбан-дошка з підзавданнями та коментарями (на PostgreSQL).
- Планувальник heartbeat: агенти автоматично беруть очікуючі завдання (за замовчуванням кожні 5 хвилин).
- Автономне виконання з HITL-шлюзами підтвердження (Telegram `/approve`, кнопки GUI).
- Push-сповіщення: Telegram, Home Assistant `notify`, веб-пуш (VAPID). У задачах можна вказати поле `notify_channel`, щоб повідомлення про завершення завжди надходило до правильного містка незалежно від того, в якій сесії було створено задачу. Агенти можуть викликати `list_notify_channels()`, щоб дізнатися доступні канали під час виконання.

**Багатоденні завдання** — рекомендований шаблон для тривалої роботи, що охоплює години або дні:
1. Створіть завдання з назвою та описом (через чат, Telegram або канбан-дошку GUI).
2. Агент (або ви) викликає `set_subtasks`, щоб розбити його на іменовані кроки.
3. Кожен запуск heartbeat бере наступне очікуване підзавдання, виконує його і зупиняється — окремі LLM-сесії залишаються короткими та сфокусованими.
4. Прогрес, рішення та проміжні результати зберігаються як коментарі до завдання, щоб кожен наступний запуск мав повний контекст того, що відбулося раніше.
5. Коли всі підзавдання виконані, агент закриває завдання і надсилає сповіщення про завершення.

Цей шаблон працює без змін коду — він побудований на існуючих інструментах завдань (`set_subtasks`, `get_next_subtask`, `complete_subtask`), до яких має доступ будь-який агент з джерелом інструментів `tasks`.

### Нагляд безпеки (Квадрумвірат)

Необов'язковий пер-агентний шар, що перевіряє кожний ризиковий виклик інструменту перед виконанням. Вмикається прапорцем `guardian: true` в `agents.yaml`; агенти без цього прапорця не зачіпаються.

- **Guardian** — ізольований виклик LLM (без інструментів), що оцінює ім'я та аргументи інструменту і повертає: `NONE` (продовжити), `SOFT VETO: причина` (потрібне рішення людини) або `HARD VETO: причина` (негайне блокування).
- **Арбітр** — активується при SOFT VETO; генерує Markdown-аналітичний звіт і призупиняє граф через LangGraph `interrupt()`. Оператор схвалює або відхиляє через Telegram `/approve` або GUI — той самий потік, що й HITL.
- **Хроніст (Historian)** — завдання heartbeat, що читає аудит-журнал Guardian з пам'яті і записує структурований звіт у таблицю PostgreSQL `historian_reports`.
- **Класифікація ризиків** — MCP-сервери позначаються в `mcps.yaml` як `risk: low` або `risk: high`. Інструменти пам'яті, завдань і схвалення завжди виключені з перевірки.

```yaml
# agents.yaml
agents:
  - name: ceo
    guardian: true
    guardian_provider: anthropic        # необов'язково — успадковує провайдера агента якщо порожньо
    guardian_model: claude-haiku-4-5-20251001
    arbiter_provider: anthropic
    arbiter_model: claude-sonnet-4-6
```

```yaml
# mcps.yaml
servers:
  - name: playwright
    risk: high        # усі інструменти playwright потребують схвалення Guardian
  - name: hu-tools
    risk: low         # погода, новини — передаються без перевірки
```

Ендпоінт `/guardian/log` повертає живий аудит-журнал (останні 1 000 рішень).

### Автентифікація та мультиорендність

| Режим | Опис |
|---|---|
| `AUTH_MODE=none` | Відкритий — без автентифікації (за замовчуванням, для локального використання) |
| `AUTH_MODE=local` | Bearer-токен; користувачі задаються через `LOCAL_USERS=user1:pass1,...` |
| `AUTH_MODE=sso` | Keycloak OIDC/JWT або будь-який OIDC-провайдер (Auth0, Okta, Authelia, ...) |

**Ізоляція за користувачем.** У багатокористувацькому режимі пам'ять і граф
знань кожного користувача розділені: довготривала пам'ять потрапляє до його
власної колекції Qdrant, а граф — до власного `scope`. Читання бачить власні дані
та спільний шар, який курує адміністратор, але ніколи дані іншого користувача.
Нічне обслуговування також виконується **для кожного користувача окремо**.

### Спостережуваність

- Трейси конвеєра з логуванням токенів і вартості на кожен хід.
- Водоспадний вигляд у вкладці Моніторинг GUI.
- Автоматичне очищення трейсів контролюється параметром `TRACE_RETENTION_DAYS`.

### Приймач вебхуків

Приймає підписані вебхуки від: GitHub, Gitea, Drone CI, Grafana, n8n, Slack, ERPNext, Twenty CRM, Zammad, Tiledesk, Uptime Kuma, Wekan, Umami, Duplicati, BorgWarehouse.

### Резервне копіювання та відновлення

Всі дані середовища виконання зберігаються в `data/` як bind-монтування; вся конфігурація у YAML-файлах — без прихованого стану всередині контейнерів.

**Створення резервної копії** (включає `.env` + `data/`):

```bash
sudo python3 backup.py backup                    # інтерактивно, автоматична назва файлу
sudo python3 backup.py backup /srv/backup.tgz    # явний шлях виводу
```

**Відновлення**:

```bash
python3 backup.py restore /srv/backup.tgz           # відновити до поточного каталогу
python3 backup.py restore /srv/backup.tgz /opt/qai  # відновити до вказаного каталогу
```

На Linux / macOS запускати з `sudo` для збереження власників файлів. На Windows — без `sudo`.

---

## Мости

| Міст | Транспорт | Профіль Compose |
|---|---|---|
| Telegram | Bot API, async (python-telegram-bot) | `telegram` |
| Matrix | matrix-nio, на рівні кімнати | `matrix` |
| Discord | discord.py, слеш-команди | `discord` |
| IRC | irc3 asyncio, кілька каналів | `irc` |
| WhatsApp | Meta Cloud API webhook | `whatsapp` |
| Slack | slack-bolt Socket Mode | `slack` |
| Signal | signal-cli REST API polling | `signal` |
| Viber | FastAPI webhook, кнопки клавіатури | `viber` |

Кожен міст надає `/notify` (push-сповіщення від оркестратора) і `/health` (перевірка доступності), а також підтримує списки дозволів відправників і каналів. Telegram і GUI також підтримують HITL-потік `/approve`. Всі мости підтримують перемикання мови для кожного користувача за допомогою команди `/language`; налаштування зберігається у PostgreSQL та зберігається після перезапуску контейнерів.

---

## Голос

### Міст мікрофона (локальний мікрофон)

Профіль Compose: `mic`

- openWakeWord — налаштовуване слово активації (за замовчуванням: "Ok Szif").
- Wyoming Whisper — локальний STT, хмара не потрібна.
- Wyoming Piper — локальний TTS.
- Монтування сокета PulseAudio для Linux-десктопів.

**Примітки щодо платформ:**

- **Linux** — інсталятор визначає ваш UID і автоматично монтує правильний сокет PulseAudio (`/run/user/<uid>/pulse`).
- **macOS / Windows** — Docker Desktop не пробрасує аудіопристрої. Інсталятор записує конфігурацію PulseAudio TCP. Налаштуйте PulseAudio у режимі TCP перед запуском контейнера mic:
  - macOS: `brew install pulseaudio && pulseaudio --load=module-native-protocol-tcp --exit-idle-time=-1 --daemon`
  - Windows (WSL2): `sudo apt install pulseaudio && pulseaudio --load=module-native-protocol-tcp --exit-idle-time=-1 --start`
  - Windows (нативний): завантажте PulseAudio для Windows, розкоментуйте `module-native-protocol-tcp` у `default.pa`, дозвольте порт 4713 у брандмауері.

### Home Assistant Voice PE

Профіль Compose: `ha`

QuorumAI реєструється як агент розмови у Home Assistant. HA Assist обробляє виявлення слова активації, Whisper STT і Piper TTS на стороні HA; QuorumAI виконує міркування і виклики інструментів.

### Інструменти STT і TTS (доступні для агентів)

Профіль Compose: `stt-tts`

Надає Whisper і Piper як HTTP API, які агенти можуть викликати як інструменти `system-stt` і `system-tts`.

---

## Вебінтерфейс

Профіль Compose: `gui` — доступний за адресою `http://localhost:3000`

Побудований на React, Vite і Tailwind CSS.

| Вкладка | Опис |
|---|---|
| Чат | Надсилання повідомлень будь-якому агенту; перегляд відповідей у режимі стримінгу |
| Конструктор агентів | Візуальна діаграма компанії; створення та редагування агентів і їхніх ролей |
| Редактор навичок | Створення та керування Markdown-файлами навичок |
| Завдання | Канбан-дошка; дерево підзавдань; коментарі; кнопки підтвердження |
| Провайдери | Статус провайдерів у реальному часі та список доступних моделей |
| Heartbeat | Стан планувальника; час наступних запусків; ручний запуск |
| Спостережуваність | Трейси конвеєра; водоспадний вигляд токенів і вартості |

- 16 мов інтерфейсу, 14 тем.
- Кнопки підтвердження HITL інтегровані у вкладках Чат і Завдання.

---

## Деталі встановлення

### Передумови

- Docker Engine 24+ і Docker Compose v2.
- Python 3.8+ для `install.py` — pip або virtualenv не потрібні.
- Для локальних моделей: Ollama, запущений на хості на порті 11434.

### Створення спільної мережі (один раз на хост)

```bash
docker network create quorum-net
```

### Вибір профілів

Встановіть профілі у `.env`, щоб звичайна команда `docker compose up -d` працювала:

```env
COMPOSE_PROFILES=orchestrator,memory,mcp,postgres,telegram,gui
```

Або передайте їх явно:

```bash
docker compose --profile orchestrator --profile memory --profile gui up -d
```

Доступні профілі: `orchestrator`, `memory`, `mcp`, `postgres`, `telegram`, `ha`, `mic`, `gui`, `stt-tts`, `mcp-manager`, `playwright`, `joplin`, `auth`, `email`, `matrix`, `discord`, `irc`, `whatsapp`, `slack`, `signal`, `viber`, `graph`

### Структура каталогу даних

```
data/
  qdrant/        # Вектори Qdrant
  postgres/      # Дані PostgreSQL
  workspace/     # Файловий робочий простір на агента
  whisper/       # Кеш моделі Whisper
  piper/         # Голосові файли Piper
  ...
```

Усе під `data/` ігнорується git. Резервна копія цього каталогу зберігає весь постійний стан.

---

## Конфігурація

Скопіюйте `.env.example` у `.env` і заповніть те, що потрібно. Файл `.env.example` містить вбудовану документацію для кожного ключа.

### Найважливіші ключі

| Ключ | За замовч. | Опис |
|---|---|---|
| `COMPOSE_PROFILES` | — | Профілі для запуску, через кому |
| `AUTH_MODE` | `none` | `none` / `local` / `sso` |
| `ORCHESTRATOR_PORT` | `8000` | Порт FastAPI оркестратора |
| `GUI_PORT` | `3000` | Порт GUI |
| `QDRANT_HTTP_PORT` | `6333` | Порт REST Qdrant |
| `POSTGRES_PORT` | `5433` | Порт PostgreSQL |
| `POSTGRES_PASSWORD` | `changeme` | Пароль PostgreSQL — змініть! |
| `TRACE_RETENTION_DAYS` | `14` | Автовидалення трейсів старших N днів |
| `ANTHROPIC_API_KEY` | — | Потрібен для провайдера Anthropic |
| `OPENROUTER_API_KEY` | — | Потрібен для OpenRouter |
| `OPENAI_API_KEY` | — | Потрібен для OpenAI |
| `GOOGLE_API_KEY` | — | Потрібен для Google Gemini |
| `TELEGRAM_BOT_TOKEN` | — | Потрібен для моста Telegram |
| `TELEGRAM_CHAT_ID` | — | ID чату Telegram для приймання повідомлень |
| `NOTIFY_TELEGRAM_CHAT_ID` | — | ID чату для сповіщень про завершення задач (збігається з `TELEGRAM_CHAT_ID`, якщо однаковий) |
| `MATRIX_HOMESERVER` | — | URL Matrix-сервера |
| `MATRIX_ACCESS_TOKEN` | — | Токен доступу Matrix-бота |
| `DISCORD_BOT_TOKEN` | — | Потрібен для моста Discord |
| `SLACK_BOT_TOKEN` | — | Потрібен для моста Slack |
| `SLACK_APP_TOKEN` | — | Потрібен для Slack Socket Mode |
| `SIGNAL_PHONE` | — | Номер телефону для моста Signal |
| `VIBER_AUTH_TOKEN` | — | Потрібен для моста Viber |
| `HA_URL` | `http://homeassistant:8123` | Базова URL Home Assistant |
| `HA_TOKEN` | — | Довгоживучий токен доступу HA |
| `IMAP_HOST` | — | IMAP-сервер для Email MCP |
| `SMTP_HOST` | — | SMTP-сервер для Email MCP |
| `FALKORDB_URL` | — | Встановіть для активації графу знань |
| `VAPID_EMAIL` | — | Потрібен для веб-пуш-сповіщень |
| `VAPID_PRIVATE_KEY` | — | Автоматично генерується інсталятором (потрібен пакет Python `cryptography`); інакше: `docker compose exec orchestrator python3 webpush.py` |
| `VAPID_PUBLIC_KEY` | — | Генерується разом з приватним ключем |
| `HU_TOOLS_PORT` | `4300` | Порт MCP hu-tools |
| `WHISPER_URL` | `http://whisper-http:8000` | URL сервісу STT |
| `PIPER_URL` | `http://piper-http:5000` | URL сервісу TTS |
| `ORCHESTRATOR_API_KEY` | — | Автоматично генерується інсталятором; токен сервіс-до-сервісу для мостів (обов'язковий при `AUTH_MODE=local/sso`) |
| `CONVERSATION_API_KEY` | — | Автоматично генерується інсталятором; захищає HA-ендпоінт `/conversation` (порожній = відкритий) |

Налаштування агентів: `orchestrator/agents.yaml`. Повна документація: `.env.example`.

---

## Галузеві пакети

Готові вертикальні пакети для конкретних галузей. Кожен пакет містить файли навичок, рекомендовані конфігурації агентів і посилання на MCP. Встановлюються через `install.py` або вручну.

| Пакет | Цільова аудиторія | Основні навички |
|---|---|---|
| `legal` | Юридичні фірми | Пошук документів, аналіз контрактів, пошук за угорським правом |
| `devops` | IT/DevOps компанії | Тріаж інцидентів, пошук runbook, AIOps з HITL |
| `agency` | Маркетингові та PR-агентства | Статус проєкту, кваліфікація лідів, аналіз брифів, звітність для клієнтів |

**Ручне встановлення:**
```bash
cp industry-packs/legal/skills/*.md data/skills/
cat industry-packs/legal/agents.yaml
```

**Через інсталятор:** повторно запустіть `python3 install.py` → Змінити → вибрати галузевий пакет.

Створіть власний пакет, скопіювавши `industry-packs/_template/` і заповнивши `pack.yaml`.

---

## CRM-інтеграція

CRM MCP (`mcps/crm/`) надає єдиний інтерфейс для кількох CRM-систем через змінну адаптерну архітектуру. Агенти використовують однакові інструменти незалежно від бекенду.

**Підтримувані адаптери:**

| Адаптер | Система | Тип |
|---|---|---|
| `minicrm` | MiniCRM (лідер угорського ринку) | Повний |
| `hubspot` | HubSpot CRM | Повний |
| `pipedrive` | Pipedrive | Повний |
| `billingo` | Billingo (виставлення рахунків) | Лише читання |
| `szamlazzhu` | Számlázz.hu (виставлення рахунків) | Лише читання |
| `salesautopilot` | SalesAutopilot (маркетингова автоматизація HU) | Повний |

**Доступні інструменти:** `search_entities`, `get_entity`, `create_entity`, `update_entity`, `add_note`, `get_timeline`, `link_entities`, `get_related`, `emit_event`, `list_entity_types`

**Швидкий старт:**
```env
CRM_ADAPTER=minicrm
MINICRM_SYSTEM_ID=12345
MINICRM_API_KEY=your-key
```

```bash
docker compose --profile crm up -d
```

Додайте `crm` до списку `tools:` агента в `agents.yaml`, щоб надати йому доступ до CRM.

---

## jog.gov.hu MCP — Пошук угорського законодавства

MCP jog.gov.hu (`mcps/jog-hu/`) надає угорську правову інформацію ШІ-агентам у двох режимах розгортання:

**Режим Docker** (завжди працює, Playwright не потрібен):

| Інструмент | Опис |
|---|---|
| `search_njt_laws(keywords)` | Пошук за ключовими словами на njt.jog.gov.hu — повертає заголовки та URL відповідних законів |
| `get_law_text(law_id, section)` | Повний або частковий текст закону з njt.hu (наприклад, `"2012. évi I. törvény"`, розділ `"69"`) |
| `list_recent_laws(category, days)` | Нещодавні закони з RSS-стрічки Magyar Közlöny |

**Режим хосту** (ШІ-пошук, потрібен запущений `host_server.py` на хост-машині):

| Інструмент | Опис |
|---|---|
| `search_law(question)` | Запитання природною мовою → відповідь ШІ + цитовані посилання на закони (jog.gov.hu) |

reCAPTCHA v3 оцінює сесії насамперед за **репутацією IP-адреси**. IP-адреси Docker-контейнерів, хмарних і VPS-серверів класифікуються як діапазони дата-центрів і отримують низький рівень довіри — незалежно від налаштувань відбитку браузера. Домашня або офісна машина на **домашньому IP** отримує достатньо високий бал для проходження перевірки. Графічний дисплей **не потрібен** — браузер працює у безголовому режимі; наявність дисплея не має значення.

**Швидкий старт (інструменти Docker — завжди працюють):**
```bash
docker compose --profile jog-hu up -d
```

**Запуск хостового сервера (ШІ-пошук — необхідний домашній IP):**
```bash
# Працює на: домашньому/офісному десктопі або ноутбуці (Windows, macOS, Linux)
# НЕ працює на: хмарних/VPS-серверах (IP дата-центрів заблоковані reCAPTCHA)
# Графічний дисплей НЕ потрібен — браузер запускається у безголовому режимі

pip install mcp fastmcp httpx playwright playwright-stealth
playwright install chromium

python3 mcps/jog-hu/host_server.py --background   # запустити демон, порт 4312
python3 mcps/jog-hu/host_server.py --stop          # зупинити демон
```

**Додайте до `mcps.yaml`:**
```yaml
- name: jog-hu
  url: http://jog-hu-mcp:4302/mcp/
  description: Hungarian legal search (njt.hu)

# Опціонально — лише якщо запущений host_server.py:
- name: jog-hu-host
  url: http://host.docker.internal:4312/mcp/
  description: Hungarian legal AI search (jog.gov.hu)
```

Додайте `jog-hu` (і опціонально `jog-hu-host`) до списку `tools:` агента в `agents.yaml`.
