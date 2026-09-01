[English](README.md) | [Magyar](README.hu.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Русский](README.ru.md) | [Nederlands](README.nl.md) | [Polski](README.pl.md) | [Українська](README.uk.md) | [Svenska](README.sv.md) | [Italiano](README.it.md) | [日本語](README.ja.md) | [中文](README.zh.md) | [한국어](README.ko.md) | [Kiswahili](README.sw.md)

# QuorumAI

QuorumAI est un système d'orchestration multi-agents modulaire et auto-hébergé, construit sur LangGraph. Il fonctionne entièrement dans Docker, se connecte à toutes les principales plateformes de messagerie, prend en charge l'interaction vocale, le contrôle de la maison intelligente et simule une « entreprise » IA multi-rôles avec une mémoire à long terme et une exécution autonome des tâches.

![Python 3.11](https://img.shields.io/badge/Python-3.11-blue.svg) ![Docker](https://img.shields.io/badge/Docker-Compose-2496ED.svg)

---

<div align="center">
  <video src="https://github.com/user-attachments/assets/7bd072b6-75cd-4345-9fe0-fa2f3ee0566e" controls width="800"></video>

  <p><b><a href="https://license.quorumai.eu/portal/register">Commencer — inscrivez-vous pour un essai gratuit de 30 jours »</a></b></p>
</div>

---

## Qu'est-ce que QuorumAI ?

QuorumAI transforme un ou plusieurs LLM en une équipe d'agents IA capables de :

- Répondre à des questions, lire les actualités, contrôler des appareils domotiques — depuis un microphone, Telegram, Matrix, Discord, Slack, Signal, WhatsApp, Viber ou IRC.
- Déléguer le travail entre des rôles spécialisés (PDG, développeur, commercial) et maintenir une mémoire à long terme entre les sessions grâce à la recherche vectorielle Qdrant.
- Exécuter des tâches de manière autonome via un planificateur heartbeat, demander une approbation humaine si nécessaire (HITL) et exposer chaque capacité externe comme serveur MCP (Model Context Protocol).

Tout est configuré en YAML. Aucune modification de code n'est nécessaire pour changer de modèle, ajouter des agents ou connecter de nouveaux outils.

---

## Installation rapide

### Une ligne (recommandé)

Le programme d'installation bootstrap vérifie la présence de Python 3 et Docker, les installe si nécessaire, puis lance l'installateur interactif de QuorumAI.

**Linux / macOS:**
```bash
curl -fsSL https://raw.githubusercontent.com/FulopJozsi/QuorumAI/main/install.sh | bash
```

**Windows (PowerShell — exécuter en tant qu'Administrateur) :**
```powershell
irm https://raw.githubusercontent.com/FulopJozsi/QuorumAI/main/install.ps1 | iex
```

Ou téléchargez `install.bat` / `install.ps1` depuis le dépôt et double-cliquez dessus.

> **Remarque :** Sur Linux, le bootstrap installe Docker Engine depuis le dépôt officiel Docker (apt/dnf/yum selon la distribution) et ajoute votre utilisateur au groupe `docker`. Une déconnexion/reconnexion est nécessaire. Sur macOS et Windows, il installe Docker Desktop et vous invite à le démarrer avant de continuer.

---

### Vous avez déjà Python 3 et Docker ?

Clonez le dépôt et exécutez l'installateur interactif directement — pip et dépendances supplémentaires ne sont pas nécessaires :

```bash
git clone https://github.com/FulopJozsi/QuorumAI.git
cd QuorumAI
python3 install.py
```

L'installateur :
- Présente un sélecteur de modules interactif (orchestrateur, bridges, voix, GUI et plus).
- Écrit `.env` à partir de vos réponses, crée les répertoires bind-mount `data/` et exécute `docker compose up -d`.
- L'interface de l'installateur est disponible en 16 langues.

**Mode Satellite** — exécuter le micro, des bridges ou des serveurs MCP sur une machine séparée :
```bash
python3 install.py   # choisissez "Satellite" lorsque demandé
```

---

## Démarrage rapide

```bash
git clone https://github.com/FulopJozsi/QuorumAI.git
cd QuorumAI
python3 install.py
```

Vérifier que l'orchestrateur fonctionne :

```bash
curl http://localhost:8000/health
```

Envoyer un message de test :

```bash
curl -X POST http://localhost:8000/invoke \
  -H 'Content-Type: application/json' \
  -d '{"message": "Hello, introduce yourself."}'
```

Interface graphique : `http://localhost:3000`

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

Chaque couche réside dans son propre répertoire avec son propre `compose.yml`. La `compose.yml` racine regroupe toutes les couches via `include:` et les profils Docker Compose — vous ne démarrez que ce dont vous avez besoin.

---

## Fonctionnalités

### Orchestration principale

- **Runtime LangGraph** — graphe d'agents à machine d'état, checkpointing HITL natif, `AsyncPostgresSaver`.
- **API HTTP FastAPI** — `POST /invoke`, `GET /health`, streaming, récepteur webhook, relais de notifications push.
- **agents.yaml** — déclarez les agents en YAML : nom, rôle, fournisseur, modèle, chemin du prompt système, outils.
- **Rechargement à chaud** — `POST /agents/reload` recharge `agents.yaml` sans redémarrer le conteneur.
- **Protocole d'outils MCP** — chaque capacité externe est un serveur MCP ; les agents découvrent les outils automatiquement.
- **Mémoire vectorielle Qdrant** — recherche hybride sémantique + BM42 lexicale, embeddings multilingual-e5-large, collections par agent, déduplication cosinus, rappel diversifié par MMR.
- **Consolidation mémorielle nocturne** — tâche de « rêve » planifiée qui distille l'historique de session PostgreSQL en faits Qdrant à long terme ; fusionne les progressions, supprime les entrées éphémères obsolètes ; état suivi dans PostgreSQL.
- **PostgreSQL** — checkpointer `AsyncPostgresSaver` + tables de tâches et commentaires.
- **Graphe de connaissances** — FalkorDB (compatible Redis), requêtes Cypher par utilisateur, extraction automatique d'entités.

### Fournisseurs LLM (par agent, configurés dans agents.yaml)

| Local | Cloud |
|---|---|
| Ollama (par défaut, sans clé) | Anthropic Claude |
| llama.cpp | OpenAI |
| LM Studio | OpenRouter |
| vLLM | Google Gemini |
| Docker Model Runner | Grok (xAI) |
| Unsloth Studio | DeepSeek |
| | Mistral AI |
| | Together AI |
| | Fireworks AI |
| | Zhipu AI / Z.AI |
| | Eden AI (agrégateur) |
| | NVIDIA NIM (niveau gratuit disponible) |

Aucune clé API n'est nécessaire pour commencer — Ollama fonctionne localement et gratuitement.

**Pools de fournisseurs** — plusieurs serveurs locaux identiques (p. ex. six machines Ollama) peuvent être regroupés dans un pool nommé. L'orchestrateur distribue les requêtes par algorithme least-connections ; si tous les membres du pool échouent, il bascule sur la chaîne de fallback habituelle. Configuré dans `providers.yaml`, gérable depuis l'onglet Fournisseurs de la GUI.

### Simulation d'entreprise multi-agents

- Agents basés sur des rôles : PDG, développeur, commercial et tout rôle personnalisé.
- L'agent dispatcher dirige automatiquement les requêtes vers le bon spécialiste.
- Agents pipeline : boucles planificateur → exécuteur → réviseur avec état partagé.
- **Agents autonomes (Deep)** — définissez `deep: true` sur un agent ou une étape de pipeline pour activer la boucle ReAct LangGraph intégrée. L'agent planifie, exécute et itère de façon autonome — il appelle des outils successivement jusqu'à ce que la tâche soit terminée ou que la limite optionnelle d'appels d'outils soit atteinte (`deep_max_steps`, 0 = illimité). Configurable par agent et par étape de pipeline ; bascule disponible dans le GUI Agent Builder.
- Bibliothèque de compétences : fichiers Markdown de compétences, chargement paresseux par agent, place de marché communautaire pour le partage.
- Espace de travail partagé : les agents peuvent lire et écrire dans une zone de fichiers partagée.
- **Outils d'administration** — les agents dotés du rôle `admin` peuvent créer et supprimer des agents, des compétences, des serveurs MCP, des tâches cron et des planifications heartbeat au moment de l'exécution via les outils `system-admin`. Chaque action d'écriture nécessite une approbation HITL avant exécution.

### Gestion des tâches et autonomie

- Tableau Kanban avec sous-tâches et commentaires (basé sur PostgreSQL).
- Planificateur heartbeat : les agents prennent automatiquement les tâches en attente (toutes les 5 minutes par défaut).
- Exécution autonome avec points d'approbation HITL (Telegram `/approve`, boutons GUI).
- Notifications push : Telegram, Home Assistant `notify`, web push (VAPID). Les tâches peuvent spécifier un champ `notify_channel` pour que le message de fin soit toujours envoyé au bon bridge, quelle que soit la session qui a créé la tâche. Les agents peuvent appeler `list_notify_channels()` pour découvrir les canaux disponibles au moment de l'exécution.

**Tâches sur plusieurs jours** — le modèle recommandé pour les travaux de longue durée s'étalant sur des heures ou des jours :
1. Créez une tâche avec un titre et une description (via le chat, Telegram ou le tableau Kanban de l'interface).
2. L'agent (ou vous) appelle `set_subtasks` pour la diviser en étapes nommées.
3. Chaque exécution heartbeat récupère la prochaine sous-tâche en attente, l'accomplit et s'arrête — les sessions LLM individuelles restent courtes et ciblées.
4. La progression, les décisions et les résultats intermédiaires sont stockés en commentaires de tâche, de sorte que chaque exécution suivante dispose du contexte complet de ce qui s'est passé avant.
5. Lorsque toutes les sous-tâches sont terminées, l'agent ferme la tâche et envoie une notification de complétion.

Ce modèle fonctionne sans modification de code — il repose sur les outils de tâches existants (`set_subtasks`, `get_next_subtask`, `complete_subtask`) auxquels tout agent disposant de la source d'outils `tasks` a accès.

### Supervision de sécurité (Quadrumvirat)

Une couche optionnelle par agent qui contrôle chaque appel d'outil risqué avant son exécution. Activée avec `guardian: true` dans `agents.yaml` ; les agents sans ce drapeau ne sont pas affectés.

- **Guardian** — un appel LLM isolé (sans outils) qui évalue le nom et les arguments de l'outil et retourne : `NONE` (continuer), `SOFT VETO: raison` (décision humaine requise) ou `HARD VETO: raison` (blocage immédiat).
- **Arbitre** — activé sur SOFT VETO ; génère un rapport d'analyse Markdown et suspend le graphe via LangGraph `interrupt()`. L'opérateur approuve ou refuse via Telegram `/approve` ou l'interface — même flux que le HITL.
- **Historien** — une tâche heartbeat qui lit le journal d'audit Guardian en mémoire et écrit un rapport structuré dans la table PostgreSQL `historian_reports`.
- **Classification des risques** — les serveurs MCP sont étiquetés `risk: low` ou `risk: high` dans `mcps.yaml`. Les outils de mémoire, de tâche et d'approbation sont toujours exclus du contrôle.

```yaml
# agents.yaml
agents:
  - name: ceo
    guardian: true
    guardian_provider: anthropic        # optionnel — hérite du provider de l'agent si vide
    guardian_model: claude-haiku-4-5-20251001
    arbiter_provider: anthropic
    arbiter_model: claude-sonnet-4-6
```

```yaml
# mcps.yaml
servers:
  - name: playwright
    risk: high        # tous les outils playwright nécessitent l'approbation du Guardian
  - name: hu-tools
    risk: low         # météo, actualités — transmis sans contrôle
```

L'endpoint `/guardian/log` retourne le journal d'audit en direct (1 000 dernières décisions).

### Authentification et multi-tenancy

| Mode | Description |
|---|---|
| `AUTH_MODE=none` | Ouvert — sans authentification (par défaut, pour usage local) |
| `AUTH_MODE=local` | Token Bearer ; utilisateurs définis dans `LOCAL_USERS=user1:pass1,...` |
| `AUTH_MODE=sso` | Keycloak OIDC/JWT ou tout fournisseur OIDC (Auth0, Okta, Authelia, …) |

**Isolation par utilisateur.** En mode multi-utilisateur, la mémoire et le
graphe de connaissances de chaque utilisateur sont séparés : la mémoire à long
terme va dans sa propre collection Qdrant et le graphe dans son propre `scope` —
une lecture voit ses propres données et la couche commune gérée par
l'administrateur, jamais celles d'un autre. La maintenance nocturne s'exécute
également **par utilisateur**.

### Observabilité

- Traces de pipeline avec journalisation des tokens et des coûts par tour.
- Vue en cascade dans l'onglet Monitoring de la GUI.
- Nettoyage automatique des traces contrôlé par `TRACE_RETENTION_DAYS`.

### Récepteur webhook

Accepte des webhooks signés depuis : GitHub, Gitea, Drone CI, Grafana, n8n, Slack, ERPNext, Twenty CRM, Zammad, Tiledesk, Uptime Kuma, Wekan, Umami, Duplicati, BorgWarehouse.

### Sauvegarde et persistance de la configuration

Toutes les données d'exécution sont dans `data/` en bind mounts ; toute la configuration dans des fichiers YAML — aucun état caché dans les conteneurs.

**Créer une sauvegarde** (inclut `.env` + `data/`) :

```bash
sudo python3 backup.py backup                 # interactif, nom de fichier automatique
sudo python3 backup.py backup /srv/backup.tgz # chemin de sortie explicite
```

**Restaurer** :

```bash
python3 backup.py restore /srv/backup.tgz          # restaurer dans le répertoire courant
python3 backup.py restore /srv/backup.tgz /opt/qai # restaurer dans un répertoire spécifique
```

Sous Linux / macOS, exécuter avec `sudo` pour préserver les propriétaires de fichiers. Sous Windows, inutile.

---

## Bridges

| Bridge | Transport | Profil Compose |
|---|---|---|
| Telegram | Bot API, async (python-telegram-bot) | `telegram` |
| Matrix | matrix-nio, niveau salle | `matrix` |
| Discord | discord.py, slash commands | `discord` |
| IRC | irc3 asyncio, multi-canal | `irc` |
| WhatsApp | Meta Cloud API webhook | `whatsapp` |
| Slack | slack-bolt Socket Mode | `slack` |
| Signal | signal-cli REST API polling | `signal` |
| Viber | FastAPI webhook, boutons clavier | `viber` |

Chaque bridge expose `/notify` (pour les notifications push depuis l'orchestrateur) et `/health` (vérification de vivacité), et prend en charge des listes d'autorisation pour les expéditeurs et les canaux. Telegram et la GUI prennent également en charge le flux HITL `/approve`. Tous les bridges prennent en charge le changement de langue par utilisateur via la commande `/language` ; la préférence est enregistrée dans PostgreSQL et survit aux redémarrages des conteneurs.

---

## Voix

### Bridge microphone (microphone local)

Profil Compose : `mic`

- openWakeWord — mot de réveil configurable (par défaut : "Ok Szif").
- Wyoming Whisper — STT local, sans cloud requis.
- Wyoming Piper — TTS local.
- Montage de socket PulseAudio pour bureaux Linux.

**Notes sur la plateforme :**

- **Linux** — l'installateur détecte votre UID et monte automatiquement le bon socket PulseAudio (`/run/user/<uid>/pulse`).
- **macOS / Windows** — Docker Desktop ne transfère pas les périphériques audio. L'installateur écrit une configuration PulseAudio TCP à la place. Configurez PulseAudio en mode TCP avant de démarrer le conteneur mic :
  - macOS : `brew install pulseaudio && pulseaudio --load=module-native-protocol-tcp --exit-idle-time=-1 --daemon`
  - Windows (WSL2) : `sudo apt install pulseaudio && pulseaudio --load=module-native-protocol-tcp --exit-idle-time=-1 --start`
  - Windows (natif) : téléchargez PulseAudio pour Windows, décommentez `module-native-protocol-tcp` dans `default.pa`, autorisez le port 4713 dans le pare-feu.

### Home Assistant Voice PE

Profil Compose : `ha`

QuorumAI s'enregistre comme agent de conversation dans Home Assistant. HA Assist gère la détection du mot de réveil, le STT Whisper et le TTS Piper côté HA ; QuorumAI gère le raisonnement et les appels d'outils.

### Outils STT et TTS (appelables par les agents)

Profil Compose : `stt-tts`

Expose Whisper et Piper comme des API HTTP que les agents peuvent appeler en tant qu'outils `system-stt` et `system-tts`.

---

## Interface graphique

Profil Compose : `gui` — disponible à `http://localhost:3000`

Construit avec React, Vite et Tailwind CSS.

| Onglet | Description |
|---|---|
| Chat | Envoyer des messages à n'importe quel agent ; afficher les réponses en streaming |
| Agent Builder | Diagramme d'entreprise visuel ; créer et modifier des agents et leurs rôles |
| Skill Editor | Créer et gérer des fichiers de compétences Markdown |
| Tasks | Tableau Kanban ; arborescence de sous-tâches ; commentaires ; boutons d'approbation |
| Providers | Statut des fournisseurs en temps réel et liste des modèles disponibles |
| Heartbeat | État du planificateur ; prochaines exécutions ; déclenchement manuel |
| Observability | Traces de pipeline ; vue en cascade des tokens et des coûts |

- 16 langues d'interface, 14 thèmes.
- Boutons d'approbation HITL intégrés dans les onglets Chat et Tasks.

---

## Détails d'installation

### Prérequis

- Docker Engine 24+ et Docker Compose v2.
- Python 3.8+ pour `install.py` — ni pip ni virtualenv requis.
- Pour les modèles locaux : Ollama en cours d'exécution sur l'hôte au port 11434.

### Créer le réseau partagé (une fois par hôte)

```bash
docker network create quorum-net
```

### Sélection des profils

Définissez les profils dans `.env` pour que `docker compose up -d` fonctionne simplement :

```env
COMPOSE_PROFILES=orchestrator,memory,mcp,postgres,telegram,gui
```

Ou passez-les explicitement :

```bash
docker compose --profile orchestrator --profile memory --profile gui up -d
```

Profils disponibles : `orchestrator`, `memory`, `mcp`, `postgres`, `telegram`, `ha`, `mic`, `gui`, `stt-tts`, `mcp-manager`, `playwright`, `joplin`, `auth`, `email`, `matrix`, `discord`, `irc`, `whatsapp`, `slack`, `signal`, `viber`, `graph`

### Structure du répertoire de données

```
data/
  qdrant/        # Vecteurs Qdrant
  postgres/      # Données PostgreSQL
  workspace/     # Espace de travail de fichiers par agent
  whisper/       # Cache du modèle Whisper
  piper/         # Fichiers de voix Piper
  ...
```

Tout ce qui est sous `data/` est ignoré par git. Sauvegarder ce répertoire préserve tout l'état persistant.

---

## Configuration

Copiez `.env.example` dans `.env` et remplissez ce dont vous avez besoin. Le fichier `.env.example` contient une documentation en ligne pour chaque clé.

### Clés principales

| Clé | Défaut | Description |
|---|---|---|
| `COMPOSE_PROFILES` | — | Profils à démarrer, séparés par des virgules |
| `AUTH_MODE` | `none` | `none` / `local` / `sso` |
| `ORCHESTRATOR_PORT` | `8000` | Port FastAPI de l'orchestrateur |
| `GUI_PORT` | `3000` | Port GUI |
| `QDRANT_HTTP_PORT` | `6333` | Port REST Qdrant |
| `POSTGRES_PORT` | `5433` | Port PostgreSQL |
| `POSTGRES_PASSWORD` | `changeme` | Mot de passe PostgreSQL — à modifier ! |
| `TRACE_RETENTION_DAYS` | `14` | Suppression automatique des traces après N jours |
| `ANTHROPIC_API_KEY` | — | Requis pour le fournisseur Anthropic |
| `OPENROUTER_API_KEY` | — | Requis pour OpenRouter |
| `OPENAI_API_KEY` | — | Requis pour OpenAI |
| `GOOGLE_API_KEY` | — | Requis pour Google Gemini |
| `TELEGRAM_BOT_TOKEN` | — | Requis pour le bridge Telegram |
| `TELEGRAM_CHAT_ID` | — | ID du chat Telegram à accepter |
| `NOTIFY_TELEGRAM_CHAT_ID` | — | ID du chat pour les notifications de fin de tâche (identique à `TELEGRAM_CHAT_ID` si pareil) |
| `MATRIX_HOMESERVER` | — | URL du serveur Matrix |
| `MATRIX_ACCESS_TOKEN` | — | Token d'accès du bot Matrix |
| `DISCORD_BOT_TOKEN` | — | Requis pour le bridge Discord |
| `SLACK_BOT_TOKEN` | — | Requis pour le bridge Slack |
| `SLACK_APP_TOKEN` | — | Requis pour Slack Socket Mode |
| `SIGNAL_PHONE` | — | Numéro de téléphone pour le bridge Signal |
| `VIBER_AUTH_TOKEN` | — | Requis pour le bridge Viber |
| `HA_URL` | `http://homeassistant:8123` | URL de base de Home Assistant |
| `HA_TOKEN` | — | Token d'accès longue durée HA |
| `IMAP_HOST` | — | Serveur IMAP pour le MCP Email |
| `SMTP_HOST` | — | Serveur SMTP pour le MCP Email |
| `FALKORDB_URL` | — | Définir pour activer le graphe de connaissances |
| `VAPID_EMAIL` | — | Requis pour les notifications web push |
| `VAPID_PRIVATE_KEY` | — | Généré automatiquement par l'installateur (nécessite le paquet Python `cryptography`) ; sinon : `docker compose exec orchestrator python3 webpush.py` |
| `VAPID_PUBLIC_KEY` | — | Généré avec la clé privée |
| `HU_TOOLS_PORT` | `4300` | Port MCP hu-tools |
| `WHISPER_URL` | `http://whisper-http:8000` | URL du service STT |
| `PIPER_URL` | `http://piper-http:5000` | URL du service TTS |
| `ORCHESTRATOR_API_KEY` | — | Généré automatiquement par l'installateur ; token service-à-service pour les bridges (requis en `AUTH_MODE=local/sso`) |
| `CONVERSATION_API_KEY` | — | Généré automatiquement par l'installateur ; protège l'endpoint HA `/conversation` (vide = ouvert) |

La configuration des agents se trouve dans `orchestrator/agents.yaml` — pas dans `.env`.

---

## Packs métiers

Packs verticaux préconstruits pour des secteurs spécifiques. Chaque pack contient des fichiers de compétences, des configurations d'agents suggérées et des références MCP. Installés via `install.py` ou manuellement.

| Pack | Cible | Compétences clés |
|---|---|---|
| `legal` | Cabinets d'avocats | Recherche documentaire, analyse de contrats, recherche juridique hongroise |
| `devops` | Entreprises IT/DevOps | Triage d'incidents, recherche de runbook, AIOps avec HITL |
| `agency` | Agences marketing et relations publiques | Statut projet, qualification de leads, analyse de briefs, reporting client |

**Installation manuelle :**
```bash
cp industry-packs/legal/skills/*.md data/skills/
cat industry-packs/legal/agents.yaml
```

**Via l'installateur :** relancez `python3 install.py` → Modifier → sélectionner un pack métier.

Créez votre propre pack en copiant `industry-packs/_template/` et en remplissant `pack.yaml`.

---

## Intégration CRM

Le MCP CRM (`mcps/crm/`) fournit une interface unifiée à plusieurs systèmes CRM via une architecture d'adaptateurs interchangeables. Les agents utilisent les mêmes outils quel que soit le backend.

**Adaptateurs supportés :**

| Adaptateur | Système | Type |
|---|---|---|
| `minicrm` | MiniCRM (leader du marché hongrois) | Complet |
| `hubspot` | HubSpot CRM | Complet |
| `pipedrive` | Pipedrive | Complet |
| `billingo` | Facturation Billingo | Lecture seule |
| `szamlazzhu` | Számlázz.hu facturation | Lecture seule |
| `salesautopilot` | SalesAutopilot (automatisation marketing HU) | Complet |

**Outils disponibles :** `search_entities`, `get_entity`, `create_entity`, `update_entity`, `add_note`, `get_timeline`, `link_entities`, `get_related`, `emit_event`, `list_entity_types`

**Démarrage rapide :**
```env
CRM_ADAPTER=minicrm
MINICRM_SYSTEM_ID=12345
MINICRM_API_KEY=votre-cle
```

```bash
docker compose --profile crm up -d
```

Ajoutez `crm` à la liste `tools:` d'un agent dans `agents.yaml` pour lui donner accès au CRM.

---

## jog.gov.hu MCP — Recherche juridique hongroise

Le MCP jog.gov.hu (`mcps/jog-hu/`) fournit des informations juridiques hongroises aux agents IA selon deux modes de déploiement :

**Mode Docker** (fonctionne toujours, Playwright non requis) :

| Outil | Description |
|---|---|
| `search_njt_laws(keywords)` | Recherche par mots-clés sur njt.jog.gov.hu — renvoie les titres et URL des lois correspondantes |
| `get_law_text(law_id, section)` | Texte complet ou partiel d'une loi depuis njt.hu (ex. `"2012. évi I. törvény"`, section `"69"`) |
| `list_recent_laws(category, days)` | Lois récentes issues du flux RSS du Magyar Közlöny |

**Mode hôte** (recherche assistée par IA, nécessite l'exécution de `host_server.py` sur la machine hôte) :

| Outil | Description |
|---|---|
| `search_law(question)` | Question en langage naturel → réponse IA + références législatives citées (jog.gov.hu) |

reCAPTCHA v3 évalue les sessions principalement en fonction de la **réputation IP**. Les adresses IP des conteneurs Docker et des serveurs cloud/VPS sont classées comme plages de datacentre et reçoivent un score de confiance trop faible — indépendamment des correctifs d'empreinte du navigateur. Une machine à domicile ou au bureau sur une **IP résidentielle** obtient un score suffisamment élevé pour passer. Un affichage graphique **n'est pas requis** — le navigateur fonctionne en mode sans interface (headless) ; l'affichage est sans importance.

**Démarrage rapide (outils Docker — fonctionne toujours) :**
```bash
docker compose --profile jog-hu up -d
```

**Démarrer le serveur hôte (recherche IA — IP résidentielle requise) :**
```bash
# Fonctionne sur : bureau ou ordinateur portable personnel/professionnel (Windows, macOS, Linux)
# Ne fonctionne PAS sur : serveurs cloud/VPS (adresses IP de datacentre bloquées par reCAPTCHA)
# Affichage graphique NON requis — fonctionne en mode headless

pip install mcp fastmcp httpx playwright playwright-stealth
playwright install chromium

python3 mcps/jog-hu/host_server.py --background   # démarrer en daemon, port 4312
python3 mcps/jog-hu/host_server.py --stop          # arrêter le daemon
```

**Ajouter dans `mcps.yaml` :**
```yaml
- name: jog-hu
  url: http://jog-hu-mcp:4302/mcp/
  description: Hungarian legal search (njt.hu)

# Optionnel — uniquement si host_server.py est en cours d'exécution :
- name: jog-hu-host
  url: http://host.docker.internal:4312/mcp/
  description: Hungarian legal AI search (jog.gov.hu)
```

Ajoutez `jog-hu` (et optionnellement `jog-hu-host`) à la liste `tools:` d'un agent dans `agents.yaml`.
