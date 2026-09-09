---
tags: [servicio, ai, llm, ollama, gpu, docker]
---

# Ollama — Inferencia AI/LLM

Servidor de inferencia para modelos de lenguaje (LLM) con aceleración GPU AMD (ROCm).

## Datos del servicio

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
OLLAMA_NUM_CTX: 65536          # ventana de contexto por defecto (64k)
```

## Variantes de contexto por modelo

Algunos modelos requieren una ventana de contexto distinta a la default del servidor. Se crean como tags separados con `PARAMETER num_ctx` (ver `./do.sh models_hermes` / `models_opencode` y la función interna `_prepare_ctx` en `do.sh`), sin modificar el modelo base:

| Sufijo | num_ctx | Uso |
|---|---|---|
| `-64k` | 65536 | Default general (Hermes Agent, uso normal) |
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
