[English](README.md) | [Magyar](README.hu.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Русский](README.ru.md) | [Nederlands](README.nl.md) | [Polski](README.pl.md) | [Українська](README.uk.md) | [Svenska](README.sv.md) | [Italiano](README.it.md) | [日本語](README.ja.md) | [中文](README.zh.md) | [한국어](README.ko.md) | [Kiswahili](README.sw.md)

# QuorumAI

O QuorumAI é um sistema modular de orquestração de múltiplos agentes de IA, auto-hospedado e construído sobre o LangGraph. Funciona inteiramente no Docker, conecta-se a todas as principais plataformas de mensagens, suporta interação por voz, controle de casa inteligente e simula uma «empresa» de IA com vários papéis, com memória de longo prazo e execução autônoma de tarefas.

![Python 3.11](https://img.shields.io/badge/Python-3.11-blue.svg) ![Docker](https://img.shields.io/badge/Docker-Compose-2496ED.svg)

---

## O que é o QuorumAI

O QuorumAI transforma um ou mais LLMs em uma equipe de agentes de IA capazes de:

- Responder perguntas, ler notícias e controlar dispositivos domóticos — acionados por microfone, Telegram, Matrix, Discord, Slack, Signal, WhatsApp, Viber ou IRC.
- Delegar trabalho entre papéis especializados (CEO, desenvolvedor, vendas) e manter memória de longo prazo entre sessões usando busca vetorial do Qdrant.
- Executar tarefas de forma autônoma via um agendador heartbeat, solicitar aprovação humana quando necessário (HITL) e expor cada capacidade externa como servidor MCP (Model Context Protocol).

Tudo é configurado em YAML. Não são necessárias alterações de código para trocar modelos, adicionar agentes ou conectar novas ferramentas.

---

## Instalação rápida

### Uma linha (recomendado)

O instalador bootstrap verifica se Python 3 e Docker estão instalados, instala-os se necessário e executa o instalador interativo do QuorumAI.

**Linux / macOS:**
```bash
curl -fsSL https://raw.githubusercontent.com/fulopjozsef86/QuorumAI/main/install.sh | bash
```

**Windows (PowerShell — executar como Administrador):**
```powershell
irm https://raw.githubusercontent.com/fulopjozsef86/QuorumAI/main/install.ps1 | iex
```

Ou baixe `install.bat` / `install.ps1` do repositório e dê um duplo clique.

> **Nota:** No Linux, o bootstrap instala o Docker Engine a partir do repositório oficial do Docker (apt/dnf/yum conforme a distribuição) e adiciona o seu utilizador ao grupo `docker`. É necessário terminar sessão e iniciar novamente. No macOS e Windows instala o Docker Desktop e solicita que o inicie antes de continuar.

---

### Já tem Python 3 e Docker?

Clone o repositório e execute o instalador interativo diretamente — não é necessário pip nem dependências adicionais:

```bash
git clone https://github.com/fulopjozsef86/QuorumAI.git
cd QuorumAI
python3 install.py
```

O instalador:
- Apresenta um seletor interativo de módulos (orchestrator, bridges, voz, GUI e mais).
- Escreve `.env` com as suas respostas, cria diretórios bind-mount `data/` e executa `docker compose up -d`.
- A interface do instalador está disponível em 16 idiomas.

**Modo Satellite** — executar microfone, bridges ou servidores MCP numa máquina separada:
```bash
python3 install.py   # escolha "Satellite" quando solicitado
```

---

## Início rápido (manual)

```bash
git clone https://github.com/your-org/QuorumAI.git
cd QuorumAI

# Criar a rede Docker compartilhada (uma vez por host):
docker network create quorum-net

cp .env.example .env
# Edite .env — defina COMPOSE_PROFILES e as chaves API necessárias

docker compose up -d
```

Verificar se o orquestrador está a funcionar:

```bash
curl http://localhost:8000/health
```

Enviar uma mensagem de teste:

```bash
curl -X POST http://localhost:8000/invoke \
  -H 'Content-Type: application/json' \
  -d '{"message": "Hello, introduce yourself."}'
```

Interface gráfica: `http://localhost:3000`

---

## Arquitetura

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

Cada camada vive em seu próprio diretório com seu próprio `compose.yml`. O `compose.yml` raiz agrega todas as camadas via `include:` e perfis do Docker Compose — você inicia apenas o que precisa.

---

## Funcionalidades

### Orquestração principal

- **Runtime LangGraph** — grafo de agentes de máquina de estados, checkpointing HITL nativo, `AsyncPostgresSaver`.
- **API HTTP FastAPI** — `POST /invoke`, `GET /health`, streaming, receptor de webhooks, retransmissão de notificações push.
- **agents.yaml** — declare agentes em YAML: nome, papel, provedor, modelo, caminho do prompt de sistema, ferramentas.
- **Recarga a quente** — `POST /agents/reload` recarrega `agents.yaml` sem reiniciar o contêiner.
- **Protocolo de ferramentas MCP** — cada capacidade externa é um servidor MCP; os agentes descobrem ferramentas automaticamente.
- **Memória vetorial Qdrant** — busca híbrida semântica + BM42 lexical, embeddings multilingual-e5-large, coleções por agente, deduplicação por cosseno, recuperação diversificada por MMR.
- **Consolidação de memória noturna** — tarefa de «sonho» agendada que destila o histórico de sessões do PostgreSQL em fatos Qdrant de longo prazo; mescla progressões, remove entradas efêmeras obsoletas; estado rastreado no PostgreSQL.
- **PostgreSQL** — checkpointer `AsyncPostgresSaver` + tabelas de tarefas e comentários.
- **Grafo de conhecimento** — FalkorDB (compatível com Redis), consultas Cypher por usuário, extração automática de entidades.

### Provedores LLM (por agente, configurados em agents.yaml)

| Local | Nuvem |
|---|---|
| Ollama (padrão, sem chave) | Anthropic Claude |
| llama.cpp | OpenAI |
| LM Studio | OpenRouter |
| vLLM | Google Gemini |
| Docker Model Runner | Grok (xAI) |
| Unsloth Studio | DeepSeek |
| | Mistral AI |
| | Together AI |
| | Fireworks AI |
| | Zhipu AI / Z.AI |
| | Eden AI (agregador) |
| | NVIDIA NIM (nível gratuito disponível) |

Não é necessária nenhuma chave API para começar — o Ollama funciona localmente e gratuitamente.

**Pools de provedores** — vários servidores locais idênticos (ex.: seis máquinas Ollama) podem ser agrupados em um pool com nome. O orquestrador distribui as solicitações com balanceamento least-connections; se todos os membros do pool falharem, volta à cadeia de fallback normal. Configurado em `providers.yaml` e gerenciável pela aba Provedores da GUI.

### Simulação de empresa multi-agente

- Agentes baseados em papéis: CEO, desenvolvedor, vendas e qualquer papel personalizado.
- O agente dispatcher direciona automaticamente as solicitações ao especialista correto.
- Agentes pipeline: loops planejador → executor → revisor com estado compartilhado.
- **Agentes autônomos (Deep)** — defina `deep: true` em qualquer agente ou fase de pipeline para ativar o loop ReAct LangGraph integrado. O agente planeja, executa e itera autonomamente — chamando ferramentas repetidamente até a tarefa ser concluída ou o limite opcional de chamadas de ferramentas ser atingido (`deep_max_steps`, 0 = ilimitado). Configurável por agente e por fase de pipeline; botão disponível no GUI Agent Builder.
- Biblioteca de habilidades: arquivos Markdown de habilidades, carregamento lazy por agente, mercado comunitário para compartilhamento.
- Espaço de trabalho compartilhado: os agentes podem ler e escrever em uma área de ficheiros compartilhada.
- **Ferramentas de administração** — agentes com o papel `admin` podem criar e excluir agentes, skills, servidores MCP, cron jobs e agendamentos heartbeat em tempo de execução via ferramentas `system-admin`. Cada ação de escrita requer aprovação HITL antes da execução.

### Gestão de tarefas e autonomia

- Quadro Kanban com subtarefas e comentários (baseado em PostgreSQL).
- Agendador heartbeat: os agentes pegam tarefas pendentes automaticamente (a cada 5 minutos por padrão).
- Execução autônoma com pontos de aprovação HITL (Telegram `/approve`, botões GUI).
- Notificações push: Telegram, Home Assistant `notify`, web push (VAPID). As tarefas podem especificar um campo `notify_channel` para que a mensagem de conclusão vá sempre para o bridge correto, independentemente de qual sessão criou a tarefa. Os agentes podem chamar `list_notify_channels()` para descobrir os canais disponíveis em tempo de execução.

**Tarefas de vários dias** — o padrão recomendado para trabalhos de longa duração que abrangem horas ou dias:
1. Crie uma tarefa com título e descrição (via chat, Telegram ou o quadro Kanban da GUI).
2. O agente (ou você) chama `set_subtasks` para dividi-la em etapas nomeadas.
3. Cada execução do heartbeat pega a próxima subtarefa pendente, conclui-a e para — as sessões LLM individuais permanecem curtas e focadas.
4. O progresso, decisões e resultados intermediários são armazenados como comentários de tarefa para que cada execução seguinte tenha contexto completo do que aconteceu antes.
5. Quando todas as subtarefas estão concluídas, o agente fecha a tarefa e envia uma notificação de conclusão.

Este padrão funciona sem alterações de código — baseia-se nas ferramentas de tarefas existentes (`set_subtasks`, `get_next_subtask`, `complete_subtask`) às quais qualquer agente com a fonte de ferramentas `tasks` já tem acesso.

### Supervisão de segurança (Quadrumvirato)

Uma camada opcional por agente que verifica cada chamada de ferramenta de risco antes de ser executada. Ativada com `guardian: true` em `agents.yaml`; agentes sem este indicador não são afetados.

- **Guardian** — uma chamada LLM isolada (sem ferramentas) que avalia o nome e os argumentos da ferramenta e retorna: `NONE` (continuar), `SOFT VETO: motivo` (decisão humana necessária) ou `HARD VETO: motivo` (bloqueio imediato).
- **Árbitro** — ativado em SOFT VETO; gera um relatório de análise Markdown e suspende o grafo via LangGraph `interrupt()`. O operador aprova ou rejeita via Telegram `/approve` ou a GUI — mesmo fluxo que o HITL.
- **Historiador** — uma tarefa heartbeat que lê o log de auditoria Guardian em memória e escreve um relatório estruturado na tabela PostgreSQL `historian_reports`.
- **Classificação de risco** — os servidores MCP recebem a etiqueta `risk: low` ou `risk: high` em `mcps.yaml`. As ferramentas de memória, tarefas e aprovação estão sempre excluídas do controlo.

```yaml
# agents.yaml
agents:
  - name: ceo
    guardian: true
    guardian_provider: anthropic        # opcional — herda o fornecedor do agente se vazio
    guardian_model: claude-haiku-4-5-20251001
    arbiter_provider: anthropic
    arbiter_model: claude-sonnet-4-6
```

```yaml
# mcps.yaml
servers:
  - name: playwright
    risk: high        # todas as ferramentas playwright requerem aprovação do Guardian
  - name: hu-tools
    risk: low         # clima, notícias — transmitidos sem controlo
```

O endpoint `/guardian/log` devolve o log de auditoria em tempo real (últimas 1 000 decisões).

### Autenticação e multi-tenancy

| Modo | Descrição |
|---|---|
| `AUTH_MODE=none` | Aberto — sem autenticação (padrão, adequado para uso local) |
| `AUTH_MODE=local` | Token Bearer; usuários definidos em `LOCAL_USERS=usuario1:senha1,...` |
| `AUTH_MODE=sso` | Keycloak OIDC/JWT ou qualquer provedor OIDC (Auth0, Okta, Authelia, …) |

**Isolamento por utilizador.** Em modo multiutilizador, a memória e o grafo
de conhecimento de cada utilizador estão separados: a memória de longo prazo vai
para a sua própria coleção Qdrant e o grafo para o seu próprio `scope` — uma
leitura vê os seus próprios dados e a camada comum curada pelo administrador,
nunca os de outro utilizador. A manutenção noturna também corre **por
utilizador**.

### Observabilidade

- Traces de pipeline com registo de tokens e custos por turno.
- Vista em cascata na aba Monitorização da GUI.
- Limpeza automática de traces controlada por `TRACE_RETENTION_DAYS`.

### Receptor de webhooks

Aceita webhooks assinados de: GitHub, Gitea, Drone CI, Grafana, n8n, Slack, ERPNext, Twenty CRM, Zammad, Tiledesk, Uptime Kuma, Wekan, Umami, Duplicati, BorgWarehouse.

### Backup e persistência de configuração

Todos os dados de execução ficam em `data/` como bind mounts; toda a configuração em arquivos YAML — sem estado oculto dentro dos contêineres.

**Criar backup** (inclui `.env` + `data/`):

```bash
sudo python3 backup.py backup                    # interativo, nome de arquivo automático
sudo python3 backup.py backup /srv/backup.tgz    # caminho de saída explícito
```

**Restaurar**:

```bash
python3 backup.py restore /srv/backup.tgz           # restaurar no diretório atual
python3 backup.py restore /srv/backup.tgz /opt/qai  # restaurar em diretório específico
```

No Linux / macOS executar com `sudo` para preservar a propriedade dos arquivos. No Windows não é necessário.

---

## Bridges

| Bridge | Transporte | Perfil Compose |
|---|---|---|
| Telegram | Bot API, async (python-telegram-bot) | `telegram` |
| Matrix | matrix-nio, nível de sala | `matrix` |
| Discord | discord.py, slash commands | `discord` |
| IRC | irc3 asyncio, multi-canal | `irc` |
| WhatsApp | Meta Cloud API webhook | `whatsapp` |
| Slack | slack-bolt Socket Mode | `slack` |
| Signal | signal-cli REST API polling | `signal` |
| Viber | FastAPI webhook, botões de teclado | `viber` |

Cada bridge expõe `/notify` (para notificações push do orquestrador) e `/health` (vivacidade), e suporta listas de permissão para remetentes e canais. Telegram e a GUI também suportam o fluxo HITL `/approve`. Todos os bridges suportam troca de idioma por usuário via o comando `/language`; a preferência é armazenada no PostgreSQL e sobrevive a reinicializações de containers.

---

## Voz

### Bridge de microfone (microfone local)

Perfil Compose: `mic`

- openWakeWord — palavra de ativação configurável (padrão: "Ok Szif").
- Wyoming Whisper — STT local, sem nuvem.
- Wyoming Piper — TTS local.
- Montagem de socket PulseAudio para desktops Linux.

**Notas de plataforma:**

- **Linux** — o instalador deteta o seu UID e monta automaticamente o socket PulseAudio correto (`/run/user/<uid>/pulse`).
- **macOS / Windows** — o Docker Desktop não passa dispositivos de áudio. O instalador escreve uma configuração TCP do PulseAudio em alternativa. Configure o PulseAudio em modo TCP antes de iniciar o contentor mic:
  - macOS: `brew install pulseaudio && pulseaudio --load=module-native-protocol-tcp --exit-idle-time=-1 --daemon`
  - Windows (WSL2): `sudo apt install pulseaudio && pulseaudio --load=module-native-protocol-tcp --exit-idle-time=-1 --start`
  - Windows (nativo): transfira o PulseAudio para Windows, descomente `module-native-protocol-tcp` em `default.pa`, permita a porta 4713 na firewall.

### Home Assistant Voice PE

Perfil Compose: `ha`

O QuorumAI regista-se como agente de conversação no Home Assistant. O HA Assist trata da deteção de palavra de ativação, Whisper STT e Piper TTS do lado do HA; o QuorumAI trata do raciocínio e das chamadas de ferramentas.

### Ferramentas STT e TTS (chamáveis por agentes)

Perfil Compose: `stt-tts`

Expõe o Whisper e o Piper como APIs HTTP que os agentes podem chamar como ferramentas `system-stt` e `system-tts`.

---

## Interface gráfica

Perfil Compose: `gui` — disponível em `http://localhost:3000`

Construída com React, Vite e Tailwind CSS.

| Aba | Descrição |
|---|---|
| Chat | Enviar mensagens a qualquer agente; ver respostas em streaming |
| Agent Builder | Diagrama visual da empresa; criar e editar agentes e seus papéis |
| Skill Editor | Criar e gerir ficheiros Markdown de habilidades |
| Tasks | Quadro Kanban; árvore de subtarefas; comentários; botões de aprovação |
| Providers | Estado em tempo real dos provedores e lista de modelos disponíveis |
| Heartbeat | Estado do agendador; próximos horários de execução; acionamento manual |
| Observabilidade | Traces de pipeline; vista em cascata de tokens e custos |

- 16 idiomas de interface, 14 temas.
- Botões de aprovação HITL integrados nas abas Chat e Tasks.

---

## Detalhes de instalação

### Pré-requisitos

- Docker Engine 24+ e Docker Compose v2.
- Python 3.8+ para `install.py` — sem pip ou virtualenv necessários.
- Para modelos locais: Ollama a correr no host na porta 11434.

### Criar a rede compartilhada (uma vez por host)

```bash
docker network create quorum-net
```

### Selecionar perfis

Defina os perfis no `.env` para que o simples `docker compose up -d` funcione:

```env
COMPOSE_PROFILES=orchestrator,memory,mcp,postgres,telegram,gui
```

Ou passe-os explicitamente:

```bash
docker compose --profile orchestrator --profile memory --profile gui up -d
```

Perfis disponíveis: `orchestrator`, `memory`, `mcp`, `postgres`, `telegram`, `ha`, `mic`, `gui`, `stt-tts`, `mcp-manager`, `playwright`, `joplin`, `auth`, `email`, `matrix`, `discord`, `irc`, `whatsapp`, `slack`, `signal`, `viber`, `graph`

### Reconstruir após alterações no código fonte

```bash
# Reconstruir apenas o serviço alterado:
docker compose build orchestrator

# Reiniciar sem tocar nos outros contêineres:
docker compose up -d --no-deps orchestrator
```

### Estrutura do diretório de dados

```
data/
  qdrant/        # Vetores Qdrant
  postgres/      # Dados PostgreSQL
  workspace/     # Espaço de trabalho de ficheiros por agente
  whisper/       # Cache do modelo Whisper
  piper/         # Ficheiros de voz Piper
  ...
```

Tudo em `data/` está no gitignore. Fazer backup deste diretório preserva todo o estado persistente.

---

## Configuração

Copie `.env.example` para `.env` e preencha o que necessitar. O ficheiro `.env.example` contém documentação inline para cada chave.

### Chaves mais importantes

| Chave | Padrão | Descrição |
|---|---|---|
| `COMPOSE_PROFILES` | — | Perfis a iniciar, separados por vírgulas |
| `AUTH_MODE` | `none` | `none` / `local` / `sso` |
| `ORCHESTRATOR_PORT` | `8000` | Porta FastAPI do orquestrador |
| `GUI_PORT` | `3000` | Porta da GUI |
| `QDRANT_HTTP_PORT` | `6333` | Porta REST do Qdrant |
| `POSTGRES_PORT` | `5433` | Porta do PostgreSQL |
| `POSTGRES_PASSWORD` | `changeme` | Senha do PostgreSQL — altere! |
| `TRACE_RETENTION_DAYS` | `14` | Exclusão automática de traces com mais de N dias |
| `ANTHROPIC_API_KEY` | — | Necessário para provedor Anthropic |
| `OPENROUTER_API_KEY` | — | Necessário para OpenRouter |
| `OPENAI_API_KEY` | — | Necessário para OpenAI |
| `GOOGLE_API_KEY` | — | Necessário para Google Gemini |
| `TELEGRAM_BOT_TOKEN` | — | Necessário para bridge Telegram |
| `TELEGRAM_CHAT_ID` | — | ID do chat Telegram a aceitar mensagens |
| `NOTIFY_TELEGRAM_CHAT_ID` | — | ID do chat para notificações de conclusão de tarefas (igual a `TELEGRAM_CHAT_ID` se for o mesmo) |
| `MATRIX_HOMESERVER` | — | URL do servidor Matrix |
| `MATRIX_ACCESS_TOKEN` | — | Token de acesso do bot Matrix |
| `DISCORD_BOT_TOKEN` | — | Necessário para bridge Discord |
| `SLACK_BOT_TOKEN` | — | Necessário para bridge Slack |
| `SLACK_APP_TOKEN` | — | Necessário para Slack Socket Mode |
| `SIGNAL_PHONE` | — | Número de telefone para bridge Signal |
| `VIBER_AUTH_TOKEN` | — | Necessário para bridge Viber |
| `HA_URL` | `http://homeassistant:8123` | URL base do Home Assistant |
| `HA_TOKEN` | — | Token de acesso de longa duração HA |
| `IMAP_HOST` | — | Servidor IMAP para Email MCP |
| `SMTP_HOST` | — | Servidor SMTP para Email MCP |
| `FALKORDB_URL` | — | Definir para ativar o grafo de conhecimento |
| `VAPID_EMAIL` | — | Necessário para notificações web push |
| `VAPID_PRIVATE_KEY` | — | Gerado automaticamente pelo instalador (requer o pacote Python `cryptography`); caso contrário: `docker compose exec orchestrator python3 webpush.py` |
| `VAPID_PUBLIC_KEY` | — | Gerado juntamente com a chave privada |
| `HU_TOOLS_PORT` | `4300` | Porta do MCP hu-tools |
| `WHISPER_URL` | `http://whisper-http:8000` | URL do serviço STT |
| `PIPER_URL` | `http://piper-http:5000` | URL do serviço TTS |
| `ORCHESTRATOR_API_KEY` | — | Gerado automaticamente pelo instalador; token serviço-a-serviço para bridges (obrigatório em `AUTH_MODE=local/sso`) |
| `CONVERSATION_API_KEY` | — | Gerado automaticamente pelo instalador; protege o endpoint HA `/conversation` (vazio = aberto) |

A configuração de agentes é feita em `orchestrator/agents.yaml` — não no `.env`.

---

## Pacotes setoriais

Pacotes verticais pré-construídos para setores específicos. Cada pacote contém ficheiros de habilidades, configurações de agentes sugeridas e referências MCP. Instalados via `install.py` ou manualmente.

| Pacote | Alvo | Habilidades principais |
|---|---|---|
| `legal` | Escritórios de advocacia | Pesquisa de documentos, análise de contratos, pesquisa jurídica húngara |
| `devops` | Empresas de TI/DevOps | Triagem de incidentes, pesquisa de runbook, AIOps com HITL |
| `agency` | Agências de marketing e RP | Status de projeto, qualificação de leads, análise de briefs, relatórios de clientes |

**Instalação manual:**
```bash
cp industry-packs/legal/skills/*.md data/skills/
cat industry-packs/legal/agents.yaml
```

**Via instalador:** execute novamente `python3 install.py` → Modificar → selecionar um pacote setorial.

Crie o seu próprio pacote copiando `industry-packs/_template/` e preenchendo `pack.yaml`.

---

## Integração CRM

O MCP CRM (`mcps/crm/`) fornece uma interface unificada para múltiplos sistemas CRM através de uma arquitetura de adaptadores intercambiáveis. Os agentes usam as mesmas ferramentas independentemente do backend.

**Adaptadores suportados:**

| Adaptador | Sistema | Tipo |
|---|---|---|
| `minicrm` | MiniCRM (líder de mercado húngaro) | Completo |
| `hubspot` | HubSpot CRM | Completo |
| `pipedrive` | Pipedrive | Completo |
| `billingo` | Faturação Billingo | Somente leitura |
| `szamlazzhu` | Faturação Számlázz.hu | Somente leitura |
| `salesautopilot` | SalesAutopilot (automação de marketing HU) | Completo |

**Ferramentas disponíveis:** `search_entities`, `get_entity`, `create_entity`, `update_entity`, `add_note`, `get_timeline`, `link_entities`, `get_related`, `emit_event`, `list_entity_types`

**Início rápido:**
```env
CRM_ADAPTER=minicrm
MINICRM_SYSTEM_ID=12345
MINICRM_API_KEY=sua-chave
```

```bash
docker compose --profile crm up -d
```

Adicione `crm` à lista `tools:` de um agente em `agents.yaml` para lhe dar acesso ao CRM.

---

## jog.gov.hu MCP — Pesquisa jurídica húngara

O MCP jog.gov.hu (`mcps/jog-hu/`) fornece informação jurídica húngara a agentes de IA em dois modos de implantação:

**Modo Docker** (funciona sempre, sem Playwright necessário):

| Ferramenta | Descrição |
|---|---|
| `search_njt_laws(keywords)` | Pesquisa por palavras-chave em njt.jog.gov.hu — devolve títulos e URLs de leis correspondentes |
| `get_law_text(law_id, section)` | Texto completo ou parcial de uma lei em njt.hu (ex.: `"2012. évi I. törvény"`, secção `"69"`) |
| `list_recent_laws(category, days)` | Leis recentes do feed RSS Magyar Közlöny |

**Modo Host** (pesquisa com IA, requer executar `host_server.py` na máquina anfitriã):

| Ferramenta | Descrição |
|---|---|
| `search_law(question)` | Pergunta em linguagem natural → resposta da IA + referências de leis citadas (jog.gov.hu) |

O reCAPTCHA v3 avalia as sessões principalmente pela **reputação do IP**. Os IPs de contêineres Docker e de servidores cloud/VPS são classificados como intervalos de datacenter e recebem uma pontuação de confiança baixa — independentemente de ajustes à impressão digital do navegador. Uma máquina doméstica ou de escritório com um **IP residencial** pontua suficientemente alto para passar. Não é necessário um ecrã gráfico — o navegador corre sem interface; o ecrã é irrelevante.

**Início rápido (ferramentas Docker — funciona sempre):**
```bash
docker compose --profile jog-hu up -d
```

**Iniciar o servidor host (pesquisa com IA — IP residencial necessário):**
```bash
# Funciona em: desktop ou portátil doméstico/de escritório (Windows, macOS, Linux)
# NÃO funciona em: servidores cloud/VPS (IPs de datacenter bloqueados pelo reCAPTCHA)
# Não é necessário ecrã gráfico — corre em modo headless

pip install mcp fastmcp httpx playwright playwright-stealth
playwright install chromium

python3 mcps/jog-hu/host_server.py --background   # iniciar daemon, porta 4312
python3 mcps/jog-hu/host_server.py --stop          # parar daemon
```

**Adicionar a `mcps.yaml`:**
```yaml
- name: jog-hu
  url: http://jog-hu-mcp:4302/mcp/
  description: Hungarian legal search (njt.hu)

# Opcional — apenas se host_server.py estiver a correr:
- name: jog-hu-host
  url: http://host.docker.internal:4312/mcp/
  description: Hungarian legal AI search (jog.gov.hu)
```

Adicione `jog-hu` (e opcionalmente `jog-hu-host`) à lista `tools:` de um agente em `agents.yaml`.

---

## Contribuir

1. Faça fork do repositório e crie um branch de funcionalidade.
2. Siga as convenções de camada e compose em `CLAUDE.md`.
3. Adicione ou atualize o bloco de teste correspondente em `tests.sh`.
4. Abra um pull request com uma descrição da fase ou funcionalidade adicionada.

---

## Licença
