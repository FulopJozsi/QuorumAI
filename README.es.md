[English](README.md) | [Magyar](README.hu.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Русский](README.ru.md) | [Nederlands](README.nl.md) | [Polski](README.pl.md) | [Українська](README.uk.md) | [Svenska](README.sv.md) | [Italiano](README.it.md) | [日本語](README.ja.md) | [中文](README.zh.md) | [한국어](README.ko.md) | [Kiswahili](README.sw.md)

# QuorumAI

QuorumAI es un sistema modular de orquestación de agentes de IA, auto-alojado y construido sobre LangGraph. Funciona completamente en Docker, se conecta a todas las plataformas de mensajería principales, admite interacción por voz, control del hogar inteligente y simula una «empresa» IA de múltiples roles con memoria a largo plazo y ejecución autónoma de tareas.

![Python 3.11](https://img.shields.io/badge/Python-3.11-blue.svg) ![Docker](https://img.shields.io/badge/Docker-Compose-2496ED.svg)

---

## ¿Qué es QuorumAI?

QuorumAI convierte uno o más LLM en un equipo de agentes de IA capaces de:

- Responder preguntas, leer noticias y controlar dispositivos domóticos — activados desde un micrófono, Telegram, Matrix, Discord, Slack, Signal, WhatsApp, Viber o IRC.
- Delegar trabajo entre roles especializados (CEO, desarrollador, ventas) y mantener memoria a largo plazo entre sesiones mediante búsqueda vectorial de Qdrant.
- Ejecutar tareas de forma autónoma mediante un programador heartbeat, solicitar aprobación humana cuando sea necesario (HITL) y exponer cada capacidad externa como servidor MCP (Model Context Protocol).

Todo se configura en YAML. No se necesitan cambios de código para cambiar modelos, agregar agentes o conectar nuevas herramientas.

---

## Instalación rápida

### Una línea (recomendado)

El instalador bootstrap comprueba si Python 3 y Docker están instalados, los instala si faltan y luego ejecuta el instalador interactivo de QuorumAI.

**Linux / macOS:**
```bash
curl -fsSL https://raw.githubusercontent.com/FulopJozsi/QuorumAI/main/install.sh | bash
```

**Windows (PowerShell — ejecutar como Administrador):**
```powershell
irm https://raw.githubusercontent.com/FulopJozsi/QuorumAI/main/install.ps1 | iex
```

O descarga `install.bat` / `install.ps1` del repositorio y haz doble clic.

> **Nota:** En Linux, el bootstrap instala Docker Engine desde el repositorio oficial de Docker (apt/dnf/yum según la distribución) y añade tu usuario al grupo `docker`. Se requiere cerrar e iniciar sesión de nuevo. En macOS y Windows instala Docker Desktop y te pide que lo inicies antes de continuar.

---

### ¿Ya tienes Python 3 y Docker?

Clona el repositorio y ejecuta el instalador interactivo directamente — no se requiere pip ni dependencias adicionales:

```bash
git clone https://github.com/FulopJozsi/QuorumAI.git
cd QuorumAI
python3 install.py
```

El instalador:
- Presenta un selector de módulos interactivo (orchestrator, bridges, voz, GUI y más).
- Escribe `.env` con tus respuestas, crea directorios bind-mount `data/` y ejecuta `docker compose up -d`.
- La interfaz del instalador está disponible en 16 idiomas.

**Modo Satellite** — ejecutar micrófono, bridges o servidores MCP en una máquina separada:
```bash
python3 install.py   # elige "Satellite" cuando se te pregunte
```

---

## Inicio rápido

```bash
git clone https://github.com/FulopJozsi/QuorumAI.git
cd QuorumAI
python3 install.py
```

Verificar que el orquestador está en funcionamiento:

```bash
curl http://localhost:8000/health
```

Enviar un mensaje de prueba:

```bash
curl -X POST http://localhost:8000/invoke \
  -H 'Content-Type: application/json' \
  -d '{"message": "Hola, preséntate."}'
```

Interfaz gráfica: `http://localhost:3000`

---

## Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                      quorum-net (red Docker)                 │
│                                                             │
│  ┌──────────────┐   ┌──────────┐   ┌─────────────────────┐ │
│  │   Bridges    │   │   GUI    │   │   Servidores MCP    │ │
│  │  Telegram    │──▶│  React   │   │  hu-tools  │ │
│  │  Matrix      │   │  Vite    │   │  home-assistant     │ │
│  │  Discord     │   │ Tailwind │   │  email, joplin      │ │
│  │  IRC, etc.   │   └──────────┘   │  playwright, mgr    │ │
│  └──────┬───────┘                  └──────────┬──────────┘ │
│         │              ┌────────────────────┐  │            │
│         └─────────────▶│    Orquestador     │◀─┘            │
│                        │    LangGraph       │               │
│                        │    FastAPI :8000   │               │
│                        └────────┬───────────┘               │
│               ┌─────────────────┼─────────────────┐         │
│          ┌────▼────┐      ┌─────▼────┐    ┌───────▼──────┐  │
│          │ Qdrant  │      │PostgreSQL│    │  FalkorDB    │  │
│          │ Memoria │      │Checkpoint│    │ Conocimiento │  │
│          └─────────┘      └──────────┘    └──────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

Cada capa vive en su propio directorio con su propio `compose.yml`. El `compose.yml` raíz agrupa todas las capas mediante `include:` y perfiles de Docker Compose — solo inicia lo que necesita.

---

## Características

### Orquestación principal

- **Runtime LangGraph** — grafo de agentes de máquina de estados, checkpointing HITL nativo, `AsyncPostgresSaver`.
- **API HTTP FastAPI** — `POST /invoke`, `GET /health`, streaming, receptor de webhooks, relé de notificaciones push.
- **agents.yaml** — declare agentes en YAML: nombre, rol, proveedor, modelo, ruta de prompt de sistema, herramientas.
- **Recarga en caliente** — `POST /agents/reload` recarga `agents.yaml` sin reiniciar el contenedor.
- **Protocolo de herramientas MCP** — cada capacidad externa es un servidor MCP; los agentes descubren herramientas automáticamente.
- **Memoria vectorial Qdrant** — búsqueda híbrida semántica + BM42 léxica, embeddings multilingual-e5-large, colecciones por agente, deduplicación por coseno, recuperación diversificada por MMR.
- **Consolidación de memoria nocturna** — tarea de «sueño» programada que destila el historial de sesiones de PostgreSQL en hechos Qdrant a largo plazo; fusiona progresiones, elimina entradas efímeras obsoletas; estado rastreado en PostgreSQL.
- **PostgreSQL** — checkpointer `AsyncPostgresSaver` + tablas de tareas y comentarios.
- **Grafo de conocimiento** — FalkorDB (compatible con Redis), consultas Cypher por usuario, extracción automática de entidades.

### Proveedores LLM (por agente, configurados en agents.yaml)

| Local | Nube |
|---|---|
| Ollama (predeterminado, sin clave) | Anthropic Claude |
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
| | NVIDIA NIM (nivel gratuito disponible) |

No se necesita clave API para empezar — Ollama se ejecuta localmente y de forma gratuita.

**Pools de proveedores** — varios servidores locales idénticos (p. ej. seis máquinas Ollama) pueden agruparse en un pool con nombre. El orquestador distribuye las solicitudes mediante balanceo de carga least-connections; si todos los miembros del pool fallan, se pasa a la cadena de fallback habitual. Configurado en `providers.yaml` y gestionable desde la pestaña Proveedores de la GUI.

### Simulación de empresa multi-agente

- Agentes basados en roles: CEO, desarrollador, ventas y cualquier rol personalizado.
- El agente dispatcher dirige automáticamente las solicitudes entrantes al especialista correcto.
- Agentes pipeline: bucles planificador → ejecutor → revisor con estado compartido.
- **Agentes autónomos (Deep)** — establece `deep: true` en cualquier agente o etapa de pipeline para activar el bucle ReAct LangGraph integrado. El agente planifica, ejecuta e itera de forma autónoma — llama a herramientas repetidamente hasta que la tarea esté completa o se alcance el límite opcional de llamadas a herramientas (`deep_max_steps`, 0 = ilimitado). Configurable por agente y por etapa de pipeline; palanca disponible en el GUI Agent Builder.
- Biblioteca de habilidades: archivos Markdown de habilidades, carga perezosa por agente, mercado comunitario para compartir.
- Espacio de trabajo compartido: los agentes pueden leer y escribir en un área de archivos compartida.
- **Herramientas de administración** — los agentes con rol `admin` pueden crear y eliminar agentes, skills, servidores MCP, cron jobs y programaciones heartbeat en tiempo de ejecución mediante las herramientas `system-admin`. Cada acción de escritura requiere aprobación HITL antes de ejecutarse.

### Gestión de tareas y autonomía

- Tablero Kanban con subtareas y comentarios (basado en PostgreSQL).
- Programador heartbeat: los agentes recogen tareas pendientes automáticamente (cada 5 minutos por defecto).
- Ejecución autónoma con puntos de aprobación HITL (Telegram `/approve`, botones GUI).
- Notificaciones push: Telegram, Home Assistant `notify`, web push (VAPID). Las tareas pueden especificar un campo `notify_channel` para que el mensaje de finalización siempre llegue al bridge correcto, independientemente de qué sesión creó la tarea. Los agentes pueden llamar a `list_notify_channels()` para descubrir los canales disponibles en tiempo de ejecución.

**Tareas de varios días** — el patrón recomendado para trabajos de larga duración que abarcan horas o días:
1. Crea una tarea con título y descripción (por chat, Telegram o el tablero Kanban de la GUI).
2. El agente (o tú) llama a `set_subtasks` para dividirla en pasos con nombre.
3. Cada ejecución de heartbeat toma la siguiente subtarea pendiente, la completa y se detiene — las sesiones LLM individuales permanecen cortas y enfocadas.
4. El progreso, las decisiones y los resultados intermedios se almacenan como comentarios de tarea para que cada ejecución siguiente tenga contexto completo de lo que ocurrió antes.
5. Cuando todas las subtareas están listas, el agente cierra la tarea y envía una notificación de finalización.

Este patrón funciona sin cambios de código — se basa en las herramientas de tareas existentes (`set_subtasks`, `get_next_subtask`, `complete_subtask`) a las que tiene acceso cualquier agente con la fuente de herramientas `tasks`.

### Supervisión de seguridad (Cuadrumvirato)

Una capa opcional por agente que verifica cada llamada de herramienta de riesgo antes de ejecutarse. Se activa con `guardian: true` en `agents.yaml`; los agentes sin este indicador no se ven afectados.

- **Guardian** — una llamada LLM aislada (sin herramientas) que evalúa el nombre y los argumentos de la herramienta y devuelve: `NONE` (continuar), `SOFT VETO: motivo` (decisión humana requerida) o `HARD VETO: motivo` (bloqueo inmediato).
- **Árbitro** — se activa en SOFT VETO; genera un informe de análisis Markdown y suspende el grafo mediante LangGraph `interrupt()`. El operador aprueba o rechaza via Telegram `/approve` o la GUI — el mismo flujo que HITL.
- **Historiador** — una tarea heartbeat que lee el registro de auditoría Guardian en memoria y escribe un informe estructurado en la tabla PostgreSQL `historian_reports`.
- **Clasificación de riesgo** — los servidores MCP reciben la etiqueta `risk: low` o `risk: high` en `mcps.yaml`. Las herramientas de memoria, tareas y aprobación siempre están excluidas del control.

```yaml
# agents.yaml
agents:
  - name: ceo
    guardian: true
    guardian_provider: anthropic        # opcional — hereda el proveedor del agente si está vacío
    guardian_model: claude-haiku-4-5-20251001
    arbiter_provider: anthropic
    arbiter_model: claude-sonnet-4-6
```

```yaml
# mcps.yaml
servers:
  - name: playwright
    risk: high        # todas las herramientas playwright requieren aprobación del Guardian
  - name: hu-tools
    risk: low         # clima, noticias — se transmiten sin control
```

El endpoint `/guardian/log` devuelve el registro de auditoría en vivo (últimas 1 000 decisiones).

### Autenticación y multi-tenancy

| Modo | Descripción |
|---|---|
| `AUTH_MODE=none` | Abierto — sin autenticación (predeterminado, adecuado para uso local) |
| `AUTH_MODE=local` | Token Bearer; usuarios definidos en `LOCAL_USERS=usuario1:contraseña1,...` |
| `AUTH_MODE=sso` | Keycloak OIDC/JWT, o cualquier proveedor OIDC (Auth0, Okta, Authelia, …) |

**Aislamiento por usuario.** En modo multiusuario, la memoria y el grafo de
conocimiento de cada usuario están separados: la memoria a largo plazo va a su
propia colección de Qdrant y el grafo a su propio `scope` — una lectura ve los
datos propios y la capa común curada por el administrador, nunca los de otro
usuario. El mantenimiento nocturno también se ejecuta **por usuario**.

### Observabilidad

- Trazas de pipeline con registro de tokens y costes por turno.
- Vista en cascada en la pestaña Observabilidad de la GUI.
- Limpieza automática de trazas controlada por `TRACE_RETENTION_DAYS`.

### Receptor de webhooks

Acepta webhooks firmados de: GitHub, Gitea, Drone CI, Grafana, n8n, Slack, ERPNext, Twenty CRM, Zammad, Tiledesk, Uptime Kuma, Wekan, Umami, Duplicati, BorgWarehouse.

### Copia de seguridad y persistencia de configuración

Todos los datos de ejecución viven en `data/` como bind mounts; toda la configuración en archivos YAML — sin estado oculto dentro de los contenedores.

**Crear copia de seguridad** (incluye `.env` + `data/`):

```bash
sudo python3 backup.py backup                    # interactivo, nombre de archivo automático
sudo python3 backup.py backup /srv/backup.tgz    # ruta de salida explícita
```

**Restaurar**:

```bash
python3 backup.py restore /srv/backup.tgz           # restaurar en el directorio actual
python3 backup.py restore /srv/backup.tgz /opt/qai  # restaurar en un directorio específico
```

En Linux / macOS ejecutar con `sudo` para preservar la propiedad de archivos. En Windows no es necesario.

---

## Bridges

| Bridge | Transporte | Perfil Compose |
|---|---|---|
| Telegram | Bot API, async (python-telegram-bot) | `telegram` |
| Matrix | matrix-nio, a nivel de sala | `matrix` |
| Discord | discord.py, slash commands | `discord` |
| IRC | irc3 asyncio, multi-canal | `irc` |
| WhatsApp | Meta Cloud API webhook | `whatsapp` |
| Slack | slack-bolt Socket Mode | `slack` |
| Signal | signal-cli REST API polling | `signal` |
| Viber | FastAPI webhook, botones de teclado | `viber` |

Cada bridge expone `/notify` (para notificaciones push desde el orquestador) y `/health` (verificación de actividad), y admite listas de permitidos para remitentes y canales. Telegram y la GUI también admiten el flujo HITL `/approve`. Todos los bridges admiten cambio de idioma por usuario mediante el comando `/language`; la preferencia se almacena en PostgreSQL y sobrevive a los reinicios de contenedores.

---

## Voz

### Bridge de micrófono (micrófono local)

Perfil Compose: `mic`

- openWakeWord — palabra de activación configurable (predeterminada: "Ok Szif").
- Wyoming Whisper — STT local, sin nube requerida.
- Wyoming Piper — TTS local.
- Montaje de socket PulseAudio para escritorios Linux.

**Notas de plataforma:**

- **Linux** — el instalador detecta su UID y monta automáticamente el socket PulseAudio correcto (`/run/user/<uid>/pulse`).
- **macOS / Windows** — Docker Desktop no pasa los dispositivos de audio. El instalador escribe una configuración TCP de PulseAudio en su lugar. Configure PulseAudio en modo TCP antes de iniciar el contenedor mic:
  - macOS: `brew install pulseaudio && pulseaudio --load=module-native-protocol-tcp --exit-idle-time=-1 --daemon`
  - Windows (WSL2): `sudo apt install pulseaudio && pulseaudio --load=module-native-protocol-tcp --exit-idle-time=-1 --start`
  - Windows (nativo): descargue PulseAudio para Windows, descomente `module-native-protocol-tcp` en `default.pa`, permita el puerto 4713 en el firewall.

### Home Assistant Voice PE

Perfil Compose: `ha`

QuorumAI se registra como agente de conversación dentro de Home Assistant. HA Assist gestiona la detección de palabra de activación, Whisper STT y Piper TTS en el lado de HA; QuorumAI gestiona el razonamiento y las llamadas a herramientas.

### Herramientas STT y TTS (invocables por agentes)

Perfil Compose: `stt-tts`

Expone Whisper y Piper como APIs HTTP que los agentes pueden llamar como herramientas `system-stt` y `system-tts`.

---

## Interfaz gráfica

Perfil Compose: `gui` — disponible en `http://localhost:3000`

Construida con React, Vite y Tailwind CSS.

| Pestaña | Descripción |
|---|---|
| Chat | Enviar mensajes a cualquier agente; ver respuestas en streaming |
| Agent Builder | Diagrama visual de empresa; crear y editar agentes y sus roles |
| Skill Editor | Crear y gestionar archivos Markdown de habilidades |
| Tasks | Tablero Kanban; árbol de subtareas; comentarios; botones de aprobación |
| Proveedores | Estado en tiempo real de proveedores y lista de modelos disponibles |
| Heartbeat | Estado del programador; próximas ejecuciones; activación manual |
| Observabilidad | Trazas de pipeline; vista en cascada de tokens y costes |

- 16 idiomas de interfaz, 14 temas.
- Botones de aprobación HITL integrados en las pestañas Chat y Tareas.

---

## Detalles de instalación

### Requisitos previos

- Docker Engine 24+ y Docker Compose v2.
- Python 3.8+ para `install.py` — sin pip ni virtualenv requerido.
- Para modelos locales: Ollama ejecutándose en el host en el puerto 11434.

### Crear la red compartida (una vez por host)

```bash
docker network create quorum-net
```

### Selección de perfiles

Establezca los perfiles en `.env` para que `docker compose up -d` funcione sin argumentos:

```env
COMPOSE_PROFILES=orchestrator,memory,mcp,postgres,telegram,gui
```

O páselos explícitamente:

```bash
docker compose --profile orchestrator --profile memory --profile gui up -d
```

Perfiles disponibles: `orchestrator`, `memory`, `mcp`, `postgres`, `telegram`, `ha`, `mic`, `gui`, `stt-tts`, `mcp-manager`, `playwright`, `joplin`, `auth`, `email`, `matrix`, `discord`, `irc`, `whatsapp`, `slack`, `signal`, `viber`, `graph`

### Estructura del directorio de datos

```
data/
  qdrant/        # Vectores Qdrant
  postgres/      # Datos PostgreSQL
  workspace/     # Espacio de trabajo de archivos por agente
  whisper/       # Caché de modelos Whisper
  piper/         # Archivos de voz Piper
  ...
```

Todo lo que hay bajo `data/` está en gitignore. Hacer una copia de seguridad de este directorio preserva todo el estado persistente.

---

## Configuración

Copie `.env.example` a `.env` y rellene lo que necesite. El archivo `.env.example` contiene documentación en línea para cada clave.

### Claves más importantes

| Clave | Predeterminado | Descripción |
|---|---|---|
| `COMPOSE_PROFILES` | — | Perfiles a iniciar, separados por comas |
| `AUTH_MODE` | `none` | `none` / `local` / `sso` |
| `ORCHESTRATOR_PORT` | `8000` | Puerto FastAPI del orquestador |
| `GUI_PORT` | `3000` | Puerto de la GUI |
| `QDRANT_HTTP_PORT` | `6333` | Puerto REST de Qdrant |
| `POSTGRES_PORT` | `5433` | Puerto PostgreSQL |
| `POSTGRES_PASSWORD` | `changeme` | Contraseña PostgreSQL — ¡cámbiela! |
| `TRACE_RETENTION_DAYS` | `14` | Eliminación automática de trazas más antiguas de N días |
| `ANTHROPIC_API_KEY` | — | Requerido para proveedor Anthropic |
| `OPENROUTER_API_KEY` | — | Requerido para OpenRouter |
| `OPENAI_API_KEY` | — | Requerido para OpenAI |
| `GOOGLE_API_KEY` | — | Requerido para Google Gemini |
| `TELEGRAM_BOT_TOKEN` | — | Requerido para bridge Telegram |
| `TELEGRAM_CHAT_ID` | — | ID del chat Telegram del que aceptar mensajes |
| `NOTIFY_TELEGRAM_CHAT_ID` | — | ID del chat para notificaciones de tarea completada (igual que `TELEGRAM_CHAT_ID` si es el mismo) |
| `MATRIX_HOMESERVER` | — | URL del servidor Matrix |
| `MATRIX_ACCESS_TOKEN` | — | Token de acceso del bot Matrix |
| `DISCORD_BOT_TOKEN` | — | Requerido para bridge Discord |
| `SLACK_BOT_TOKEN` | — | Requerido para bridge Slack |
| `SLACK_APP_TOKEN` | — | Requerido para Slack Socket Mode |
| `SIGNAL_PHONE` | — | Número de teléfono para bridge Signal |
| `VIBER_AUTH_TOKEN` | — | Requerido para bridge Viber |
| `HA_URL` | `http://homeassistant:8123` | URL base de Home Assistant |
| `HA_TOKEN` | — | Token de acceso de larga duración HA |
| `IMAP_HOST` | — | Servidor IMAP para Email MCP |
| `SMTP_HOST` | — | Servidor SMTP para Email MCP |
| `FALKORDB_URL` | — | Establecer para habilitar el grafo de conocimiento |
| `VAPID_EMAIL` | — | Requerido para notificaciones web push |
| `VAPID_PRIVATE_KEY` | — | Generado automáticamente por el instalador (requiere el paquete Python `cryptography`); de lo contrario: `docker compose exec orchestrator python3 webpush.py` |
| `VAPID_PUBLIC_KEY` | — | Generado junto con la clave privada |
| `HU_TOOLS_PORT` | `4300` | Puerto del MCP hu-tools |
| `WHISPER_URL` | `http://whisper-http:8000` | URL del servicio STT |
| `PIPER_URL` | `http://piper-http:5000` | URL del servicio TTS |
| `ORCHESTRATOR_API_KEY` | — | Generado automáticamente por el instalador; token servicio-a-servicio para bridges (requerido en `AUTH_MODE=local/sso`) |
| `CONVERSATION_API_KEY` | — | Generado automáticamente por el instalador; protege el endpoint HA `/conversation` (vacío = abierto) |

La configuración de agentes se encuentra en `orchestrator/agents.yaml`, no en `.env`.

---

## Paquetes sectoriales

Paquetes verticales preconstruidos para industrias específicas. Cada paquete contiene archivos de habilidades, configuraciones de agentes sugeridas y referencias MCP. Se instalan mediante `install.py` o manualmente.

| Paquete | Objetivo | Habilidades clave |
|---|---|---|
| `legal` | Despachos de abogados | Búsqueda de documentos, análisis de contratos, búsqueda legal húngara |
| `devops` | Empresas IT/DevOps | Triaje de incidentes, búsqueda de runbook, AIOps con HITL |
| `agency` | Agencias de marketing y PR | Estado de proyecto, calificación de leads, análisis de briefs, reporting de clientes |

**Instalación manual:**
```bash
cp industry-packs/legal/skills/*.md data/skills/
cat industry-packs/legal/agents.yaml
```

**Vía instalador:** vuelva a ejecutar `python3 install.py` → Modificar → seleccionar un paquete sectorial.

Cree su propio paquete copiando `industry-packs/_template/` y rellenando `pack.yaml`.

---

## Integración CRM

El MCP CRM (`mcps/crm/`) proporciona una interfaz unificada para múltiples sistemas CRM mediante una arquitectura de adaptadores intercambiables. Los agentes utilizan las mismas herramientas independientemente del backend.

**Adaptadores soportados:**

| Adaptador | Sistema | Tipo |
|---|---|---|
| `minicrm` | MiniCRM (líder del mercado húngaro) | Completo |
| `hubspot` | HubSpot CRM | Completo |
| `pipedrive` | Pipedrive | Completo |
| `billingo` | Facturación Billingo | Solo lectura |
| `szamlazzhu` | Számlázz.hu facturación | Solo lectura |
| `salesautopilot` | SalesAutopilot (automatización marketing HU) | Completo |

**Herramientas disponibles:** `search_entities`, `get_entity`, `create_entity`, `update_entity`, `add_note`, `get_timeline`, `link_entities`, `get_related`, `emit_event`, `list_entity_types`

**Inicio rápido:**
```env
CRM_ADAPTER=minicrm
MINICRM_SYSTEM_ID=12345
MINICRM_API_KEY=su-clave
```

```bash
docker compose --profile crm up -d
```

Agregue `crm` a la lista `tools:` de un agente en `agents.yaml` para darle acceso al CRM.

---

## jog.gov.hu MCP — Búsqueda legal húngara

El MCP jog.gov.hu (`mcps/jog-hu/`) proporciona información jurídica húngara a los agentes de IA en dos modos de despliegue:

**Modo Docker** (siempre funciona, sin Playwright requerido):

| Herramienta | Descripción |
|---|---|
| `search_njt_laws(keywords)` | Búsqueda por palabras clave en njt.jog.gov.hu — devuelve títulos y URLs de leyes coincidentes |
| `get_law_text(law_id, section)` | Texto completo o parcial de una ley desde njt.hu (p. ej. `"2012. évi I. törvény"`, sección `"69"`) |
| `list_recent_laws(category, days)` | Leyes recientes del feed RSS de Magyar Közlöny |

**Modo Host** (búsqueda con IA, requiere ejecutar `host_server.py` en la máquina host):

| Herramienta | Descripción |
|---|---|
| `search_law(question)` | Pregunta en lenguaje natural → respuesta de IA + referencias legales citadas (jog.gov.hu) |

reCAPTCHA v3 puntúa las sesiones principalmente según la **reputación de la IP**. Las IPs de contenedores Docker y de servidores en la nube/VPS se clasifican como rangos de centros de datos y reciben una puntuación de confianza baja — independientemente de los parches de huella digital del navegador. Una máquina doméstica u ofimática con una **IP residencial** obtiene puntuación suficientemente alta para pasar. **No se requiere pantalla gráfica** — el navegador funciona sin interfaz gráfica (headless); la pantalla es irrelevante.

**Inicio rápido (herramientas Docker — siempre funciona):**
```bash
docker compose --profile jog-hu up -d
```

**Iniciar el servidor host (búsqueda con IA — se requiere IP residencial):**
```bash
# Funciona en: escritorio o portátil doméstico/ofimático (Windows, macOS, Linux)
# NO funciona en: servidores en la nube/VPS (IPs de centros de datos bloqueadas por reCAPTCHA)
# No se requiere pantalla gráfica — funciona en modo headless

pip install mcp fastmcp httpx playwright playwright-stealth
playwright install chromium

python3 mcps/jog-hu/host_server.py --background   # iniciar como demonio, puerto 4312
python3 mcps/jog-hu/host_server.py --stop          # detener demonio
```

**Agregar a `mcps.yaml`:**
```yaml
- name: jog-hu
  url: http://jog-hu-mcp:4302/mcp/
  description: Búsqueda legal húngara (njt.hu)

# Opcional — solo si host_server.py está en ejecución:
- name: jog-hu-host
  url: http://host.docker.internal:4312/mcp/
  description: Búsqueda legal con IA húngara (jog.gov.hu)
```

Agregue `jog-hu` (y opcionalmente `jog-hu-host`) a la lista `tools:` de un agente en `agents.yaml`.
