[English](README.md) | [Magyar](README.hu.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Русский](README.ru.md) | [Nederlands](README.nl.md) | [Polski](README.pl.md) | [Українська](README.uk.md) | [Svenska](README.sv.md) | [Italiano](README.it.md) | [日本語](README.ja.md) | [中文](README.zh.md) | [한국어](README.ko.md) | [Kiswahili](README.sw.md)

# QuorumAI

QuorumAI 是一个基于 LangGraph 构建的模块化自托管多智能体 AI 编排系统。它完全运行在 Docker 中，连接所有主要消息平台，支持语音交互、智能家居控制，并模拟具有长期记忆和自主任务执行能力的多角色 AI "企业"。

![Python 3.11](https://img.shields.io/badge/Python-3.11-blue.svg) ![Docker](https://img.shields.io/badge/Docker-Compose-2496ED.svg)

---

## QuorumAI 是什么

QuorumAI 将一个或多个 LLM 转变为 AI 智能体团队，能够：

- 回答问题、阅读新闻、控制智能家居设备 — 通过麦克风、Telegram、Matrix、Discord、Slack、Signal、WhatsApp、Viber 或 IRC 触发。
- 在专业角色（CEO、开发者、销售）之间委派工作，并使用 Qdrant 向量搜索在会话间维护长期记忆。
- 通过心跳调度器自主执行任务，必要时请求人工审批（HITL），并将每个外部能力作为 MCP（模型上下文协议）服务器公开。

一切通过 YAML 配置。切换模型、添加智能体或连接新工具无需修改代码。

---

## 快速安装

### 一行命令（推荐）

引导安装程序检查 Python 3 和 Docker 是否已安装，如未安装则自动安装，然后运行交互式 QuorumAI 安装程序。

**Linux / macOS:**
```bash
curl -fsSL https://raw.githubusercontent.com/fulopjozsef86/QuorumAI/main/install.sh | bash
```

**Windows（PowerShell — 以管理员身份运行）：**
```powershell
irm https://raw.githubusercontent.com/fulopjozsef86/QuorumAI/main/install.ps1 | iex
```

或从仓库下载 `install.bat` / `install.ps1` 并双击运行。

> **注意：** 在 Linux 上，引导程序从官方 Docker 仓库安装 Docker Engine（根据发行版使用 apt/dnf/yum），并将您的用户添加到 `docker` 组。之后需要重新登录。在 macOS 和 Windows 上，它会安装 Docker Desktop 并提示您在继续之前启动它。

---

### 已安装 Python 3 和 Docker？

直接克隆仓库并运行交互式安装程序 — 不需要 pip 或额外依赖：

```bash
git clone https://github.com/fulopjozsef86/QuorumAI.git
cd QuorumAI
python3 install.py
```

安装程序功能：
- 提供交互式模块选择器（编排器、网桥、语音、GUI 等）。
- 根据您的回答写入 `.env`，创建 `data/` 绑定挂载目录，并运行 `docker compose up -d`。
- 安装程序界面支持 16 种语言。

**卫星模式** — 在独立机器上运行麦克风、网桥或 MCP 服务器：
```bash
python3 install.py   # 在提示时选择 "Satellite"
```

---

## 快速开始（手动）

```bash
git clone https://github.com/your-org/QuorumAI.git
cd QuorumAI

# 创建共享 Docker 网络（每台主机执行一次）：
docker network create quorum-net

cp .env.example .env
# 编辑 .env — 设置 COMPOSE_PROFILES 和所需的 API 密钥

docker compose up -d
```

验证编排器是否运行：

```bash
curl http://localhost:8000/health
```

发送测试消息：

```bash
curl -X POST http://localhost:8000/invoke \
  -H 'Content-Type: application/json' \
  -d '{"message": "Hello, introduce yourself."}'
```

GUI 访问地址：`http://localhost:3000`

---

## 架构

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

每个层次都有自己的目录和 `compose.yml`。根 `compose.yml` 通过 `include:` 和 Docker Compose 配置文件聚合所有层次 — 只启动您需要的部分。

---

## 功能

### 核心编排

- **LangGraph 运行时** — 状态机智能体图，原生 HITL 检查点，`AsyncPostgresSaver`。
- **FastAPI HTTP API** — `POST /invoke`、`GET /health`、流式传输、Webhook 接收器、推送通知中继。
- **agents.yaml** — 用 YAML 声明智能体：名称、角色、提供商、模型、系统提示路径、工具。
- **热重载** — `POST /agents/reload` 无需重启容器即可重载 `agents.yaml`。
- **MCP 工具协议** — 每个外部能力都是 MCP 服务器；智能体自动发现工具。
- **Qdrant 向量记忆** — 混合语义 + BM42 词汇搜索，多语言 E5-Large 嵌入，智能体级集合，余弦去重，MMR 多样化召回。
- **夜间记忆整合** — 定时"梦境任务"将 PostgreSQL 会话历史提炼为长期 Qdrant 事实；合并进展，删除过期的临时条目；状态在 PostgreSQL 中跟踪。
- **PostgreSQL** — LangGraph `AsyncPostgresSaver` 检查点 + 任务和评论表。
- **知识图谱** — FalkorDB（Redis 兼容），用户级 Cypher 查询，自动实体抽取。

### LLM 提供商（按智能体配置，在 agents.yaml 中设置）

| 本地 | 云端 |
|---|---|
| Ollama（默认，无需密钥） | Anthropic Claude |
| llama.cpp | OpenAI |
| LM Studio | OpenRouter |
| vLLM | Google Gemini |
| Docker Model Runner | Grok (xAI) |
| Unsloth Studio | DeepSeek |
| | Mistral AI |
| | Together AI |
| | Fireworks AI |
| | 智谱 AI / Z.AI |
| | Eden AI（聚合器） |
| | NVIDIA NIM（提供免费层级） |

开始无需 API 密钥 — Ollama 在本地免费运行。

**提供商池** — 多台相同的本地服务器（例如六台 Ollama 机器）可组成一个命名池。编排器使用最少连接算法分发请求；若所有池成员均失败，则回退至常规 fallback 链。在 `providers.yaml` 中配置，可通过 GUI 提供商选项卡管理。

### 多智能体企业模拟

- 基于角色的智能体：CEO、开发者、销售以及任意自定义角色。
- 调度器智能体自动将传入请求路由到正确的专家。
- 流水线智能体：规划者 → 执行者 → 审阅者循环，共享状态。
- **自主（Deep）智能体** — 在任意智能体或流水线阶段设置 `deep: true` 以启用内置 LangGraph ReAct 循环。智能体自主规划、执行并迭代 — 反复调用工具直到任务完成或达到可选的工具调用限制（`deep_max_steps`，0 = 无限制）。可按智能体和阶段分别配置；GUI Agent Builder 中提供开关。
- 技能库：Markdown 技能文件，按智能体懒加载，社区市场用于共享。
- 共享工作区：智能体可读写共享文件区域。
- **管理工具** — 具有 `admin` 角色的智能体可在运行时通过 `system-admin` 工具创建和删除智能体、技能、MCP 服务器、cron 任务及心跳计划。每项写操作均需 HITL 审批。

### 任务管理与自主性

- 带子任务和评论的看板（PostgreSQL 支持）。
- 心跳调度器：智能体自动获取待处理任务（默认每 5 分钟）。
- 带 HITL 审批门的自主执行（Telegram `/approve`、GUI 按钮）。
- 推送通知：Telegram、Home Assistant `notify`、Web 推送（VAPID）。任务可以指定 `notify_channel` 字段，使完成消息始终发送到正确的桥接器，无论哪个会话创建了该任务。智能体可以调用 `list_notify_channels()` 在运行时发现可用频道。

**多天任务** — 适用于跨越数小时或数天的长期工作的推荐模式：
1. 通过聊天、Telegram 或 GUI 看板创建带有标题和描述的任务。
2. 智能体（或您）调用 `set_subtasks` 将其分解为命名步骤。
3. 每次心跳运行获取下一个待处理子任务，完成后停止 — 单次 LLM 会话保持简短且专注。
4. 进度、决策和中间结果以任务评论形式存储，每次后续运行都能获得完整上下文。
5. 所有子任务完成后，智能体关闭任务并发送完成通知。

此模式无需更改代码即可工作 — 它基于现有的任务工具（`set_subtasks`、`get_next_subtask`、`complete_subtask`），任何具有 `tasks` 工具源的智能体都可以访问。

### 安全监督（四人执政团）

可选的按代理层，在执行前检查每个高风险工具调用。在 `agents.yaml` 中设置 `guardian: true` 即可启用；未设置此标志的代理不受影响。

- **Guardian（守卫）** — 隔离的 LLM 调用（无工具绑定），评估工具名称和参数，返回：`NONE`（继续）、`SOFT VETO: 原因`（需要人工决策）或 `HARD VETO: 原因`（立即阻止）。
- **仲裁者（Arbiter）** — 在 SOFT VETO 时激活，生成 Markdown 分析报告，并通过 LangGraph `interrupt()` 暂停图执行。操作员通过 Telegram `/approve` 或 GUI 批准或拒绝 — 与 HITL 流程相同。
- **历史学家（Historian）** — 心跳任务，读取内存中的 Guardian 审计日志，并将结构化报告写入 PostgreSQL 的 `historian_reports` 表。
- **风险分类** — MCP 服务器在 `mcps.yaml` 中标记为 `risk: low` 或 `risk: high`。内存、任务和审批工具始终排除在检查之外，与风险级别无关。

```yaml
# agents.yaml
agents:
  - name: ceo
    guardian: true
    guardian_provider: anthropic        # 可选 — 为空时继承代理的提供商
    guardian_model: claude-haiku-4-5-20251001
    arbiter_provider: anthropic
    arbiter_model: claude-sonnet-4-6
```

```yaml
# mcps.yaml
servers:
  - name: playwright
    risk: high        # 所有 playwright 工具需要 Guardian 批准
  - name: hu-tools
    risk: low         # 天气、新闻 — 直接通过，不检查
```

`/guardian/log` 端点返回实时审计日志（最近 1,000 条决策）。

### 认证与多租户

| 模式 | 说明 |
|---|---|
| `AUTH_MODE=none` | 开放，无认证（默认，适合本地使用） |
| `AUTH_MODE=local` | Bearer 令牌；用户定义于 `LOCAL_USERS=user1:pass1,...` |
| `AUTH_MODE=sso` | Keycloak OIDC/JWT，或任意 OIDC 提供商（Auth0、Okta、Authelia 等） |

**按用户隔离。** 在多用户模式下，每个用户的记忆和知识图谱相互分离：长期记忆
存入该用户专属的 Qdrant 集合，图谱存入专属 `scope` — 读取时只能看到自己的数据以及
管理员维护的共享层，永远看不到其他用户的数据。夜间维护同样**按用户**执行。

### 可观测性

- 每轮带 token 和成本记录的流水线追踪。
- GUI 监控选项卡中的瀑布视图。
- 通过 `TRACE_RETENTION_DAYS` 控制的自动追踪清理。

### Webhook 接收器

接受来自以下来源的已签名 Webhook：GitHub、Gitea、Drone CI、Grafana、n8n、Slack、ERPNext、Twenty CRM、Zammad、Tiledesk、Uptime Kuma、Wekan、Umami、Duplicati、BorgWarehouse。

### 备份与配置持久化

所有运行时数据以绑定挂载方式存储在 `data/` 中；所有配置存于 YAML 文件——容器内无隐藏状态。

**创建备份**（包含 `.env` + `data/`）：

```bash
sudo python3 backup.py backup                 # 交互式，自动文件名
sudo python3 backup.py backup /srv/backup.tgz # 指定输出路径
```

**恢复**：

```bash
python3 backup.py restore /srv/backup.tgz           # 恢复到当前目录
python3 backup.py restore /srv/backup.tgz /opt/qai  # 恢复到指定目录
```

在 Linux / macOS 上使用 `sudo` 运行以保留文件所有者。Windows 上无需此操作。

---

## 桥接器

| 桥接器 | 传输方式 | Compose 配置文件 |
|---|---|---|
| Telegram | Bot API，async（python-telegram-bot） | `telegram` |
| Matrix | matrix-nio，房间级别 | `matrix` |
| Discord | discord.py，斜线命令 | `discord` |
| IRC | irc3 asyncio，多频道 | `irc` |
| WhatsApp | Meta Cloud API webhook | `whatsapp` |
| Slack | slack-bolt Socket Mode | `slack` |
| Signal | signal-cli REST API 轮询 | `signal` |
| Viber | FastAPI webhook，键盘按钮 | `viber` |

每个桥接器都提供 `/notify`（编排器推送通知）和 `/health`（存活检查），并支持发送者和频道的允许列表。Telegram 和 GUI 还支持 HITL `/approve` 流程。所有桥接器均支持通过 `/language` 命令按用户切换语言；偏好设置存储在 PostgreSQL 中，容器重启后仍然保留。

---

## 语音

### 麦克风桥接器（本地麦克风）

Compose 配置文件：`mic`

- openWakeWord — 可配置唤醒词（默认："Ok Szif"）。
- Wyoming Whisper — 本地 STT，无需云端。
- Wyoming Piper — 本地 TTS。
- Linux 桌面的 PulseAudio 套接字挂载。

**平台说明：**

- **Linux** — 安装程序自动检测您的 UID 并挂载正确的 PulseAudio 套接字（`/run/user/<uid>/pulse`）。
- **macOS / Windows** — Docker Desktop 不会传递音频设备。安装程序会改写 PulseAudio TCP 配置。在启动 mic 容器前，请以 TCP 模式设置 PulseAudio：
  - macOS: `brew install pulseaudio && pulseaudio --load=module-native-protocol-tcp --exit-idle-time=-1 --daemon`
  - Windows (WSL2): `sudo apt install pulseaudio && pulseaudio --load=module-native-protocol-tcp --exit-idle-time=-1 --start`
  - Windows（原生）：下载 PulseAudio for Windows，在 `default.pa` 中取消注释 `module-native-protocol-tcp`，在防火墙中允许端口 4713。

### Home Assistant Voice PE

Compose 配置文件：`ha`

QuorumAI 在 Home Assistant 中注册为对话智能体。HA Assist 负责唤醒词检测、Whisper STT 和 Piper TTS；QuorumAI 负责推理和工具调用。

### STT 和 TTS 工具（智能体可调用）

Compose 配置文件：`stt-tts`

将 Whisper 和 Piper 作为 HTTP API 公开，智能体可以将其作为 `system-stt` 和 `system-tts` 工具调用。

---

## GUI

Compose 配置文件：`gui` — 访问地址 `http://localhost:3000`

基于 React、Vite 和 Tailwind CSS 构建。

| 选项卡 | 说明 |
|---|---|
| 聊天 | 向任意智能体发送消息；查看流式响应 |
| 智能体构建器 | 可视化企业图；创建和编辑智能体及其角色 |
| 技能编辑器 | 创建和管理 Markdown 技能文件 |
| 任务 | 看板；子任务树；评论；审批按钮 |
| 提供商 | 实时提供商状态和可用模型列表 |
| 心跳 | 调度器状态；下次运行时间；手动触发 |
| 可观测性 | 流水线追踪；token 和成本瀑布视图 |

- 16 种界面语言，14 个主题。
- HITL 审批按钮集成在聊天和任务选项卡中。

---

## 安装详情

### 前提条件

- Docker Engine 24+ 和 Docker Compose v2。
- Python 3.8+（用于 `install.py`）— 无需 pip 或 virtualenv。
- 本地模型：Ollama 运行在主机 11434 端口。

### 创建共享网络（每台主机执行一次）

```bash
docker network create quorum-net
```

### 选择配置文件

在 `.env` 中设置配置文件，以便直接运行 `docker compose up -d`：

```env
COMPOSE_PROFILES=orchestrator,memory,mcp,postgres,telegram,gui
```

或显式传入：

```bash
docker compose --profile orchestrator --profile memory --profile gui up -d
```

可用配置文件：`orchestrator`、`memory`、`mcp`、`postgres`、`telegram`、`ha`、`mic`、`gui`、`stt-tts`、`mcp-manager`、`playwright`、`joplin`、`auth`、`email`、`matrix`、`discord`、`irc`、`whatsapp`、`slack`、`signal`、`viber`、`graph`

### 源码更改后重建

```bash
# 仅重建已更改的服务：
docker compose build orchestrator

# 不影响其他容器地重启：
docker compose up -d --no-deps orchestrator
```

### 数据目录结构

```
data/
  qdrant/        # Qdrant 向量
  postgres/      # PostgreSQL 数据
  workspace/     # 每个智能体的文件工作区
  whisper/       # Whisper 模型缓存
  piper/         # Piper 语音文件
  ...
```

`data/` 下的所有内容均已 gitignore。备份此目录可保留所有持久状态。

---

## 配置

将 `.env.example` 复制为 `.env` 并填写所需内容。`.env.example` 文件包含每个配置项的内联文档。

### 最重要的配置项

| 配置项 | 默认值 | 说明 |
|---|---|---|
| `COMPOSE_PROFILES` | — | 要启动的配置文件，逗号分隔 |
| `AUTH_MODE` | `none` | `none` / `local` / `sso` |
| `ORCHESTRATOR_PORT` | `8000` | 编排器 FastAPI 端口 |
| `GUI_PORT` | `3000` | GUI 端口 |
| `QDRANT_HTTP_PORT` | `6333` | Qdrant REST 端口 |
| `POSTGRES_PORT` | `5433` | PostgreSQL 端口 |
| `POSTGRES_PASSWORD` | `changeme` | PostgreSQL 密码 — 请修改！ |
| `TRACE_RETENTION_DAYS` | `14` | 自动删除 N 天前的追踪数据 |
| `ANTHROPIC_API_KEY` | — | 使用 Anthropic 提供商时必需 |
| `OPENROUTER_API_KEY` | — | 使用 OpenRouter 时必需 |
| `OPENAI_API_KEY` | — | 使用 OpenAI 时必需 |
| `GOOGLE_API_KEY` | — | 使用 Google Gemini 时必需 |
| `TELEGRAM_BOT_TOKEN` | — | Telegram 桥接器必需 |
| `TELEGRAM_CHAT_ID` | — | 接受消息的 Telegram 聊天 ID |
| `NOTIFY_TELEGRAM_CHAT_ID` | — | 任务完成通知的聊天 ID（与 `TELEGRAM_CHAT_ID` 相同时可复用） |
| `MATRIX_HOMESERVER` | — | Matrix 服务器 URL |
| `MATRIX_ACCESS_TOKEN` | — | Matrix 机器人访问令牌 |
| `DISCORD_BOT_TOKEN` | — | Discord 桥接器必需 |
| `SLACK_BOT_TOKEN` | — | Slack 桥接器必需 |
| `SLACK_APP_TOKEN` | — | Slack Socket Mode 必需 |
| `SIGNAL_PHONE` | — | Signal 桥接器的电话号码 |
| `VIBER_AUTH_TOKEN` | — | Viber 桥接器必需 |
| `HA_URL` | `http://homeassistant:8123` | Home Assistant 基础 URL |
| `HA_TOKEN` | — | HA 长期访问令牌 |
| `IMAP_HOST` | — | Email MCP 的 IMAP 服务器 |
| `SMTP_HOST` | — | Email MCP 的 SMTP 服务器 |
| `FALKORDB_URL` | — | 设置后启用知识图谱 |
| `VAPID_EMAIL` | — | Web 推送通知必需 |
| `VAPID_PRIVATE_KEY` | — | 由安装程序自动生成（需要 Python 包 `cryptography`）；否则运行 `docker compose exec orchestrator python3 webpush.py` |
| `VAPID_PUBLIC_KEY` | — | 与私钥同时生成 |
| `HU_TOOLS_PORT` | `4300` | hu-tools MCP 端口 |
| `WHISPER_URL` | `http://whisper-http:8000` | STT 服务 URL |
| `PIPER_URL` | `http://piper-http:5000` | TTS 服务 URL |
| `ORCHESTRATOR_API_KEY` | — | 由安装程序自动生成；桥接器的服务间令牌（`AUTH_MODE=local/sso` 时必需） |
| `CONVERSATION_API_KEY` | — | 由安装程序自动生成；保护 HA `/conversation` 端点（空 = 开放） |

智能体配置：`orchestrator/agents.yaml`。完整文档：`.env.example`。

---

## 行业包

为特定行业预构建的垂直包。每个包包含技能文件、建议的智能体配置和 MCP 引用。通过 `install.py` 或手动安装。

| 包 | 目标 | 主要技能 |
|---|---|---|
| `legal` | 律师事务所 | 文档搜索、合同分析、匈牙利法律搜索 |
| `devops` | IT/DevOps 公司 | 事件分类、运行手册搜索、带 HITL 的 AIOps |
| `agency` | 营销与公关代理机构 | 项目状态、潜在客户资质审核、简报分析、客户报告 |

**手动安装：**
```bash
cp industry-packs/legal/skills/*.md data/skills/
cat industry-packs/legal/agents.yaml
```

**通过安装程序：** 重新运行 `python3 install.py` → 修改 → 选择行业包。

通过复制 `industry-packs/_template/` 并填写 `pack.yaml` 来创建自己的包。

---

## CRM 集成

CRM MCP（`mcps/crm/`）通过可替换的适配器架构为多个 CRM 系统提供统一接口。无论后端如何，智能体使用相同的工具。

**支持的适配器：**

| 适配器 | 系统 | 类型 |
|---|---|---|
| `minicrm` | MiniCRM（匈牙利市场领导者） | 完整 |
| `hubspot` | HubSpot CRM | 完整 |
| `pipedrive` | Pipedrive | 完整 |
| `billingo` | Billingo 开票 | 只读 |
| `szamlazzhu` | Számlázz.hu 开票 | 只读 |
| `salesautopilot` | SalesAutopilot（匈牙利营销自动化） | 完整 |

**可用工具：** `search_entities`、`get_entity`、`create_entity`、`update_entity`、`add_note`、`get_timeline`、`link_entities`、`get_related`、`emit_event`、`list_entity_types`

**快速开始：**
```env
CRM_ADAPTER=minicrm
MINICRM_SYSTEM_ID=12345
MINICRM_API_KEY=your-key
```

```bash
docker compose --profile crm up -d
```

在 `agents.yaml` 中将 `crm` 添加到智能体的 `tools:` 列表以赋予其 CRM 访问权限。

---

## jog.gov.hu MCP — 匈牙利法律搜索

jog.gov.hu MCP（`mcps/jog-hu/`）以两种部署模式向 AI 智能体提供匈牙利法律信息：

**Docker 模式**（始终可用，无需 Playwright）：

| 工具 | 说明 |
|---|---|
| `search_njt_laws(keywords)` | 在 njt.jog.gov.hu 上进行关键词搜索 — 返回匹配的法律标题和 URL |
| `get_law_text(law_id, section)` | 从 njt.hu 获取完整或部分法律文本（例如 `"2012. évi I. törvény"`，章节 `"69"`） |
| `list_recent_laws(category, days)` | 从 Magyar Közlöny RSS 获取近期法律 |

**主机模式**（AI 驱动搜索，需要在主机上运行 `host_server.py`）：

| 工具 | 说明 |
|---|---|
| `search_law(question)` | 自然语言问题 → AI 答案 + 引用的法律参考（jog.gov.hu） |

reCAPTCHA v3 评分会话主要依据 **IP 信誉**。Docker 容器 IP 和云/VPS 服务器 IP 被划分为数据中心地址段，无论浏览器指纹如何，都会获得较低的信任分 — 从而被拦截。家庭或办公室机器使用**住宅 IP** 才能获得足够高的分数通过验证。**无需图形显示** — 浏览器以无头模式运行，显示器与此无关。

**快速开始（Docker 工具 — 始终可用）：**
```bash
docker compose --profile jog-hu up -d
```

**启动主机服务器（AI 搜索 — 需要住宅 IP）：**
```bash
# 适用于：家庭/办公室台式机或笔记本电脑（Windows、macOS、Linux）
# 不适用于：云/VPS 服务器（数据中心 IP 被 reCAPTCHA 屏蔽）
# 无需图形显示 — 以无头模式运行

pip install mcp fastmcp httpx playwright playwright-stealth
playwright install chromium

python3 mcps/jog-hu/host_server.py --background   # 启动守护进程，端口 4312
python3 mcps/jog-hu/host_server.py --stop          # 停止守护进程
```

**添加到 `mcps.yaml`：**
```yaml
- name: jog-hu
  url: http://jog-hu-mcp:4302/mcp/
  description: Hungarian legal search (njt.hu)

# 可选 — 仅在 host_server.py 运行时：
- name: jog-hu-host
  url: http://host.docker.internal:4312/mcp/
  description: Hungarian legal AI search (jog.gov.hu)
```

在 `agents.yaml` 中将 `jog-hu`（以及可选的 `jog-hu-host`）添加到智能体的 `tools:` 列表。

---

## 贡献

1. Fork 仓库并创建功能分支。
2. 遵循 `CLAUDE.md` 中的层次和 compose 规范。
3. 在 `tests.sh` 中添加或更新相应的测试块。
4. 提交包含所添加阶段或功能描述的 Pull Request。

---

## 许可证
