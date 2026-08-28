[English](README.md) | [Magyar](README.hu.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Русский](README.ru.md) | [Nederlands](README.nl.md) | [Polski](README.pl.md) | [Українська](README.uk.md) | [Svenska](README.sv.md) | [Italiano](README.it.md) | [日本語](README.ja.md) | [中文](README.zh.md) | [한국어](README.ko.md) | [Kiswahili](README.sw.md)

# QuorumAI

QuorumAIは、LangGraph上に構築されたモジュール式のセルフホスト型マルチエージェントAIオーケストレーションシステムです。Dockerで完全に動作し、主要なメッセージングプラットフォームすべてに接続し、音声インタラクション、スマートホーム制御をサポートし、長期記憶と自律的なタスク実行を備えた多役割AI「企業」をシミュレートします。

![Python 3.11](https://img.shields.io/badge/Python-3.11-blue.svg) ![Docker](https://img.shields.io/badge/Docker-Compose-2496ED.svg)

---

## QuorumAIとは

QuorumAIは1つ以上のLLMをAIエージェントのチームに変換します。このチームは以下のことができます。

- 質問への回答、ニュースの読み上げ、スマートホームデバイスの制御 — マイク、Telegram、Matrix、Discord、Slack、Signal、WhatsApp、Viber、IRCから起動。
- 専門的な役割（CEO、開発者、営業）間で作業を委任し、Qdrantベクター検索を使用してセッション間で長期記憶を維持。
- ハートビートスケジューラーによるタスクの自律実行、必要に応じた人間の承認要求（HITL）、すべての外部機能をMCP（Model Context Protocol）サーバーとして公開。

すべてはYAMLで設定されます。モデルの交換、エージェントの追加、新しいツールの接続にコード変更は不要です。

---

## クイックインストール

### ワンライナー（推奨）

ブートストラップインストーラーはPython 3とDockerの有無を確認し、なければインストールしてから対話型QuorumAIインストーラーを実行します。

**Linux / macOS:**
```bash
curl -fsSL https://raw.githubusercontent.com/FulopJozsi/QuorumAI/main/install.sh | bash
```

**Windows（PowerShell — 管理者として実行）：**
```powershell
irm https://raw.githubusercontent.com/FulopJozsi/QuorumAI/main/install.ps1 | iex
```

またはリポジトリから `install.bat` / `install.ps1` をダウンロードしてダブルクリックします。

> **注意：** Linuxでは、ブートストラップが公式DockerリポジトリからDocker Engineをインストールし（ディストリビューションによりapt/dnf/yum）、ユーザーを `docker` グループに追加します。その後ログアウト/ログインが必要です。macOSとWindowsではDocker Desktopをインストールし、続行前に起動するよう求めます。

---

### Python 3とDockerがすでにインストールされている場合

リポジトリをクローンして対話型インストーラーを直接実行します — pipや追加の依存関係は不要です：

```bash
git clone https://github.com/FulopJozsi/QuorumAI.git
cd QuorumAI
python3 install.py
```

インストーラーの機能：
- 対話型モジュールセレクター（オーケストレーター、ブリッジ、音声、GUIなど）を提供します。
- 回答から `.env` を作成し、`data/` バインドマウントディレクトリを作成して `docker compose up -d` を実行します。
- インストーラーのUIは16言語に対応しています。

**サテライトモード** — マイク、ブリッジ、またはMCPサーバーを別のマシンで実行：
```bash
python3 install.py   # プロンプトで「Satellite」を選択
```

---

## クイックスタート

```bash
git clone https://github.com/FulopJozsi/QuorumAI.git
cd QuorumAI
python3 install.py
```

オーケストレーターが動作していることを確認:

```bash
curl http://localhost:8000/health
```

テストメッセージを送信:

```bash
curl -X POST http://localhost:8000/invoke \
  -H 'Content-Type: application/json' \
  -d '{"message": "Hello, introduce yourself."}'
```

GUIにアクセス: `http://localhost:3000`

---

## アーキテクチャ

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

各レイヤーは独自のディレクトリと`compose.yml`を持ちます。ルートの`compose.yml`は`include:`とDocker Composeプロファイルを通じてすべてのレイヤーを集約します — 必要なものだけを起動します。

---

## 機能

### コアオーケストレーション

- **LangGraphランタイム** — 状態機械エージェントグラフ、ネイティブHITLチェックポインティング、`AsyncPostgresSaver`。
- **FastAPI HTTP API** — `POST /invoke`、`GET /health`、ストリーミング、Webhookレシーバー、プッシュ通知リレー。
- **agents.yaml** — YAMLでエージェントを宣言: 名前、役割、プロバイダー、モデル、システムプロンプトパス、ツール。
- **ホットリロード** — `POST /agents/reload`でコンテナ再起動なしに`agents.yaml`を再読み込み。
- **MCPツールプロトコル** — すべての外部機能がMCPサーバー; エージェントがツールを自動検出。
- **Qdrantベクターメモリ** — ハイブリッドセマンティック + BM42語彙検索、multilingual-e5-largeエンベディング、エージェントスコープのコレクション、コサイン重複排除、MMR多様化リコール。
- **夜間メモリ統合** — スケジュールされた「夢ジョブ」がPostgreSQLセッション履歴を長期Qdrantファクトに蒸留；進行状況をマージし、古いエフェメラルエントリを削除；状態はPostgreSQLで追跡。
- **PostgreSQL** — LangGraph `AsyncPostgresSaver`チェックポインター + タスクとコメントテーブル。
- **知識グラフ** — FalkorDB（Redis互換）、ユーザースコープのCypherクエリ、自動エンティティ抽出。

### LLMプロバイダー（エージェントごと、agents.yamlで設定）

| ローカル | クラウド |
|---|---|
| Ollama（デフォルト、キー不要） | Anthropic Claude |
| llama.cpp | OpenAI |
| LM Studio | OpenRouter |
| vLLM | Google Gemini |
| Docker Model Runner | Grok (xAI) |
| Unsloth Studio | DeepSeek |
| | Mistral AI |
| | Together AI |
| | Fireworks AI |
| | Zhipu AI / Z.AI |
| | Eden AI（アグリゲーター） |
| | NVIDIA NIM（無料枠あり） |

開始にAPIキーは不要 — Ollamaはローカルで無料で動作。

**プロバイダープール** — 複数の同一ローカルサーバー（例: 6台のOllamaマシン）を名前付きプールにグループ化できます。オーケストレーターは最小接続数によるロードバランシングでリクエストを分散し、すべてのプールメンバーが失敗した場合は通常のフォールバックチェーンに移行します。`providers.yaml`で設定し、GUIのプロバイダータブから管理できます。

### マルチエージェント企業シミュレーション

- 役割ベースのエージェント: CEO、開発者、営業、任意のカスタム役割。
- ディスパッチャーエージェントが受信リクエストを適切な専門家に自動ルーティング。
- パイプラインエージェント: 共有状態を持つプランナー → 実行者 → レビュアーのループ。
- **自律（ディープ）エージェント** — 任意のエージェントまたはパイプラインステージに`deep: true`を設定して、組み込みのLangGraph ReActループを有効化。エージェントは自律的に計画、実行、反復し、タスクが完了するかオプションのツール呼び出し制限（`deep_max_steps`、0 = 無制限）に達するまでツールを繰り返し呼び出します。エージェントおよびパイプラインステージごとに設定可能; GUIのエージェントビルダーで切り替え可能。
- スキルライブラリ: Markdownスキルファイル、エージェントごとのレイジーロード、コミュニティマーケットプレイス。
- 共有ワークスペース: エージェントが共有ファイルエリアを読み書き可能。
- **管理ツール** — `admin`ロールを持つエージェントは、`system-admin`ツールを通じて実行時にエージェント、スキル、MCPサーバー、cronジョブ、ハートビートスケジュールを作成・削除できます。すべての書き込みアクションは実行前にHITL承認が必要です。

### タスク管理と自律性

- サブタスクとコメント付きカンバンボード（PostgreSQLベース）。
- ハートビートスケジューラー: エージェントが自動的に保留中のタスクを取得（デフォルトで5分ごと）。
- HITLの承認ゲートによる自律実行（Telegram `/approve`、GUIボタン）。
- プッシュ通知: Telegram、Home Assistant `notify`、Webプッシュ（VAPID）。タスクに`notify_channel`フィールドを指定することで、タスクを作成したセッションに関係なく、完了メッセージが常に正しいブリッジに届きます。エージェントは`list_notify_channels()`を呼び出して、実行時に利用可能なチャンネルを確認できます。

**複数日にわたるタスク** — 数時間から数日にわたる長期作業に推奨されるパターン：
1. チャット、Telegram、またはGUIのカンバンボードでタイトルと説明のあるタスクを作成する。
2. エージェント（またはあなた）が`set_subtasks`を呼び出し、名前付きステップに分割する。
3. ハートビートの実行ごとに次の保留中のサブタスクを取得し、完了させて停止する — 個別のLLMセッションは短くフォーカスされた状態を保つ。
4. 進捗、決定事項、中間結果はタスクコメントとして保存されるため、以降の実行ごとに完全なコンテキストが得られる。
5. すべてのサブタスクが完了したら、エージェントはタスクを閉じて完了通知を送信する。

このパターンはコード変更なしで機能します — `tasks`ツールソースを持つすべてのエージェントがアクセスできる既存のタスクツール（`set_subtasks`、`get_next_subtask`、`complete_subtask`）の上に構築されています。

### 安全監視（クアドルムウィラトゥス）

ツール呼び出しを実行前に検査するオプションのエージェントごとのレイヤー。`agents.yaml` で `guardian: true` を設定することで有効になります。フラグのないエージェントは影響を受けません。

- **Guardian** — ツール名と引数を評価する隔離されたLLM呼び出し（ツールなし）。結果として `NONE`（続行）、`SOFT VETO: 理由`（人間の判断が必要）、または `HARD VETO: 理由`（即時ブロック）を返します。
- **仲裁者（Arbiter）** — SOFT VETO で起動。Markdown分析レポートを生成し、LangGraph `interrupt()` でグラフを一時停止します。オペレーターはTelegramの `/approve` またはGUIで承認または拒否します（HITLと同じフロー）。
- **歴史家（Historian）** — インメモリのGuardian監査ログを読み取り、PostgreSQL の `historian_reports` テーブルに構造化レポートを書き込むハートビートジョブ。
- **リスク分類** — MCPサーバーは `mcps.yaml` で `risk: low` または `risk: high` とタグ付けされます。メモリ、タスク、承認ツールは常に検査から除外されます。

```yaml
# agents.yaml
agents:
  - name: ceo
    guardian: true
    guardian_provider: anthropic        # 省略可 — 空の場合はエージェントのプロバイダーを継承
    guardian_model: claude-haiku-4-5-20251001
    arbiter_provider: anthropic
    arbiter_model: claude-sonnet-4-6
```

```yaml
# mcps.yaml
servers:
  - name: playwright
    risk: high        # すべてのplaywright ツールにGuardianの承認が必要
  - name: hu-tools
    risk: low         # 天気、ニュース — 検査なしでパス
```

`/guardian/log` エンドポイントはライブ監査ログ（最新1,000件の決定）を返します。

### 認証とマルチテナンシー

| モード | 説明 |
|---|---|
| `AUTH_MODE=none` | オープン — 認証なし（デフォルト、ローカル使用向け） |
| `AUTH_MODE=local` | Bearerトークン; ユーザーは`LOCAL_USERS=user1:pass1,...`で定義 |
| `AUTH_MODE=sso` | Keycloak OIDC/JWT、または任意のOIDCプロバイダー（Auth0、Okta、Autheliaなど） |

**ユーザーごとの分離。** マルチユーザーモードでは、各ユーザーのメモリと
ナレッジグラフは分離されます。長期記憶はそのユーザー専用の Qdrant コレクション
に、グラフは専用の `scope` に保存され、読み取りでは自分のデータと管理者が整備した
共有レイヤーのみが見え、他のユーザーのデータは決して見えません。夜間の
メンテナンスも**ユーザーごと**に実行されます。

### オブザーバビリティ

- ターンごとのトークンとコストのログを含むパイプライントレース。
- GUIのモニタリングタブにウォーターフォールビュー。
- `TRACE_RETENTION_DAYS`で制御される自動トレースクリーンアップ。

### Webhookレシーバー

以下からの署名済みWebhookを受け付けます: GitHub、Gitea、Drone CI、Grafana、n8n、Slack、ERPNext、Twenty CRM、Zammad、Tiledesk、Uptime Kuma、Wekan、Umami、Duplicati、BorgWarehouse。

### バックアップと設定の永続化

すべての実行時データは`data/`にバインドマウントとして保存され、すべての設定はYAMLファイルに記述されています — コンテナ内に隠れた状態はありません。

**バックアップの作成**（`.env` + `data/`を含む）:

```bash
sudo python3 backup.py backup                 # 対話式、自動ファイル名
sudo python3 backup.py backup /srv/backup.tgz # 出力パスを明示指定
```

**復元**:

```bash
python3 backup.py restore /srv/backup.tgz          # 現在のディレクトリに復元
python3 backup.py restore /srv/backup.tgz /opt/qai # 特定のディレクトリに復元
```

Linux / macOSでは`sudo`で実行してファイルの所有者を保持してください。Windowsでは不要です。

---

## ブリッジ

| ブリッジ | トランスポート | Composeプロファイル |
|---|---|---|
| Telegram | Bot API、async（python-telegram-bot） | `telegram` |
| Matrix | matrix-nio、ルームレベル | `matrix` |
| Discord | discord.py、スラッシュコマンド | `discord` |
| IRC | irc3 asyncio、マルチチャンネル | `irc` |
| WhatsApp | Meta Cloud API webhook | `whatsapp` |
| Slack | slack-bolt Socket Mode | `slack` |
| Signal | signal-cli REST API ポーリング | `signal` |
| Viber | FastAPI webhook、キーボードボタン | `viber` |

すべてのブリッジが`/notify`（オーケストレーターからのプッシュ通知）と`/health`（ライブネスチェック）を公開し、送信者とチャンネルのアローリストをサポートします。TelegramとGUIはHITL `/approve`フローもサポートします。すべてのブリッジは`/language`コマンドによるユーザーごとの言語切り替えをサポートし、設定はPostgreSQLに保存されコンテナの再起動後も維持されます。

---

## 音声

### マイクブリッジ（ローカルマイク）

Composeプロファイル: `mic`

- openWakeWord — 設定可能なウェイクワード（デフォルト: "Ok Szif"）。
- Wyoming Whisper — ローカルSTT、クラウド不要。
- Wyoming Piper — ローカルTTS。
- LinuxデスクトップのPulseAudioソケットマウント。

**プラットフォームに関する注意:**

- **Linux** — インストーラーがUIDを検出し、適切なPulseAudioソケット（`/run/user/<uid>/pulse`）を自動的にマウントします。
- **macOS / Windows** — Docker Desktopはオーディオデバイスを通過しません。インストーラーは代わりにPulseAudio TCP設定を書き込みます。micコンテナを起動する前にPulseAudioをTCPモードに設定してください:
  - macOS: `brew install pulseaudio && pulseaudio --load=module-native-protocol-tcp --exit-idle-time=-1 --daemon`
  - Windows (WSL2): `sudo apt install pulseaudio && pulseaudio --load=module-native-protocol-tcp --exit-idle-time=-1 --start`
  - Windows（ネイティブ）: PulseAudio for Windowsをダウンロードし、`default.pa`で`module-native-protocol-tcp`のコメントアウトを解除し、ファイアウォールでポート4713を許可してください。

### Home Assistant Voice PE

Composeプロファイル: `ha`

QuorumAIがHome Assistantの会話エージェントとして登録されます。HA AssistがウェイクワードDetection、Whisper STT、Piper TTSをHA側で処理し、QuorumAIが推論とツール呼び出しを処理します。

### STTおよびTTSツール（エージェント呼び出し可能）

Composeプロファイル: `stt-tts`

WhisperとPiperをHTTP APIとして公開し、エージェントが`system-stt`および`system-tts`ツールとして呼び出せます。

---

## GUI

Composeプロファイル: `gui` — `http://localhost:3000`で利用可能

React、Vite、Tailwind CSSで構築。

| タブ | 説明 |
|---|---|
| チャット | 任意のエージェントにメッセージを送信; ストリーミング応答を表示 |
| エージェントビルダー | ビジュアル企業ダイアグラム; エージェントとその役割を作成・編集 |
| スキルエディター | Markdownスキルファイルを作成・管理 |
| タスク | カンバンボード; サブタスクツリー; コメント; 承認ボタン |
| プロバイダー | リアルタイムプロバイダー状態と利用可能なモデルリスト |
| ハートビート | スケジューラー状態; 次回実行時間; 手動トリガー |
| オブザーバビリティ | パイプライントレース; トークンとコストのウォーターフォールビュー |

- 16言語UI、14テーマ。
- チャットとタスクタブにHITL承認ボタンを統合。

---

## インストール詳細

### 前提条件

- Docker Engine 24以降 および Docker Compose v2。
- `install.py`用Python 3.8以降 — pipや仮想環境は不要。
- ローカルモデルの場合: ホストのポート11434でOllamaが動作していること。

### 共有ネットワークの作成（ホストごとに1回）

```bash
docker network create quorum-net
```

### プロファイルの選択

`.env`でプロファイルを設定し、`docker compose up -d`だけで起動できるようにする:

```env
COMPOSE_PROFILES=orchestrator,memory,mcp,postgres,telegram,gui
```

または明示的に指定:

```bash
docker compose --profile orchestrator --profile memory --profile gui up -d
```

利用可能なプロファイル: `orchestrator`, `memory`, `mcp`, `postgres`, `telegram`, `ha`, `mic`, `gui`, `stt-tts`, `mcp-manager`, `playwright`, `joplin`, `auth`, `email`, `matrix`, `discord`, `irc`, `whatsapp`, `slack`, `signal`, `viber`, `graph`

### データディレクトリ構成

```
data/
  qdrant/        # Qdrantベクター
  postgres/      # PostgreSQLデータ
  workspace/     # エージェントごとのファイルワークスペース
  whisper/       # Whisperモデルキャッシュ
  piper/         # Piperボイスファイル
  ...
```

`data/`配下はすべてgitignore対象です。このディレクトリをバックアップすることですべての永続状態が保存されます。

---

## 設定

`.env.example`を`.env`にコピーし、必要な項目を入力してください。`.env.example`ファイルにはすべてのキーのインラインドキュメントが含まれています。

### 主要キー

| キー | デフォルト | 説明 |
|---|---|---|
| `COMPOSE_PROFILES` | — | 起動するプロファイル（カンマ区切り） |
| `AUTH_MODE` | `none` | `none` / `local` / `sso` |
| `ORCHESTRATOR_PORT` | `8000` | オーケストレーターのFastAPIポート |
| `GUI_PORT` | `3000` | GUIポート |
| `QDRANT_HTTP_PORT` | `6333` | Qdrant RESTポート |
| `POSTGRES_PORT` | `5433` | PostgreSQLポート |
| `POSTGRES_PASSWORD` | `changeme` | PostgreSQLパスワード — 必ず変更してください |
| `TRACE_RETENTION_DAYS` | `14` | N日以上古いトレースの自動削除 |
| `ANTHROPIC_API_KEY` | — | Anthropicプロバイダーを使用する場合に必要 |
| `OPENROUTER_API_KEY` | — | OpenRouterを使用する場合に必要 |
| `OPENAI_API_KEY` | — | OpenAIを使用する場合に必要 |
| `GOOGLE_API_KEY` | — | Google Geminiを使用する場合に必要 |
| `TELEGRAM_BOT_TOKEN` | — | Telegramブリッジに必要 |
| `TELEGRAM_CHAT_ID` | — | メッセージを受け付けるTelegramチャットID |
| `NOTIFY_TELEGRAM_CHAT_ID` | — | タスク完了通知用のチャットID（`TELEGRAM_CHAT_ID`と同じ場合は省略可） |
| `MATRIX_HOMESERVER` | — | MatrixサーバーURL |
| `MATRIX_ACCESS_TOKEN` | — | Matrixボットのアクセストークン |
| `DISCORD_BOT_TOKEN` | — | Discordブリッジに必要 |
| `SLACK_BOT_TOKEN` | — | Slackブリッジに必要 |
| `SLACK_APP_TOKEN` | — | Slack Socket Modeに必要 |
| `SIGNAL_PHONE` | — | Signalブリッジの電話番号 |
| `VIBER_AUTH_TOKEN` | — | Viberブリッジに必要 |
| `HA_URL` | `http://homeassistant:8123` | Home AssistantのベースURL |
| `HA_TOKEN` | — | HAの長期アクセストークン |
| `IMAP_HOST` | — | Email MCP用IMAPサーバー |
| `SMTP_HOST` | — | Email MCP用SMTPサーバー |
| `FALKORDB_URL` | — | 知識グラフを有効化するために設定 |
| `VAPID_EMAIL` | — | Webプッシュ通知に必要 |
| `VAPID_PRIVATE_KEY` | — | インストーラーが自動生成（Pythonパッケージ`cryptography`が必要）; または`docker compose exec orchestrator python3 webpush.py`を実行 |
| `VAPID_PUBLIC_KEY` | — | 秘密鍵と同時に生成 |
| `HU_TOOLS_PORT` | `4300` | hu-tools MCPポート |
| `WHISPER_URL` | `http://whisper-http:8000` | STTサービスURL |
| `PIPER_URL` | `http://piper-http:5000` | TTSサービスURL |
| `ORCHESTRATOR_API_KEY` | — | インストーラーが自動生成; ブリッジ用サービス間トークン（`AUTH_MODE=local/sso`時に必要） |
| `CONVERSATION_API_KEY` | — | インストーラーが自動生成; HAの`/conversation`エンドポイントを保護（空 = オープン） |

エージェントは`orchestrator/agents.yaml`で設定します — `.env`ではありません。

---

## 業種パック

特定の業種向けに事前構築されたバーティカルパッケージです。各パックにはスキルファイル、推奨エージェント設定、MCPリファレンスが含まれています。`install.py`または手動でインストールできます。

| パック | 対象 | 主なスキル |
|---|---|---|
| `legal` | 法律事務所 | 文書検索、契約分析、ハンガリー法律検索 |
| `devops` | IT / DevOps企業 | インシデントトリアージ、ランブック検索、HITL付きAIOps |
| `agency` | マーケティング・PRエージェンシー | プロジェクト状況、リード評価、ブリーフ分析、クライアントレポーティング |

**手動インストール:**
```bash
cp industry-packs/legal/skills/*.md data/skills/
cat industry-packs/legal/agents.yaml
```

**インストーラー経由:** `python3 install.py`を再実行 → 変更 → 業種パックを選択。

`industry-packs/_template/`をコピーして`pack.yaml`を記入することで独自パックを作成できます。

---

## CRM統合

CRM MCP（`mcps/crm/`）は、交換可能なアダプターアーキテクチャを通じて複数のCRMシステムへの統一インターフェースを提供します。バックエンドに関係なく、エージェントは同じツールを使用します。

**サポートされているアダプター:**

| アダプター | システム | タイプ |
|---|---|---|
| `minicrm` | MiniCRM（ハンガリー市場リーダー） | フル |
| `hubspot` | HubSpot CRM | フル |
| `pipedrive` | Pipedrive | フル |
| `billingo` | Billingo請求書 | 読み取り専用 |
| `szamlazzhu` | Számlázz.hu請求書 | 読み取り専用 |
| `salesautopilot` | SalesAutopilot（HUマーケティングオートメーション） | フル |

**利用可能なツール:** `search_entities`, `get_entity`, `create_entity`, `update_entity`, `add_note`, `get_timeline`, `link_entities`, `get_related`, `emit_event`, `list_entity_types`

**クイックスタート:**
```env
CRM_ADAPTER=minicrm
MINICRM_SYSTEM_ID=12345
MINICRM_API_KEY=your-key
```

```bash
docker compose --profile crm up -d
```

エージェントにCRMアクセスを付与するには、`agents.yaml`のエージェントの`tools:`リストに`crm`を追加してください。

---

## jog.gov.hu MCP — ハンガリー法律検索

jog.gov.hu MCP（`mcps/jog-hu/`）は、2つのデプロイモードでAIエージェントにハンガリーの法律情報を提供します。

**Dockerモード**（常に動作、Playwright不要）:

| ツール | 説明 |
|---|---|
| `search_njt_laws(keywords)` | njt.jog.gov.huでのキーワード検索 — 一致する法律のタイトルとURLを返す |
| `get_law_text(law_id, section)` | njt.huからの全文または部分的な法律テキスト（例: `"2012. évi I. törvény"`、セクション`"69"`） |
| `list_recent_laws(category, days)` | Magyar KözlönyのRSSフィードからの最新法律 |

**ホストモード**（AI搭載検索、ホストマシンで`host_server.py`の実行が必要）:

| ツール | 説明 |
|---|---|
| `search_law(question)` | 自然言語の質問 → AI回答 + 引用法律参照（jog.gov.hu） |

reCAPTCHA v3のスコアリングはセッションを主に**IPの信頼性**に基づいて評価します。DockerコンテナのIPアドレスやクラウド・VPSサーバーのIPアドレスはデータセンター範囲として分類され、ブラウザのフィンガープリントに関係なく低い信頼スコアが付与されます。自宅やオフィスの**住宅用IPアドレス**を持つマシンは、十分に高いスコアを得られます。グラフィカルディスプレイは**不要**です — ブラウザはヘッドレスで動作し、ディスプレイの有無は関係ありません。

**クイックスタート（Dockerツール — 常に動作）:**
```bash
docker compose --profile jog-hu up -d
```

**ホストサーバーの起動（AI検索 — 住宅用IPが必要）:**
```bash
# 動作する環境: 自宅またはオフィスのデスクトップ・ノートパソコン（Windows、macOS、Linux）
# 動作しない環境: クラウド・VPSサーバー（データセンターIPはreCAPTCHAでブロックされる）
# グラフィカルディスプレイは不要 — ヘッドレスで動作

pip install mcp fastmcp httpx playwright playwright-stealth
playwright install chromium

python3 mcps/jog-hu/host_server.py --background   # デーモン起動、ポート4312
python3 mcps/jog-hu/host_server.py --stop          # デーモン停止
```

**`mcps.yaml`への追加:**
```yaml
- name: jog-hu
  url: http://jog-hu-mcp:4302/mcp/
  description: Hungarian legal search (njt.hu)

# オプション — host_server.pyが動作している場合のみ:
- name: jog-hu-host
  url: http://host.docker.internal:4312/mcp/
  description: Hungarian legal AI search (jog.gov.hu)
```

エージェントにアクセスを付与するには、`agents.yaml`の`tools:`リストに`jog-hu`（およびオプションで`jog-hu-host`）を追加してください。
