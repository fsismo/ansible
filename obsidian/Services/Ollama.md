---
tags: [servicio, ai, llm, ollama, gpu, docker]
---

# Ollama — Inferencia AI/LLM

Servidor de inferencia para modelos de lenguaje (LLM) con aceleración GPU AMD (ROCm).

Hay dos instancias independientes, cada una con su propio playbook y su propio `/opt/docker/ollama/`:

| Instancia | Host | Alcance |
|---|---|---|
| Stack completo | `alphaprime.sismonda.local` | Ollama + Open-WebUI + ComfyUI + Tika |
| Solo servidor | `blackmamba.sismonda.local` | Únicamente el contenedor `ollama` (sin WebUI ni herramientas asociadas) |

El resto de esta página documenta el stack completo de **alphaprime**. Ver [[#Instancia — blackmamba (solo servidor)]] para la instancia reducida.

## Datos del servicio (alphaprime)

| Parámetro | Valor |
|---|---|
| **Host** | `alphaprime.sismonda.local` |
| **Imagen Ollama** | `ollama/ollama:rocm` |
| **Imagen WebUI** | `ghcr.io/open-webui/open-webui:main` |
| **Imagen ComfyUI** | `yanwk/comfyui-boot:rocm` |
| **Imagen Tika** | `apache/tika:latest-full` |
| **Playbook** | `ubu2404/ollama/ollama.yml` |
| **Compose** | `/opt/docker/ollama/compose.yml` |

## Puertos

| Puerto | Servicio |
|---|---|
| `11434` | Ollama API |
| `3000` | Open-WebUI (interfaz web) |
| `8188` | ComfyUI (generación de imágenes) |
| `9998` | Tika (extracción de contenido, solo interno) |

## GPU — AMD ROCm

```yaml
devices:
  - /dev/kfd    # KFD (Kernel Fusion Driver)
  - /dev/dri    # Direct Rendering Infrastructure
environment:
  HSA_OVERRIDE_GFX_VERSION: 12.0.0   # fuerza arquitectura GPU para ROCm
  ROCR_VISIBLE_DEVICES: 0
```

## Optimizaciones de inferencia

```yaml
OLLAMA_FLASH_ATTENTION: true    # reduce uso de VRAM con Flash Attention
OLLAMA_KV_CACHE_TYPE: q8_0     # cuantización del KV cache (menor VRAM, mínima pérdida)
OLLAMA_DEBUG: 0
OLLAMA_CONTEXT_LENGTH: 32768   # ventana de contexto por defecto (32k)
```

> **`OLLAMA_NUM_CTX` no es una variable de entorno real de Ollama** (se
> confunde con el campo `num_ctx` de `options` en `/api/generate`, o con el
> `PARAMETER num_ctx` de un Modelfile). Estuvo puesta así en este compose
> — sin error, sin warning, simplemente no hace nada — y el servidor corría
> con el default real de Ollama (`4096`) sin que se notara hasta que se
> comparó `ollama ps` (columna `CONTEXT`) contra lo que decía el compose.
> Encontrado y corregido el 2026-09-16 desde una sesión de ianews que
> necesitaba diagnosticar por qué el modelo daba respuestas raras con
> cuerpos de nota largos.

## Variantes de contexto por modelo

Algunos modelos requieren una ventana de contexto distinta a la default del servidor. Se crean como tags separados con `PARAMETER num_ctx` (ver `./do.sh models_opencode` y la función interna `_prepare_ctx` en `do.sh`), sin modificar el modelo base:

| Sufijo | num_ctx | Uso |
|---|---|---|
| `-64k` | 65536 | Default general (uso normal) — variantes ya creadas; sin shortcut dedicado en `do.sh` (se removió `models_hermes`), usar `_prepare_ctx 65536 64k` manualmente si hace falta una nueva |
| `-128k` | 131072 | Pruebas puntuales de contexto extendido (ej. `gemma4:latest-128k`) |

Tras un `models_update`, las variantes con sufijo `-<N>k` se reconstruyen automáticamente a partir del modelo base actualizado, preservando su `num_ctx`.

## Acceso desde extensiones de Chrome

Ollama rechaza requests cuyo header `Origin` no esté permitido, aunque el permiso de Chrome esté otorgado. Para habilitar el acceso desde una extensión de Chrome específica:

```yaml
OLLAMA_ORIGINS: chrome-extension://ekkbhfkioekacopempfeffdmflhcocnf
```

Para permitir cualquier extensión (menos seguro): `OLLAMA_ORIGINS=chrome-extension://*`. Para múltiples orígenes, separar con comas.

## Almacenamiento

```
/opt/docker/ollama/
├── ollama/         ← modelos descargados (varios GB por modelo)
├── open-webui/     ← historial de chats, configuración de usuarios
└── comfyui/        ← modelos SD, outputs, custom nodes (/root dentro del contenedor)
```

> Los modelos se guardan **localmente** en el host (no en NFS) para mayor velocidad de carga.

## Variables de entorno requeridas

Crear `/opt/docker/ollama/.env`:

```
WEBUI_SECRET_KEY=<clave-aleatoria-segura>
```

## ComfyUI

Interfaz node-based para generación de imágenes con Stable Diffusion, acelerada por GPU AMD ROCm.

- URL interna: `http://alphaprime:8188`
- Modelos SD en: `/opt/docker/ollama/comfyui/ComfyUI/models/`
- Outputs en: `/opt/docker/ollama/comfyui/ComfyUI/output/`
- Custom nodes en: `/opt/docker/ollama/comfyui/ComfyUI/custom_nodes/`

## Open-WebUI

Interfaz web para interactuar con Ollama:
- URL interna: `http://alphaprime:3000`
- Conecta a Ollama via `http://ollama:11434` (red Docker interna)
- Funcionalidades: chat, gestión de modelos, historial por usuario
- Extracción de documentos (PDF, DOCX, etc.) delegada a Tika via `http://tika:9998`

## Tika

Servicio de extracción de contenido para Open-WebUI. Permite indexar y consultar documentos en RAG.
- Sin puerto expuesto al host (solo interno en `ai-stack`)
- Sin estado: no requiere volúmenes persistentes
- Integración configurada con `CONTENT_EXTRACTION_ENGINE=tika` y `TIKA_SERVER_URL=http://tika:9998`

## Gestión con `do.sh`

```bash
./do.sh start           # inicia los contenedores
./do.sh stop            # detiene los contenedores
./do.sh upgrade         # pull de imágenes + recrear contenedores
./do.sh models_list     # lista modelos instalados
./do.sh model_pull      # descarga un modelo nuevo (pide nombre interactivo)
./do.sh model_pull qwen2.5  # descarga modelo específico
./do.sh models_update   # actualiza todos los modelos instalados
./do.sh model_rm        # elimina un modelo (menú interactivo)
```

## Systemd

Servicio: `ollama.service`
```
WorkingDirectory=/opt/docker/ollama/
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
```

## Instancia — blackmamba (solo servidor)

Deploy reducido: únicamente el contenedor `ollama`, sin Open-WebUI/ComfyUI/Tika. Pensado como segundo nodo de inferencia AMD ROCm independiente de alphaprime.

| Parámetro | Valor |
|---|---|
| **Host** | `blackmamba.sismonda.local` (`10.0.0.13`) |
| **Imagen** | `ollama/ollama:rocm` |
| **Playbook** | `ubu2404/ollama-blackmamba/ollama-blackmamba.yml` |
| **Compose** | `/opt/docker/ollama/compose.yml` (en blackmamba) |
| **Update** | `ubu2404/ollama-blackmamba/update-ollama-blackmamba.yml` — cron sábados 22:50 (ver [[../Playbooks/Actualizaciones Automáticas|Actualizaciones Automáticas]]) |

Puertos: solo `11434` (API Ollama). Sin `3000`/`8188`/`9998`.

GPU: blackmamba tiene una única GPU, la Strix (Radeon 880M/890M) integrada — la misma familia que usa el contenedor `comfyui` en alphaprime (`gfx1150`, no la discreta RX 9060 XT del `ollama` de alphaprime). Por eso el override es distinto al del `ollama.yml` de alphaprime:

```
HSA_OVERRIDE_GFX_VERSION=11.0.0   # gfx1150 (Strix 880M/890M) — igual override que comfyui en alphaprime
ROCR_VISIBLE_DEVICES=0            # única GPU del host
OLLAMA_IGPU_ENABLE=1              # Ollama descarta las iGPU por defecto; sin esto cae a CPU (ver nota)
OLLAMA_FLASH_ATTENTION=true
OLLAMA_KV_CACHE_TYPE=q8_0
OLLAMA_DEBUG=0
OLLAMA_CONTEXT_LENGTH=32768
```

Variables de entorno: mismas optimizaciones que alphaprime, sin `OLLAMA_ORIGINS` porque no hay WebUI/extensión detrás.

> **`OLLAMA_IGPU_ENABLE=1` es obligatorio acá.** Ollama (≥0.34) descarta automáticamente las GPU integradas ("dropping integrated GPU; to enable, set OLLAMA_IGPU_ENABLE=1") y cae a CPU — se detectó en el primer deploy de prueba (`default_num_ctx=4096`, `total_vram=0B`, inference compute `id=cpu`). Con la variable seteada, Ollama reconoce la Radeon 890M como `type=iGPU total="32.0 GiB"` (VRAM unificada) y sube el contexto default a 32768. No aplica en alphaprime porque ahí Ollama usa la GPU discreta (no es una iGPU).

Estado de blackmamba (Ubuntu 26.04.1 LTS): Docker 29.1.3, `/mnt/storage` (NFS) montado. Onboarding Ansible completado el 2026-09-16 — usuario `ansible` (uid/gid 1001, igual que alphaprime) creado, sudoers `NOPASSWD: ALL`, clave pública de `ansible@alphaprime` autorizada, más `systemd-resolved.yml` y `local-ca.yml` aplicados (`--limit blackmamba.sismonda.local`).

**Deploy verificado el 2026-09-16**: `ollama-blackmamba.yml` corrido dos veces (la primera sin `OLLAMA_IGPU_ENABLE`, corregido y re-aplicado); contenedor `healthy`, prueba de inferencia con `qwen2.5:0.5b` corrió `100% GPU` (`ollama ps`), modelo de prueba eliminado después.

Modelos en `/opt/docker/ollama/ollama/` (local al host, no NFS). Gestión con el mismo `do.sh` que alphaprime (`start`, `stop`, `upgrade`, `models_list`, `model_pull`, `model_rm`, `models_update`, `models_opencode`).
