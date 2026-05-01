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
| **Playbook** | `ubu2404/ollama/ollama.yml` |
| **Compose** | `/opt/docker/ollama/compose.yml` |

## Puertos

| Puerto | Servicio |
|---|---|
| `11434` | Ollama API |
| `3000` | Open-WebUI (interfaz web) |

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
```

## Almacenamiento

```
/opt/docker/ollama/
├── ollama/         ← modelos descargados (varios GB por modelo)
└── open-webui/     ← historial de chats, configuración de usuarios
```

> Los modelos se guardan **localmente** en el host (no en NFS) para mayor velocidad de carga.

## Variables de entorno requeridas

Crear `/opt/docker/ollama/.env`:

```
WEBUI_SECRET_KEY=<clave-aleatoria-segura>
```

## Open-WebUI

Interfaz web para interactuar con Ollama:
- URL interna: `http://alphaprime:3000`
- Conecta a Ollama via `http://ollama:11434` (red Docker interna)
- Funcionalidades: chat, gestión de modelos, historial por usuario

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
