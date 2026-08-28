[English](README.md) | [Magyar](README.hu.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Русский](README.ru.md) | [Nederlands](README.nl.md) | [Polski](README.pl.md) | [Українська](README.uk.md) | [Svenska](README.sv.md) | [Italiano](README.it.md) | [日本語](README.ja.md) | [中文](README.zh.md) | [한국어](README.ko.md) | [Kiswahili](README.sw.md)

# QuorumAI

QuorumAI는 LangGraph 기반의 모듈식 자체 호스팅 멀티 에이전트 AI 오케스트레이션 시스템입니다. 완전히 Docker에서 실행되며, 주요 메시징 플랫폼 모두에 연결하고, 음성 상호작용, 스마트홈 제어를 지원하며, 장기 기억과 자율적 작업 실행을 갖춘 다중 역할 AI "회사"를 시뮬레이션합니다.

![Python 3.11](https://img.shields.io/badge/Python-3.11-blue.svg) ![Docker](https://img.shields.io/badge/Docker-Compose-2496ED.svg)

---

## QuorumAI란?

QuorumAI는 하나 이상의 LLM을 AI 에이전트 팀으로 변환합니다. 이 팀은 다음을 수행할 수 있습니다:

- 질문에 답하고, 뉴스를 읽고, 스마트홈 장치를 제어 — 마이크, Telegram, Matrix, Discord, Slack, Signal, WhatsApp, Viber 또는 IRC를 통해 트리거.
- 전문 역할(CEO, 개발자, 영업) 간에 작업을 위임하고 Qdrant 벡터 검색을 사용해 세션 간 장기 기억 유지.
- 하트비트 스케줄러를 통한 자율적 작업 실행, 필요 시 인간 승인 요청(HITL), 모든 외부 기능을 MCP(모델 컨텍스트 프로토콜) 서버로 노출.

모든 것이 YAML로 구성됩니다. 모델 교체, 에이전트 추가, 새 도구 연결에 코드 변경이 필요 없습니다.

---

## 빠른 설치

### 한 줄 명령어 (권장)

부트스트랩 설치 프로그램은 Python 3와 Docker가 설치되어 있는지 확인하고, 없으면 설치한 후 대화형 QuorumAI 설치 프로그램을 실행합니다.

**Linux / macOS:**
```bash
curl -fsSL https://raw.githubusercontent.com/fulopjozsef86/QuorumAI/main/install.sh | bash
```

**Windows (PowerShell — 관리자 권한으로 실행):**
```powershell
irm https://raw.githubusercontent.com/fulopjozsef86/QuorumAI/main/install.ps1 | iex
```

또는 저장소에서 `install.bat` / `install.ps1`을 다운로드하여 더블 클릭합니다.

> **참고:** Linux에서 부트스트랩은 공식 Docker 저장소(배포판에 따라 apt/dnf/yum)에서 Docker Engine을 설치하고 사용자를 `docker` 그룹에 추가합니다. 이후 로그아웃 후 다시 로그인해야 합니다. macOS와 Windows에서는 Docker Desktop을 설치하고 계속하기 전에 시작하도록 안내합니다.

---

### 이미 Python 3와 Docker가 있으신가요?

저장소를 클론하고 대화형 설치 프로그램을 직접 실행하세요 — pip이나 추가 의존성은 필요하지 않습니다:

```bash
git clone https://github.com/fulopjozsef86/QuorumAI.git
cd QuorumAI
python3 install.py
```

설치 프로그램 기능:
- 대화형 모듈 선택기(오케스트레이터, 브리지, 음성, GUI 등)를 제공합니다.
- 답변을 바탕으로 `.env`를 작성하고, `data/` 바인드 마운트 디렉토리를 생성하며 `docker compose up -d`를 실행합니다.
- 설치 프로그램 UI는 16개 언어를 지원합니다.

**Satellite 모드** — 별도 머신에서 마이크, 브리지 또는 MCP 서버 실행:
```bash
python3 install.py   # 프롬프트에서 "Satellite" 선택
```

---

## 빠른 시작 (수동)

```bash
git clone https://github.com/your-org/QuorumAI.git
cd QuorumAI

# 공유 Docker 네트워크 생성 (호스트당 한 번):
docker network create quorum-net

cp .env.example .env
# .env 편집 — COMPOSE_PROFILES와 필요한 API 키 설정

docker compose up -d
```

오케스트레이터가 실행 중인지 확인:

```bash
curl http://localhost:8000/health
```

테스트 메시지 전송:

```bash
curl -X POST http://localhost:8000/invoke \
  -H 'Content-Type: application/json' \
  -d '{"message": "Hello, introduce yourself."}'
```

GUI 접속: `http://localhost:3000`

---

## 아키텍처

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

각 레이어는 자체 디렉토리와 `compose.yml`을 가집니다. 루트 `compose.yml`은 `include:`와 Docker Compose 프로파일을 통해 모든 레이어를 집계합니다 — 필요한 것만 시작합니다.

---

## 기능

### 핵심 오케스트레이션

- **LangGraph 런타임** — 상태 기계 에이전트 그래프, 네이티브 HITL 체크포인팅, `AsyncPostgresSaver`.
- **FastAPI HTTP API** — `POST /invoke`, `GET /health`, 스트리밍, 웹훅 수신기, 푸시 알림 릴레이.
- **agents.yaml** — YAML로 에이전트 선언: 이름, 역할, 제공자, 모델, 시스템 프롬프트 경로, 도구.
- **핫 리로드** — `POST /agents/reload`로 컨테이너 재시작 없이 `agents.yaml` 재로드.
- **MCP 도구 프로토콜** — 모든 외부 기능이 MCP 서버; 에이전트가 도구를 자동 발견.
- **Qdrant 벡터 메모리** — 하이브리드 시맨틱 + BM42 어휘 검색, 다국어 E5-Large 임베딩, 에이전트 범위 컬렉션, 코사인 중복 제거, MMR 다양화 리콜.
- **야간 메모리 통합** — 예약된 「꿈 작업」이 PostgreSQL 세션 이력을 장기 Qdrant 사실로 증류; 진행 상황을 병합하고, 오래된 임시 항목을 제거; 상태는 PostgreSQL에서 추적.
- **PostgreSQL** — LangGraph `AsyncPostgresSaver` 체크포인터 + 작업 및 댓글 테이블.
- **지식 그래프** — FalkorDB (Redis 호환), 사용자 범위의 Cypher 쿼리, 자동 엔티티 추출.

### LLM 제공자 (에이전트별, agents.yaml에서 설정)

| 로컬 | 클라우드 |
|---|---|
| Ollama (기본값, 키 불필요) | Anthropic Claude |
| llama.cpp | OpenAI |
| LM Studio | OpenRouter |
| vLLM | Google Gemini |
| Docker Model Runner | Grok (xAI) |
| Unsloth Studio | DeepSeek |
| | Mistral AI |
| | Together AI |
| | Fireworks AI |
| | Zhipu AI / Z.AI |
| | Eden AI (집계자) |
| | NVIDIA NIM (무료 티어 제공) |

시작에 API 키 불필요 — Ollama가 로컬에서 무료로 실행.

**제공자 풀** — 동일한 로컬 서버 여러 대(예: Ollama 6대)를 명명된 풀로 그룹화할 수 있습니다. 오케스트레이터는 최소 연결 로드 밸런싱으로 요청을 분배하며, 모든 풀 멤버가 실패하면 일반 폴백 체인으로 전환합니다. `providers.yaml`에서 설정하고 GUI 제공자 탭에서 관리할 수 있습니다.

### 멀티 에이전트 회사 시뮬레이션

- 역할 기반 에이전트: CEO, 개발자, 영업 및 사용자 정의 역할.
- 디스패처 에이전트가 수신 요청을 적절한 전문가에게 자동 라우팅.
- 파이프라인 에이전트: 공유 상태의 플래너 → 실행자 → 검토자 루프.
- **자율(Deep) 에이전트** — 에이전트나 파이프라인 단계에 `deep: true`를 설정하면 내장 LangGraph ReAct 루프가 활성화됩니다. 에이전트가 계획, 실행, 반복을 자율적으로 수행하며 작업이 완료되거나 선택적 도구 호출 한도(`deep_max_steps`, 0 = 무제한)에 도달할 때까지 도구를 반복 호출합니다. 에이전트별 및 파이프라인 단계별로 구성 가능하며 GUI 에이전트 빌더에서 토글할 수 있습니다.
- 스킬 라이브러리: Markdown 스킬 파일, 에이전트별 지연 로드, 커뮤니티 마켓플레이스.
- 공유 작업 공간: 에이전트가 공유 파일 영역을 읽고 쓸 수 있습니다.
- **관리자 도구** — `admin` 역할을 가진 에이전트는 런타임에 `system-admin` 도구를 통해 에이전트, 스킬, MCP 서버, 크론 작업, 하트비트 일정을 생성 및 삭제할 수 있습니다. 모든 쓰기 작업은 실행 전에 HITL 승인이 필요합니다.

### 작업 관리 및 자율성

- 서브태스크와 댓글이 있는 칸반 보드 (PostgreSQL 기반).
- 하트비트 스케줄러: 에이전트가 자동으로 대기 중인 작업을 가져옴 (기본값 5분마다).
- HITL 승인 게이트를 통한 자율 실행 (Telegram `/approve`, GUI 버튼).
- 푸시 알림: Telegram, Home Assistant `notify`, 웹 푸시 (VAPID). 태스크에 `notify_channel` 필드를 지정하면 어떤 세션이 태스크를 생성했는지와 관계없이 완료 메시지가 항상 올바른 브리지로 전달됩니다. 에이전트는 `list_notify_channels()`를 호출하여 런타임에 사용 가능한 채널을 확인할 수 있습니다.

**다일 작업** — 수 시간 또는 수 일에 걸친 장기 작업을 위한 권장 패턴:
1. 채팅, Telegram 또는 GUI 칸반 보드를 통해 제목과 설명이 있는 작업을 만듭니다.
2. 에이전트(또는 사용자)가 `set_subtasks`를 호출하여 명명된 단계로 분할합니다.
3. 각 하트비트 실행은 다음 대기 중인 하위 작업을 가져와 완료하고 중지합니다 — 개별 LLM 세션은 짧고 집중적으로 유지됩니다.
4. 진행 상황, 결정 사항, 중간 결과는 작업 댓글로 저장되어 이후 각 실행이 완전한 컨텍스트를 갖게 됩니다.
5. 모든 하위 작업이 완료되면 에이전트가 작업을 닫고 완료 알림을 보냅니다.

이 패턴은 코드 변경 없이 작동합니다 — `tasks` 도구 소스가 있는 모든 에이전트가 이미 액세스할 수 있는 기존 작업 도구(`set_subtasks`, `get_next_subtask`, `complete_subtask`)를 기반으로 합니다.

### 안전 감독 (쿼드럼비라투스)

실행 전에 위험한 도구 호출을 검사하는 선택적인 에이전트별 레이어. `agents.yaml`에서 `guardian: true`로 활성화합니다. 이 플래그가 없는 에이전트는 영향을 받지 않습니다.

- **가디언(Guardian)** — 도구 이름과 인수를 평가하는 격리된 LLM 호출 (도구 없음). `NONE` (계속), `SOFT VETO: 이유` (인간 결정 필요) 또는 `HARD VETO: 이유` (즉시 차단) 중 하나를 반환합니다.
- **중재자(Arbiter)** — SOFT VETO 시 활성화. Markdown 분석 보고서를 생성하고 LangGraph `interrupt()`로 그래프를 일시 중단합니다. 운영자는 Telegram `/approve` 또는 GUI로 승인하거나 거부합니다 (HITL과 동일한 흐름).
- **역사가(Historian)** — 메모리 내 Guardian 감사 로그를 읽고 구조화된 보고서를 PostgreSQL의 `historian_reports` 테이블에 기록하는 하트비트 작업.
- **위험 분류** — MCP 서버는 `mcps.yaml`에서 `risk: low` 또는 `risk: high`로 태그됩니다. 메모리, 작업, 승인 도구는 위험 수준에 관계없이 항상 검사에서 제외됩니다.

```yaml
# agents.yaml
agents:
  - name: ceo
    guardian: true
    guardian_provider: anthropic        # 선택 — 비어 있으면 에이전트 공급자 상속
    guardian_model: claude-haiku-4-5-20251001
    arbiter_provider: anthropic
    arbiter_model: claude-sonnet-4-6
```

```yaml
# mcps.yaml
servers:
  - name: playwright
    risk: high        # 모든 playwright 도구는 Guardian 승인 필요
  - name: hu-tools
    risk: low         # 날씨, 뉴스 — 검사 없이 통과
```

`/guardian/log` 엔드포인트는 실시간 감사 로그 (최근 1,000개 결정)를 반환합니다.

### 인증 및 멀티 테넌시

| 모드 | 설명 |
|---|---|
| `AUTH_MODE=none` | 개방형 — 인증 없음 (기본값, 로컬 사용 적합) |
| `AUTH_MODE=local` | Bearer 토큰; 사용자는 `LOCAL_USERS=user1:pass1,...`에서 정의 |
| `AUTH_MODE=sso` | Keycloak OIDC/JWT 또는 모든 OIDC 제공자 (Auth0, Okta, Authelia, …) |

**사용자별 격리.** 다중 사용자 모드에서는 각 사용자의 메모리와 지식 그래프가
분리됩니다. 장기 기억은 해당 사용자 전용 Qdrant 컬렉션에, 그래프는 전용 `scope`에
저장되며, 읽기 시에는 자신의 데이터와 관리자가 관리하는 공유 계층만 보이고 다른
사용자의 데이터는 절대 보이지 않습니다. 야간 유지관리도 **사용자별**로 실행됩니다.

### 관찰 가능성

- 턴별 토큰 및 비용 로깅이 포함된 파이프라인 트레이스.
- GUI 모니터링 탭의 워터폴 뷰.
- `TRACE_RETENTION_DAYS`로 제어되는 자동 트레이스 정리.

### 웹훅 수신기

다음에서 서명된 웹훅을 수락합니다: GitHub, Gitea, Drone CI, Grafana, n8n, Slack, ERPNext, Twenty CRM, Zammad, Tiledesk, Uptime Kuma, Wekan, Umami, Duplicati, BorgWarehouse.

### 백업 및 설정 지속성

모든 런타임 데이터는 `data/`에 바인드 마운트로 저장되며, 모든 설정은 YAML 파일에 있습니다 — 컨테이너 내부에 숨겨진 상태 없음.

**백업 생성** (`.env` + `data/` 포함):

```bash
sudo python3 backup.py backup                 # 대화식, 자동 파일명
sudo python3 backup.py backup /srv/backup.tgz # 명시적 출력 경로
```

**복원**:

```bash
python3 backup.py restore /srv/backup.tgz          # 현재 디렉터리에 복원
python3 backup.py restore /srv/backup.tgz /opt/qai # 특정 디렉터리에 복원
```

Linux / macOS에서는 파일 소유권을 보존하기 위해 `sudo`로 실행하세요. Windows에서는 불필요합니다.

---

## 브리지

| 브리지 | 전송 방식 | Compose 프로파일 |
|---|---|---|
| Telegram | Bot API, async (python-telegram-bot) | `telegram` |
| Matrix | matrix-nio, 방 단위 | `matrix` |
| Discord | discord.py, 슬래시 명령 | `discord` |
| IRC | irc3 asyncio, 다중 채널 | `irc` |
| WhatsApp | Meta Cloud API webhook | `whatsapp` |
| Slack | slack-bolt Socket Mode | `slack` |
| Signal | signal-cli REST API 폴링 | `signal` |
| Viber | FastAPI webhook, 키보드 버튼 | `viber` |

모든 브리지가 `/notify` (오케스트레이터의 푸시 알림)와 `/health` (라이브니스 체크)를 노출하며, 발신자 및 채널 허용 목록을 지원합니다. Telegram과 GUI는 HITL `/approve` 플로우도 지원합니다. 모든 브리지는 `/language` 명령을 통한 사용자별 언어 전환을 지원하며 설정은 PostgreSQL에 저장되어 컨테이너 재시작 후에도 유지됩니다.

---

## 음성

### 마이크 브리지 (로컬 마이크)

Compose 프로파일: `mic`

- openWakeWord — 설정 가능한 웨이크 워드 (기본값: "Ok Szif").
- Wyoming Whisper — 로컬 STT, 클라우드 불필요.
- Wyoming Piper — 로컬 TTS.
- Linux 데스크톱용 PulseAudio 소켓 마운트.

**플랫폼 참고 사항:**

- **Linux** — 설치 프로그램이 UID를 감지하여 올바른 PulseAudio 소켓(`/run/user/<uid>/pulse`)을 자동으로 마운트합니다.
- **macOS / Windows** — Docker Desktop은 오디오 장치를 통과시키지 않습니다. 설치 프로그램은 대신 PulseAudio TCP 설정을 작성합니다. mic 컨테이너를 시작하기 전에 PulseAudio를 TCP 모드로 설정하세요:
  - macOS: `brew install pulseaudio && pulseaudio --load=module-native-protocol-tcp --exit-idle-time=-1 --daemon`
  - Windows (WSL2): `sudo apt install pulseaudio && pulseaudio --load=module-native-protocol-tcp --exit-idle-time=-1 --start`
  - Windows (네이티브): PulseAudio for Windows를 다운로드하고, `default.pa`에서 `module-native-protocol-tcp` 주석을 해제하고, 방화벽에서 포트 4713을 허용하세요.

### Home Assistant Voice PE

Compose 프로파일: `ha`

QuorumAI가 Home Assistant에 대화 에이전트로 등록됩니다. HA Assist가 웨이크 워드 감지, Whisper STT, Piper TTS를 HA 측에서 처리하며; QuorumAI가 추론 및 도구 호출을 담당합니다.

### STT 및 TTS 도구 (에이전트 호출 가능)

Compose 프로파일: `stt-tts`

에이전트가 `system-stt` 및 `system-tts` 도구로 호출할 수 있는 HTTP API로 Whisper와 Piper를 노출합니다.

---

## GUI

Compose 프로파일: `gui` — `http://localhost:3000`에서 접속

React, Vite, Tailwind CSS로 구축.

| 탭 | 설명 |
|---|---|
| 채팅 | 에이전트에 메시지 전송; 스트리밍 응답 확인 |
| 에이전트 빌더 | 시각적 회사 다이어그램; 에이전트와 역할 생성 및 편집 |
| 스킬 편집기 | Markdown 스킬 파일 생성 및 관리 |
| 작업 | 칸반 보드; 하위 작업 트리; 댓글; 승인 버튼 |
| 제공자 | 실시간 제공자 상태 및 사용 가능한 모델 목록 |
| 하트비트 | 스케줄러 상태; 다음 실행 시간; 수동 트리거 |
| 관찰 가능성 | 파이프라인 트레이스; 토큰 및 비용 워터폴 뷰 |

- 16개 UI 언어, 14개 테마.
- 채팅 및 작업 탭에 HITL 승인 버튼 통합.

---

## 설치 세부 정보

### 사전 요구 사항

- Docker Engine 24+ 및 Docker Compose v2.
- `install.py`용 Python 3.8+ — pip 또는 virtualenv 불필요.
- 로컬 모델의 경우: 호스트의 포트 11434에서 실행 중인 Ollama.

### 공유 네트워크 생성 (호스트당 한 번)

```bash
docker network create quorum-net
```

### 프로파일 선택

`.env`에서 프로파일을 설정하면 `docker compose up -d`만으로 실행됩니다:

```env
COMPOSE_PROFILES=orchestrator,memory,mcp,postgres,telegram,gui
```

또는 명시적으로 전달:

```bash
docker compose --profile orchestrator --profile memory --profile gui up -d
```

사용 가능한 프로파일: `orchestrator`, `memory`, `mcp`, `postgres`, `telegram`, `ha`, `mic`, `gui`, `stt-tts`, `mcp-manager`, `playwright`, `joplin`, `auth`, `email`, `matrix`, `discord`, `irc`, `whatsapp`, `slack`, `signal`, `viber`, `graph`

### 소스 변경 후 재빌드

```bash
# 변경된 서비스만 재빌드:
docker compose build orchestrator

# 다른 컨테이너를 건드리지 않고 재시작:
docker compose up -d --no-deps orchestrator
```

### 데이터 디렉토리 레이아웃

```
data/
  qdrant/        # Qdrant 벡터
  postgres/      # PostgreSQL 데이터
  workspace/     # 에이전트별 파일 작업 공간
  whisper/       # Whisper 모델 캐시
  piper/         # Piper 음성 파일
  ...
```

`data/` 아래의 모든 것은 gitignore됩니다. 이 디렉토리를 백업하면 모든 영구 상태가 보존됩니다.

---

## 구성

`.env.example`을 `.env`로 복사하고 필요한 내용을 채우세요. `.env.example` 파일에는 모든 키에 대한 인라인 문서가 포함되어 있습니다.

### 주요 키

| 키 | 기본값 | 설명 |
|---|---|---|
| `COMPOSE_PROFILES` | — | 시작할 프로파일, 쉼표로 구분 |
| `AUTH_MODE` | `none` | `none` / `local` / `sso` |
| `ORCHESTRATOR_PORT` | `8000` | 오케스트레이터 FastAPI 포트 |
| `GUI_PORT` | `3000` | GUI 포트 |
| `QDRANT_HTTP_PORT` | `6333` | Qdrant REST 포트 |
| `POSTGRES_PORT` | `5433` | PostgreSQL 포트 |
| `POSTGRES_PASSWORD` | `changeme` | PostgreSQL 비밀번호 — 변경 필수 |
| `TRACE_RETENTION_DAYS` | `14` | N일보다 오래된 트레이스 자동 삭제 |
| `ANTHROPIC_API_KEY` | — | Anthropic 제공자 사용 시 필요 |
| `OPENROUTER_API_KEY` | — | OpenRouter 사용 시 필요 |
| `OPENAI_API_KEY` | — | OpenAI 사용 시 필요 |
| `GOOGLE_API_KEY` | — | Google Gemini 사용 시 필요 |
| `TELEGRAM_BOT_TOKEN` | — | Telegram 브리지에 필요 |
| `TELEGRAM_CHAT_ID` | — | 메시지를 수락할 Telegram 채팅 ID |
| `NOTIFY_TELEGRAM_CHAT_ID` | — | 태스크 완료 알림용 채팅 ID (`TELEGRAM_CHAT_ID`와 동일하면 생략 가능) |
| `MATRIX_HOMESERVER` | — | Matrix 서버 URL |
| `MATRIX_ACCESS_TOKEN` | — | Matrix 봇 액세스 토큰 |
| `DISCORD_BOT_TOKEN` | — | Discord 브리지에 필요 |
| `SLACK_BOT_TOKEN` | — | Slack 브리지에 필요 |
| `SLACK_APP_TOKEN` | — | Slack Socket Mode에 필요 |
| `SIGNAL_PHONE` | — | Signal 브리지용 전화번호 |
| `VIBER_AUTH_TOKEN` | — | Viber 브리지에 필요 |
| `HA_URL` | `http://homeassistant:8123` | Home Assistant 기본 URL |
| `HA_TOKEN` | — | HA 장기 액세스 토큰 |
| `IMAP_HOST` | — | 이메일 MCP용 IMAP 서버 |
| `SMTP_HOST` | — | 이메일 MCP용 SMTP 서버 |
| `FALKORDB_URL` | — | 지식 그래프 활성화 시 설정 |
| `VAPID_EMAIL` | — | 웹 푸시 알림에 필요 |
| `VAPID_PRIVATE_KEY` | — | 설치 프로그램이 자동 생성 (`cryptography` Python 패키지 필요); 또는 `docker compose exec orchestrator python3 webpush.py` 실행 |
| `VAPID_PUBLIC_KEY` | — | 개인 키와 함께 생성 |
| `HU_TOOLS_PORT` | `4300` | hu-tools MCP 포트 |
| `WHISPER_URL` | `http://whisper-http:8000` | STT 서비스 URL |
| `PIPER_URL` | `http://piper-http:5000` | TTS 서비스 URL |
| `ORCHESTRATOR_API_KEY` | — | 설치 프로그램이 자동 생성; 브리지용 서비스 간 토큰 (`AUTH_MODE=local/sso` 시 필요) |
| `CONVERSATION_API_KEY` | — | 설치 프로그램이 자동 생성; HA `/conversation` 엔드포인트 보호 (비어 있으면 = 개방) |

에이전트 구성은 `orchestrator/agents.yaml`에 있습니다 — `.env`가 아닙니다.

---

## 산업 팩

특정 산업을 위한 사전 구축된 수직 패키지입니다. 각 팩에는 스킬 파일, 권장 에이전트 구성 및 MCP 참조가 포함됩니다. `install.py`를 통해 또는 수동으로 설치합니다.

| 팩 | 대상 | 주요 스킬 |
|---|---|---|
| `legal` | 법률 사무소 | 문서 검색, 계약 분석, 헝가리 법률 검색 |
| `devops` | IT/DevOps 기업 | 인시던트 분류, 런북 검색, HITL 포함 AIOps |
| `agency` | 마케팅 및 PR 에이전시 | 프로젝트 상태, 리드 자격 심사, 브리프 분석, 클라이언트 리포팅 |

**수동 설치:**
```bash
cp industry-packs/legal/skills/*.md data/skills/
cat industry-packs/legal/agents.yaml
```

**설치 프로그램을 통해:** `python3 install.py` → 수정 → 산업 팩 선택.

직접 팩을 만들려면 `industry-packs/_template/`를 복사하고 `pack.yaml`을 채우세요.

---

## CRM 통합

CRM MCP(`mcps/crm/`)는 교체 가능한 어댑터 아키텍처를 통해 여러 CRM 시스템에 통합 인터페이스를 제공합니다. 에이전트는 백엔드에 관계없이 동일한 도구를 사용합니다.

**지원 어댑터:**

| 어댑터 | 시스템 | 유형 |
|---|---|---|
| `minicrm` | MiniCRM (헝가리 시장 선도) | 전체 |
| `hubspot` | HubSpot CRM | 전체 |
| `pipedrive` | Pipedrive | 전체 |
| `billingo` | Billingo 인보이싱 | 읽기 전용 |
| `szamlazzhu` | Számlázz.hu 인보이싱 | 읽기 전용 |
| `salesautopilot` | SalesAutopilot (헝가리 마케팅 자동화) | 전체 |

**사용 가능한 도구:** `search_entities`, `get_entity`, `create_entity`, `update_entity`, `add_note`, `get_timeline`, `link_entities`, `get_related`, `emit_event`, `list_entity_types`

**빠른 시작:**
```env
CRM_ADAPTER=minicrm
MINICRM_SYSTEM_ID=12345
MINICRM_API_KEY=your-key
```

```bash
docker compose --profile crm up -d
```

에이전트에 CRM 액세스를 부여하려면 `agents.yaml`의 에이전트 `tools:` 목록에 `crm`을 추가하세요.

---

## jog.gov.hu MCP — 헝가리 법률 검색

jog.gov.hu MCP(`mcps/jog-hu/`)는 두 가지 배포 모드로 AI 에이전트에 헝가리 법률 정보를 제공합니다:

**Docker 모드** (항상 작동, Playwright 불필요):

| 도구 | 설명 |
|---|---|
| `search_njt_laws(keywords)` | njt.jog.gov.hu에서 키워드 검색 — 일치하는 법률 제목과 URL 반환 |
| `get_law_text(law_id, section)` | njt.hu에서 전체 또는 부분 법률 텍스트 (예: `"2012. évi I. törvény"`, 섹션 `"69"`) |
| `list_recent_laws(category, days)` | Magyar Közlöny RSS 피드에서 최근 법률 |

**호스트 모드** (AI 기반 검색, 호스트 머신에서 `host_server.py` 실행 필요):

| 도구 | 설명 |
|---|---|
| `search_law(question)` | 자연어 질문 → AI 답변 + 인용된 법률 참조 (jog.gov.hu) |

reCAPTCHA v3는 주로 **IP 평판**을 기준으로 세션을 평가합니다. Docker 컨테이너 IP와 클라우드/VPS 서버 IP는 데이터센터 대역으로 분류되어 낮은 신뢰 점수를 받습니다 — 브라우저 지문 패치 여부와 관계없이 동일합니다. **일반 가정 또는 사무실 네트워크**의 IP를 사용하는 머신은 통과에 충분히 높은 점수를 받습니다. 그래픽 디스플레이는 **필요하지 않습니다** — 브라우저는 헤드리스로 실행되며 디스플레이는 무관합니다.

**빠른 시작 (Docker 도구 — 항상 작동):**
```bash
docker compose --profile jog-hu up -d
```

**호스트 서버 시작 (AI 검색 — 일반 가정/사무실 IP 필요):**
```bash
# 작동하는 환경: 가정/사무실 데스크톱 또는 노트북 (Windows, macOS, Linux)
# 작동하지 않는 환경: 클라우드/VPS 서버 (데이터센터 IP는 reCAPTCHA에 의해 차단됨)
# 그래픽 디스플레이 불필요 — 헤드리스로 실행됨

pip install mcp fastmcp httpx playwright playwright-stealth
playwright install chromium

python3 mcps/jog-hu/host_server.py --background   # 데몬 시작, 포트 4312
python3 mcps/jog-hu/host_server.py --stop          # 데몬 중지
```

**`mcps.yaml`에 추가:**
```yaml
- name: jog-hu
  url: http://jog-hu-mcp:4302/mcp/
  description: Hungarian legal search (njt.hu)

# 선택 사항 — host_server.py가 실행 중인 경우에만:
- name: jog-hu-host
  url: http://host.docker.internal:4312/mcp/
  description: Hungarian legal AI search (jog.gov.hu)
```

에이전트에 법률 검색 액세스를 부여하려면 `agents.yaml`의 에이전트 `tools:` 목록에 `jog-hu` (선택적으로 `jog-hu-host`도)를 추가하세요.

---

## 기여하기

1. 리포지토리를 포크하고 기능 브랜치를 생성합니다.
2. `CLAUDE.md`의 레이어 및 compose 규칙을 따릅니다.
3. `tests.sh`에 해당하는 테스트 블록을 추가하거나 업데이트합니다.
4. 추가되는 단계나 기능에 대한 설명과 함께 풀 리퀘스트를 엽니다.

---

## 라이선스
