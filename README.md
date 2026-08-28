[English](README.md) | [Magyar](README.hu.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Русский](README.ru.md) | [Nederlands](README.nl.md) | [Polski](README.pl.md) | [Українська](README.uk.md) | [Svenska](README.sv.md) | [Italiano](README.it.md) | [日本語](README.ja.md) | [中文](README.zh.md) | [한국어](README.ko.md) | [Kiswahili](README.sw.md)

# QuorumAI

QuorumAI is a modular, self-hosted multi-agent AI orchestration system built on LangGraph. It runs entirely in Docker, connects to every major messaging platform, supports voice interaction, smart-home control, and simulates a multi-role AI "company" with long-term memory and autonomous task execution.

![Python 3.11](https://img.shields.io/badge/Python-3.11-blue.svg) ![Docker](https://img.shields.io/badge/Docker-Compose-2496ED.svg)

---

## What is QuorumAI

QuorumAI turns one or more LLMs into a team of AI agents that can hold conversations, use tools, remember what happened, and act autonomously — self-hosted end to end in Docker, with no lock-in to a single AI vendor. Agents, skills, MCP servers, and schedules all live in YAML config underneath, but nothing has to be hand-edited: the GUI's Agent Builder, Skill Editor, and MCP Manager let you create and change all of it at runtime, with no code changes and no restart.

**Talk to it from anywhere.** Agents are reachable from a local microphone (openWakeWord wake-word detection, local Whisper STT, local Piper TTS, with natural pause detection and mid-reply barge-in), from Home Assistant Voice PE, or from eight chat platforms — Telegram, Matrix, Discord, IRC, WhatsApp, Slack, Signal, Viber — each with the same human-approval (HITL) flow, per-user language switching, and a 33-language UI. A custom React/Vite/Tailwind GUI covers everything outside of chat: an Agent Builder, a Company Diagram with a live org-chart, a Skill Editor with its own marketplace, a Kanban Task board, a Heartbeat scheduler view with cron job management, a Knowledge base, a Voice Studio, an MCP Manager, and Monitoring/Settings screens (providers, observability traces, knowledge graph, AI Act compliance status, license tier). An OpenAI-compatible `POST /v1/chat/completions` endpoint also lets any existing OpenAI client talk to a QuorumAI agent directly.

**Any LLM, per agent.** Each agent's provider and model is set independently in `agents.yaml`. Local runtimes (Ollama, llama.cpp, LM Studio, vLLM, Docker Model Runner, Unsloth Studio) need no API key at all; Anthropic, OpenAI, Google Gemini, OpenRouter, Grok, DeepSeek, Mistral, Together AI, Fireworks AI, Zhipu/Z.AI, Eden AI, and NVIDIA NIM are supported as swappable cloud providers. Provider pools load-balance across identical local servers, and a configurable fallback chain with cooldown keeps a conversation alive if one provider fails.

**A company of agents, not just a chatbot.** Agents can take on roles (CEO, developer, sales, …), delegate to each other through a dispatcher agent, run planner → executor → reviewer pipelines, or — with `deep: true` — act fully autonomously in a ReAct loop, calling tools repeatedly until a task is done. They share a Markdown skill library (with a community marketplace) and a common file workspace. Agents flagged as `admin` can create or delete other agents, skills, MCP servers, and schedules at runtime, always behind a human-approval gate.

**Memory and knowledge.** Long-term memory lives in Qdrant — hybrid semantic + lexical (BM42) search, deduplicated, and nightly consolidated from session history into durable facts. A FalkorDB knowledge graph tracks entities and relationships per user so agents know who they're talking to. A knowledge base ingests PDFs, DOCX, spreadsheets, and more for retrieval by any agent.

**Autonomy with oversight.** A Kanban task board with subtasks and comments lets work span days: each heartbeat run picks up the next subtask, completes it, and leaves progress as a comment for the next run. An optional Guardian/Arbiter/Historian layer ("Quadrumviratus") screens high-risk tool calls, vetoing, escalating to a human, or logging the decision. A separate AI Act mode adds full tool-call audit logging, a tamper-evident hash-chained log, and automatic PII masking for regulatory contexts.

**Tools, all via MCP.** Every external capability is exposed as an MCP (Model Context Protocol) server that agents discover automatically: Hungarian news/weather/web search, global weather and news, Hungarian legal search (njt.hu), a CRM with adapters for MiniCRM, HubSpot, Pipedrive, Billingo, Számlázz.hu, SalesAutopilot, and Twenty, email (IMAP/SMTP), Google Workspace (Gmail, Drive, Calendar, Docs, Sheets, Slides, Chat), Jira/Confluence, Home Assistant device control, Grafana, Uptime Kuma, remote bash/Python execution, browser automation (Playwright), Joplin notes, AI video generation (HyperFrames), and an MCP Manager for installing further servers from marketplaces at runtime.

**Ready-made verticals, one installer.** Industry packs (legal, DevOps, marketing agency) bundle skills, agents, and MCP wiring for a vertical out of the box. Everything installs through one interactive `install.py` (or a one-line bootstrap script), which also handles license tiers (Personal through Enterprise, all with a 30-day trial), authentication mode (none / local / SSO via Keycloak), and full backup/restore of persistent state.

---

## Quick Install

### One-liner (recommended)

The bootstrap installer checks for Python 3 and Docker, installs them if missing, then runs the interactive QuorumAI installer.

**Linux / macOS:**
```bash
curl -fsSL https://raw.githubusercontent.com/fulopjozsef86/QuorumAI/main/install.sh | bash
```

**Windows (PowerShell — run as Administrator):**
```powershell
irm https://raw.githubusercontent.com/fulopjozsef86/QuorumAI/main/install.ps1 | iex
```

Or download `install.bat` / `install.ps1` from the repo and double-click.

> **Note:** On Linux the bootstrap installs Docker Engine from the official Docker repository (apt/dnf/yum depending on distro) and adds your user to the `docker` group. A log-out/log-in is required afterwards. On macOS and Windows it installs Docker Desktop and prompts you to start it before continuing.

---

### Already have Python 3 and Docker?

Clone and run the interactive installer directly — no pip or extra dependencies required:

```bash
git clone https://github.com/fulopjozsef86/QuorumAI.git
cd QuorumAI
python3 install.py
```

The installer:
- Presents an interactive module selector (orchestrator, bridges, voice, GUI, and more).
- Writes `.env` from your answers, creates `data/` bind-mount directories, and runs `docker compose up -d`.
- Supports 33 languages in the installer UI itself.

**Satellite mode** — run mic, bridges, or MCP servers on a separate machine that connects to a remote QuorumAI orchestrator:

```bash
python3 install.py   # choose "Satellite" when prompted
```

---

## Quick Start (manual)

```bash
git clone https://github.com/your-org/QuorumAI.git
cd QuorumAI

# Create the shared Docker network (once per host):
docker network create quorum-net

cp .env.example .env
# Edit .env — set COMPOSE_PROFILES and any API keys you need

docker compose up -d
```

Verify the orchestrator is running:

```bash
curl http://localhost:8000/health
```

Send a test message:

```bash
curl -X POST http://localhost:8000/invoke \
  -H 'Content-Type: application/json' \
  -d '{"message": "Hello, introduce yourself."}'
```

Open the GUI at `http://localhost:3000`.

---

## Architecture

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

Each layer lives in its own directory with its own `compose.yml`. The root `compose.yml` aggregates all layers via `include:` and Docker Compose profiles — you only start what you need.

---

## Features

### Core orchestration

- **LangGraph runtime** — state-machine agent graph, native HITL checkpointing, `AsyncPostgresSaver`.
- **FastAPI HTTP API** — `POST /invoke`, `GET /health`, streaming, webhook receiver, push notification relay.
- **agents.yaml** — declare agents in YAML: name, role, provider, model, system prompt path, tools.
- **Hot reload** — `POST /agents/reload` reloads `agents.yaml` without restarting the container.
- **MCP tool protocol** — every external capability is an MCP server; agents discover tools automatically.
- **Qdrant vector memory** — hybrid semantic + BM42 lexical search, multilingual-e5-large embeddings, agent-scoped collections, cosine dedup, MMR-diversified recall.
- **Nightly memory consolidation** — scheduled dream job distills PostgreSQL session history into long-term Qdrant facts; merges progressions, removes stale ephemeral entries; state tracked in PostgreSQL.
- **PostgreSQL** — LangGraph `AsyncPostgresSaver` checkpointer + tasks and comments tables.
- **Knowledge Graph** — FalkorDB (Redis-compatible), user-scoped Cypher queries. Entities and relationships are extracted automatically at the end of each turn, or written explicitly by an agent via `graph_remember_entity`/`graph_remember_relation` tools; graph context is auto-injected into the system prompt (`memory_graph: true` by default) and visualized in the GUI Monitoring tab.
- **OpenAI-compatible API** — `POST /v1/chat/completions` + `GET /v1/models` (the `model` field selects the agent by name); Bearer auth via `OPENAI_COMPAT_API_KEY`, streaming (SSE) supported. Lets any existing OpenAI client or SDK talk to a QuorumAI agent without changes.

### LLM providers (per-agent, configured in agents.yaml)

| Local | Cloud |
|---|---|
| Ollama (default, no key needed) | Anthropic Claude |
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
| | NVIDIA NIM (free tier available) |

No API key is required to get started — Ollama runs locally at no cost.

**Provider pools** — multiple identical local servers (e.g. six Ollama machines) can be grouped into a named pool. The orchestrator distributes requests using least-connections load balancing; if all pool members fail, it falls through to the regular fallback chain. Configured in `providers.yaml` and manageable from the GUI Providers tab.

### Multi-agent company simulation

- Role-based agents: CEO, developer, sales agent, and any custom role.
- Dispatcher agent routes incoming requests to the right specialist automatically.
- Pipeline agents: planner → executor → reviewer loops with shared state.
- **Autonomous (Deep) agents** — set `deep: true` on any agent or pipeline stage to enable the built-in LangGraph ReAct loop. The agent plans, executes, and iterates autonomously — calling tools repeatedly until the task is done or the optional tool-call limit is reached (`deep_max_steps`, 0 = unlimited). Configurable per-agent and per-pipeline-stage; toggle available in the GUI Agent Builder.
- **Company Diagram** — a live, auto-laid-out org chart (React Flow + dagre) showing dispatcher → subordinate relationships as a DAG (an agent can report to more than one parent), with zoom, pan, and a minimap.
- **Skill library** — Markdown skill files, lazy-loaded per agent. A Skill Marketplace lets you browse, search, and install skills from 6 sources, including recursive GitHub-URL import; admin agents can also search and install skills themselves at runtime via `search_skill_marketplace`/`install_skill_from_marketplace` tools, HITL-gated.
- Shared workspace: agents can read and write a shared file area.
- **Admin tools** — agents with the `admin` role can create and delete agents, skills, MCP servers, cron jobs, and heartbeat schedules at runtime via `system-admin` tools. Every write action requires HITL approval before execution.

### Task management and autonomy

- Kanban task board with subtasks and comments (PostgreSQL-backed).
- Heartbeat scheduler: agents pick up pending tasks automatically (every 5 minutes by default). Heartbeat jobs (cron schedules) can be created, edited, and deleted via REST API or the GUI Heartbeat tab — no YAML editing required.
- Autonomous task execution with HITL approval gates (Telegram `/approve`, GUI buttons).
- Push notifications: Telegram, Home Assistant `notify`, web push (VAPID). Tasks can specify a `notify_channel` field so the completion message always goes to the right bridge regardless of which session created the task. Agents can call `list_notify_channels()` to discover available channels at runtime.

**Multi-day tasks** — the recommended pattern for long-running work that spans hours or days:
1. Create a task with a title and description (via chat, Telegram, or the GUI Kanban board).
2. The agent (or you) calls `set_subtasks` to break it into named steps.
3. Each heartbeat run picks up the next pending subtask, completes it, and stops — keeping individual LLM sessions short and focused.
4. Progress, decisions, and intermediate results are stored as task comments so every subsequent run has full context of what happened before.
5. When all subtasks are done the agent closes the task and sends a completion notification.

This pattern works without any code changes — it is built on the existing task tools (`set_subtasks`, `get_next_subtask`, `complete_subtask`) that any agent with the `tasks` tool source already has access to.

### Safety supervision (Quadrumviratus)

An optional per-agent layer that screens every high-risk tool call before it runs. Enabled with `guardian: true` in `agents.yaml`; agents without the flag are unaffected.

- **Guardian** — an isolated LLM call (no tools bound) that evaluates the tool name and arguments and returns `NONE` (proceed), `SOFT VETO: reason` (escalate to human), or `HARD VETO: reason` (block immediately).
- **Arbiter** — activated on SOFT VETO; generates a Markdown analysis report and suspends the graph via LangGraph `interrupt()`. The operator approves or rejects via Telegram `/approve` or the GUI — same flow as HITL.
- **Historian** — a heartbeat job that reads the in-memory Guardian audit log and writes a structured report to the `historian_reports` PostgreSQL table on a configurable schedule.
- **Risk classification** — MCP servers are tagged `risk: low` or `risk: high` in `mcps.yaml`. Memory, task, and approval tools are always excluded from screening regardless of risk level.

```yaml
# agents.yaml
agents:
  - name: ceo
    guardian: true
    guardian_provider: anthropic        # optional — inherits agent provider if empty
    guardian_model: claude-haiku-4-5-20251001
    arbiter_provider: anthropic
    arbiter_model: claude-sonnet-4-6
```

```yaml
# mcps.yaml
servers:
  - name: playwright
    risk: high        # all playwright tools require Guardian approval
  - name: hu-tools
    risk: low         # weather, news — passed through without screening
```

The `/guardian/log` endpoint returns the live audit log (last 1 000 decisions).

### AI Act compliance mode

An independent traceability/audit layer aimed at EU AI Act requirements — separate from Quadrumviratus above, and usable without it (it does not require the Guardian LLM screening call).

- **Full tool-call logging** — every tool call's input and output is recorded in the `tool_events` table; configuration changes are recorded in `config_audit_log`.
- **`ai_act_mode`** — adds a human-approval (HITL) gate to every tool call, independent of Guardian screening.
- **Tamper-evident audit chain** — `audit_chain_log` hash-chains each entry to the previous one so retroactive tampering is detectable; an optional RFC 3161 timestamp authority (TSA) anchor adds an external, verifiable time proof.
- **PII masking** — Presidio-based automatic masking of personal data (with Hungarian-language support) before it is written to the log.
- **Retention** — audit data is cleaned up automatically after 6 months.
- **GUI** — the Settings → AI Act tab shows chain status, lets you anchor and verify the chain, and export records.

### Auth and multi-tenancy

| Mode | Description |
|---|---|
| `AUTH_MODE=none` | Open — no authentication (default, suitable for local use) |
| `AUTH_MODE=local` | Bearer token; users defined in `LOCAL_USERS=user1:pass1,...` |
| `AUTH_MODE=sso` | Keycloak OIDC/JWT, or any OIDC provider (Auth0, Okta, Authelia, …) |

**Per-user isolation.** In multi-user mode each user's memory and knowledge
graph are separated: long-term memory lands in that user's own Qdrant collection
and the graph in their own `scope` — a read sees the user's own data plus the
admin-curated shared layer, never another user's. Nightly memory maintenance also
runs **per user**, inside that user's own storage.

### Observability

- Pipeline traces with per-turn token and cost logging.
- Waterfall view in the GUI Monitoring tab.
- Automatic trace cleanup controlled by `TRACE_RETENTION_DAYS`.

### Webhook receiver

Accepts signed webhooks from: GitHub, Gitea, Drone CI, Grafana, n8n, Slack, ERPNext, Twenty CRM, Zammad, Tiledesk, Uptime Kuma, Wekan, Umami, Duplicati, BorgWarehouse.

### Backup and config persistence

All runtime data lives under `data/` as bind mounts; all config in YAML files — nothing hidden inside containers.

**Create a backup** (includes `.env` + `data/`):

```bash
sudo python3 backup.py backup                 # interactive, auto-named file
sudo python3 backup.py backup /srv/backup.tgz # explicit output path
```

**Restore**:

```bash
python3 backup.py restore /srv/backup.tgz          # restore to current dir
python3 backup.py restore /srv/backup.tgz /opt/qai # restore to specific dir
```

On Linux / macOS run with `sudo` to preserve file ownership. On Windows run normally.

---

## Bridges

| Bridge | Transport | Compose profile |
|---|---|---|
| Telegram | Bot API, async (python-telegram-bot) | `telegram` |
| Matrix | matrix-nio, room-level | `matrix` |
| Discord | discord.py, slash commands | `discord` |
| IRC | irc3 asyncio, multi-channel | `irc` |
| WhatsApp | Meta Cloud API webhook | `whatsapp` |
| Slack | slack-bolt Socket Mode | `slack` |
| Signal | signal-cli REST API polling | `signal` |
| Viber | FastAPI webhook, keyboard buttons | `viber` |

Every bridge exposes `/notify` (for push notifications from the orchestrator) and `/health` (liveness), and supports allowlists for senders and channels. Telegram and the GUI also support the HITL `/approve` flow. All bridges support per-user language switching via the `/language` command; the preference is stored in PostgreSQL and survives container restarts.

---

## Voice

### Mic bridge (local microphone)

Compose profile: `mic`

- openWakeWord — configurable wake word (default: "Ok Szif").
- Silero VAD — natural pause detection (800ms+ of silence marks the end of a sentence) instead of a fixed recording window.
- Wyoming Whisper — local STT, no cloud required.
- Wyoming Piper — local TTS, streamed sentence-by-sentence (SSE) as the reply is generated.
- Barge-in — you can interrupt the assistant's spoken reply mid-sentence by speaking again, or stop it entirely with "Stop".
- PulseAudio socket mount for Linux desktops.

**Platform notes:**

- **Linux** — the installer detects your UID and mounts the correct PulseAudio socket (`/run/user/<uid>/pulse`) automatically.
- **macOS / Windows** — Docker Desktop does not pass through audio devices. The installer writes a PulseAudio TCP config instead. Set up PulseAudio in TCP mode before starting the mic container:
  - macOS: `brew install pulseaudio && pulseaudio --load=module-native-protocol-tcp --exit-idle-time=-1 --daemon`
  - Windows (WSL2): `sudo apt install pulseaudio && pulseaudio --load=module-native-protocol-tcp --exit-idle-time=-1 --start`
  - Windows (native): download PulseAudio for Windows, uncomment `module-native-protocol-tcp` in `default.pa`, allow port 4713 in the firewall.

### Home Assistant Voice PE

Compose profile: `ha`

QuorumAI registers as a conversation agent inside Home Assistant. HA Assist handles wake-word detection, Whisper STT, and Piper TTS on the HA side; QuorumAI handles reasoning and tool calls.

### STT and TTS tools (agent-callable)

Compose profile: `stt-tts`

Exposes Whisper and Piper as HTTP APIs that agents can call as `system-stt` and `system-tts` tools.

### OmniVoice TTS (voice cloning)

Compose profile: `stt-tts`

A PyTorch-based neural TTS service (`POST /synthesize`, `/clone`, `/voices`) exposed through the orchestrator's `/tts/*` proxy. Ships with 8 built-in Hungarian voices and can clone a new voice from an uploaded audio sample. Agents can call it as the `tts_speak_omnivoice` tool; the GUI Chat tab can also read replies aloud with it (🔊 button, switchable between Piper and OmniVoice backends, adjustable voice and speed, auto-stream sentence-by-sentence). The **Voice Studio** ("Hang Stúdió") GUI tab is the dedicated place to manage voices and try synthesis/cloning.

---

## GUI

Compose profile: `gui` — available at `http://localhost:3000`

Built with React, Vite, and Tailwind CSS.

| Tab | Description |
|---|---|
| Chat | Send messages to any agent; token-by-token streamed responses with a live thinking view and tool-call indicators |
| Tasks | Kanban board; subtask tree; comments; approval buttons |
| Heartbeat | Scheduler state; next run times; manual trigger; create/edit/delete cron jobs |
| Agent Builder | Create and edit agents: provider, model, tools, prompts, Guardian, autonomous (deep) mode |
| Company Diagram | Live company org chart — dispatcher → subordinates as an auto-laid-out DAG, multi-parent nodes, zoom/pan, minimap |
| Skill Editor | Markdown skill editor with toolbar and live preview; Skill Marketplace (browse/search/install from 6 sources, incl. GitHub-URL import) |
| Monitoring | Live state view; observability trace waterfall (token/cost per turn); knowledge graph visualization |
| Knowledge | Upload and manage knowledge-base documents (PDF, DOCX, spreadsheets, …) for retrieval by any agent |
| Voice Studio (Hang Stúdió) | OmniVoice text-to-speech: synthesize, clone a voice from an audio sample, manage the 8 built-in voices |
| MCP Manager | Install/remove MCP servers from marketplaces at runtime; manage per-agent tool wiring |
| Settings | Providers, push notifications, webhooks, Home Assistant, OpenAI-compatible API key, users/SSO, AI Act compliance status, license tier |

- 33 UI languages, 14 themes.
- HITL approval buttons integrated in Chat and Tasks tabs.

---

## Installation Details

### Prerequisites

- Docker Engine 24+ and Docker Compose v2.
- Python 3.8+ for `install.py` — no pip or virtualenv required.
- For local models: Ollama running on the host at port 11434.

### Create the shared network (once per host)

```bash
docker network create quorum-net
```

### Selecting profiles

Set profiles in `.env` so plain `docker compose up -d` works:

```env
COMPOSE_PROFILES=orchestrator,memory,mcp,postgres,telegram,gui
```

Or pass them explicitly:

```bash
docker compose --profile orchestrator --profile memory --profile gui up -d
```

Available profiles: `orchestrator`, `memory`, `mcp`, `postgres`, `telegram`, `ha`, `mic`, `gui`, `stt-tts`, `mcp-manager`, `playwright`, `joplin`, `auth`, `email`, `matrix`, `discord`, `irc`, `whatsapp`, `slack`, `signal`, `viber`, `graph`

### Rebuilding after source changes

```bash
# Rebuild only the changed service:
docker compose build orchestrator

# Restart without touching other containers:
docker compose up -d --no-deps orchestrator
```

### Data directory layout

```
data/
  qdrant/        # Qdrant vectors
  postgres/      # PostgreSQL data
  workspace/     # per-agent file workspace
  whisper/       # Whisper model cache
  piper/         # Piper voice files
  ...
```

Everything under `data/` is gitignored. Backing up this directory preserves all persistent state.

### Unattended installation (Ansible / CI)

`install.py` is normally interactive, but every prompt can be pre-answered with an environment variable, so a freshly provisioned VM can be installed with zero interaction (Ansible `command`/`shell` module, cloud-init, CI). When stdin is not a TTY (always true under Ansible), the installer never blocks — any prompt without a matching environment variable simply falls back to its normal default instead of waiting for input.

Supported override variables:

| Variable | Effect |
|---|---|
| `QUORUM_LANG` | Language code (e.g. `en`, `hu`) — skips the language menu. |
| `QUORUM_MODE` | `full` or `satellite` — skips the install-mode menu. |
| `QUORUM_INSTALL_DIR` | Target directory — skips the install-dir prompt. |
| `QUORUM_MODULES` | Comma-separated module ids to install — skips the module checkbox entirely. See the full id list below. |
| `QUORUM_LICENSE_KEY` | The mandatory license key (free 30-day trial: https://license.quorumai.eu). |
| `QUORUM_INDUSTRY_PACK` | Pack id (`agency`, `devops`, `legal`) or `none`. |
| `QUORUM_ORCHESTRATOR_URL` | Satellite mode only — the remote orchestrator URL. |
| Any other `.env` key (e.g. `POSTGRES_PASSWORD`, `TELEGRAM_BOT_TOKEN`, `ANTHROPIC_API_KEY`, `ORCHESTRATOR_API_KEY`, …) | Exporting a variable with the **exact same name** it would have in `.env` pre-fills that prompt — this works for every module's env vars and every LLM provider key, not just the ones listed above. |

Module ids for `QUORUM_MODULES`: `orchestrator`, `memory`, `mcp`, `postgres`, `gui`, `stt-tts`, `telegram`, `matrix`, `discord`, `irc`, `whatsapp`, `slack`, `signal`, `viber`, `mic`, `ha`, `email`, `graph`, `auth`, `mcp-manager`, `playwright`, `joplin`, `atlassian`, `google-workspace`, `crm`, `jog-hu`, `jog-hu-host`, `grafana-mcp`, `uptime-kuma-mcp`, `hyperframes`, `global-news`, `world-weather`, `bash-mcp`, `bash-mcp-host`.

Example Ansible task on a brand-new VM:

```yaml
- name: Install QuorumAI unattended
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

The installer never runs `docker compose up -d` on its own when stdin is not a TTY — it writes all the files and prints the exact manual start command instead, so a follow-up Ansible task should run `docker network create quorum-net` and `docker compose up -d` in the install directory explicitly.

---

## Configuration

Copy `.env.example` to `.env` and fill in what you need. The `.env.example` file contains inline documentation for every key.

### Most important keys

| Key | Default | Description |
|---|---|---|
| `COMPOSE_PROFILES` | — | Comma-separated profiles to start |
| `AUTH_MODE` | `none` | `none` / `local` / `sso` |
| `ORCHESTRATOR_PORT` | `8000` | Orchestrator FastAPI port |
| `GUI_PORT` | `3000` | GUI port |
| `QDRANT_HTTP_PORT` | `6333` | Qdrant REST port |
| `POSTGRES_PORT` | `5433` | PostgreSQL port |
| `POSTGRES_PASSWORD` | `changeme` | PostgreSQL password — change this |
| `TRACE_RETENTION_DAYS` | `14` | Auto-delete traces older than N days |
| `ANTHROPIC_API_KEY` | — | Required if using Anthropic provider |
| `OPENROUTER_API_KEY` | — | Required if using OpenRouter |
| `OPENAI_API_KEY` | — | Required if using OpenAI |
| `GOOGLE_API_KEY` | — | Required if using Google Gemini |
| `TELEGRAM_BOT_TOKEN` | — | Required for Telegram bridge |
| `TELEGRAM_CHAT_ID` | — | Telegram chat ID to accept messages from |
| `NOTIFY_TELEGRAM_CHAT_ID` | — | Chat ID for task-completion notifications (defaults to `TELEGRAM_CHAT_ID` if same) |
| `MATRIX_HOMESERVER` | — | Matrix server URL |
| `MATRIX_ACCESS_TOKEN` | — | Matrix bot access token |
| `DISCORD_BOT_TOKEN` | — | Required for Discord bridge |
| `SLACK_BOT_TOKEN` | — | Required for Slack bridge |
| `SLACK_APP_TOKEN` | — | Required for Slack Socket Mode |
| `SIGNAL_PHONE` | — | Phone number for Signal bridge |
| `VIBER_AUTH_TOKEN` | — | Required for Viber bridge |
| `HA_URL` | `http://homeassistant:8123` | Home Assistant base URL |
| `HA_TOKEN` | — | HA Long-Lived Access Token |
| `IMAP_HOST` | — | IMAP server for Email MCP |
| `SMTP_HOST` | — | SMTP server for Email MCP |
| `FALKORDB_URL` | — | Set to enable the knowledge graph |
| `VAPID_EMAIL` | — | Required for web push notifications |
| `VAPID_PRIVATE_KEY` | — | Auto-generated by the installer (requires `cryptography` Python package); otherwise run `docker compose exec orchestrator python3 webpush.py` |
| `VAPID_PUBLIC_KEY` | — | Generated alongside the private key |
| `HU_TOOLS_PORT` | `4300` | hu-tools MCP port |
| `WHISPER_URL` | `http://whisper-http:8000` | STT service URL |
| `PIPER_URL` | `http://piper-http:5000` | TTS service URL |
| `ORCHESTRATOR_API_KEY` | — | Auto-generated by the installer; service-to-service token for bridges (required in `AUTH_MODE=local/sso`) |
| `CONVERSATION_API_KEY` | — | Auto-generated by the installer; protects the HA `/conversation` endpoint (empty = open) |

Agents are configured in `orchestrator/agents.yaml` — not in `.env`.

---

## Industry Packs

Pre-built vertical packages for specific industries. Each pack contains skill files, suggested agent configurations and MCP references. Installed via `install.py` or manually.

| Pack | Target | Key skills |
|---|---|---|
| `legal` | Law firms | Document search, contract analysis, Hungarian law research |
| `devops` | IT / DevOps companies | Incident triage, runbook search, AIOps with HITL |
| `agency` | Marketing & PR agencies | Project status, lead qualification, brief analysis, client reporting |

**Manual install:**
```bash
cp industry-packs/legal/skills/*.md data/skills/
cat industry-packs/legal/agents.yaml
```

**Via installer:** re-run `python3 install.py` → Modify → select an industry pack.

Create your own pack by copying `industry-packs/_template/` and filling in `pack.yaml`.

---
## CRM Integration

The CRM MCP (`mcps/crm/`) provides a unified interface to multiple CRM systems via a swappable adapter architecture. Agents use the same tools regardless of the backend.

**Supported adapters:**

| Adapter | System | Type |
|---|---|---|
| `minicrm` | MiniCRM (Hungarian market leader) | Full |
| `hubspot` | HubSpot CRM | Full |
| `pipedrive` | Pipedrive | Full |
| `billingo` | Billingo invoicing | Read-only |
| `szamlazzhu` | Számlázz.hu invoicing | Read-only |
| `salesautopilot` | SalesAutopilot (HU marketing automation) | Full |
| `twenty` | Twenty CRM | Full |

**Available tools:** `search_entities`, `get_entity`, `create_entity`, `update_entity`, `add_note`, `get_timeline`, `link_entities`, `get_related`, `emit_event`, `list_entity_types`

**Quick start:**
```env
CRM_ADAPTER=minicrm
MINICRM_SYSTEM_ID=12345
MINICRM_API_KEY=your-key
```

```bash
docker compose --profile crm up -d
```

Add `crm` to an agent's `tools:` list in `agents.yaml` to give it CRM access.

---
## jog.gov.hu MCP — Hungarian Legal Search

The jog.gov.hu MCP (`mcps/jog-hu/`) provides Hungarian legal information to AI agents in two deployment modes:

**Docker mode** (always works, no Playwright required):

| Tool | Description |
|---|---|
| `search_njt_laws(keywords)` | Keyword search on njt.jog.gov.hu — returns matching law titles and URLs |
| `get_law_text(law_id, section)` | Full or partial law text from njt.hu (e.g. `"2012. évi I. törvény"`, section `"69"`) |
| `list_recent_laws(category, days)` | Recent laws from Magyar Közlöny RSS feed |

**Host mode** (AI-powered search, requires running `host_server.py` on the host machine):

| Tool | Description |
|---|---|
| `search_law(question)` | Natural language question → AI answer + cited law references (jog.gov.hu) |

reCAPTCHA v3 scores sessions primarily on **IP reputation**. Docker container IPs and cloud/VPS server IPs are classified as datacenter ranges and receive a low trust score — regardless of browser fingerprint patches. A home or office machine on a **residential IP** scores high enough to pass. A graphical display is **not required** — the browser runs headless; the display is irrelevant.

**Quick start (Docker tools — always works):**
```bash
docker compose --profile jog-hu up -d
```

**Start the host server (AI search — residential IP required):**
```bash
# Works on: home/office desktop or laptop (Windows, macOS, Linux)
# Does NOT work on: cloud/VPS servers (datacenter IPs blocked by reCAPTCHA)
# Graphical display is NOT required — runs headless

pip install mcp fastmcp httpx playwright playwright-stealth
playwright install chromium

python3 mcps/jog-hu/host_server.py --background   # start daemon, port 4312
python3 mcps/jog-hu/host_server.py --stop          # stop daemon
```

**Add to `mcps.yaml`:**
```yaml
- name: jog-hu
  url: http://jog-hu-mcp:4302/mcp/
  description: Hungarian legal search (njt.hu)

# Optional — only if host_server.py is running:
- name: jog-hu-host
  url: http://host.docker.internal:4312/mcp/
  description: Hungarian legal AI search (jog.gov.hu)
```

Add `jog-hu` (and optionally `jog-hu-host`) to an agent's `tools:` list in `agents.yaml`.


---
## Contributing

1. Fork the repository and create a feature branch.
2. Follow the layer and compose conventions in `CLAUDE.md`.
3. Add or update the corresponding test block in `tests.sh`.
4. Open a pull request with a description of the phase or feature being added.

---

## License
