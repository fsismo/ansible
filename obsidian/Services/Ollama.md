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
| **Update** | `ubu2404/ollama/update-ollama.yml` — cron domingos 02:50 (ver [[#Ventana de mantenimiento]]) |

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
  ROCR_VISIBLE_DEVICES: 0   # la placa discreta; la 1 es la iGPU Strix (gfx1150), la usa comfyui
```

> **Sin `HSA_OVERRIDE_GFX_VERSION` (desde 2026-11-24).** Estaba en `12.0.0`, la arquitectura real de la RX 9060 XT (gfx1200): no cambiaba nada. La imagen `ollama/ollama:rocm` (`rocm_v7_2`) trae rocBLAS con kernels nativos `gfx1200` y `gfx1201`, y Ollama detecta la placa sola (`gfx1200 ... VRAM: 16304 MiB`). Se sacó antes del cambio por una placa AMD de 32 GB (gfx1201): con el override hubiera forzado kernels de gfx1200. Si al cambiar la placa se invierte el orden de las GPU (`rocm-smi --showproductname`), ajustar `ROCR_VISIBLE_DEVICES` acá y en `comfyui`. El aviso `rocblaslt error: Cannot read "TensileLibrary_lazy_gfx1200.dat"` no viene del override: la imagen no trae hipBLASLt para gfx1200.
>
> **Errores de memoria con la placa de 16 GB (desde 2026-11-23).** Con la imagen del 2026-11-21 (modelo de borrador para decodificación especulativa, proyector de visión y 32k de contexto), `gemma4:26b` carga en los 15,9 GiB libres pero se queda sin memoria al responder (`ROCm error: out of memory`): Ollama descarga y recarga el modelo, 7-10 s cada vez, hasta 250 veces por hora el 2026-11-24. El paso `run` de ianews pasó de 4-7 a 15-19 min. Se resuelve con la placa de 32 GB.

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

## Ventana de mantenimiento

**Domingos 02:50-03:20** (hora Argentina). El processor de ianews (rbpi4004) usa
`ollama` y `comfyui` de este host todo el día: la cadena cada 2 h (:01 de las
horas pares), `run` cada hora (:20), `clima` cada hora (:45) y `resumen`
(20:00). Medido sobre una semana de trabajos (2026-09-29 a 2026-10-06), la
franja 02:50-03:20 no tuvo ningún trabajo que use el modelo, ningún día. A
esa hora tampoco hay volumen de noticias.

`update-ollama.yml` (cron en `/etc/cron.d/update-ollama`) actualiza todo el
compose (ollama, comfyui, open-webui, tika). Diferencias con el flujo
estándar de [[../Convenciones#Playbooks de actualización|Playbooks de actualización]]:

- **El pull va antes del stop**: las imágenes ROCm pesan varios GB; bajarlas
  con los contenedores corriendo deja el corte en stop + start (~1-2 min).
  El tag `:_rollback` se toma antes del pull.
- **Verificaciones específicas**: `/api/tags` responde y lista modelos,
  `OLLAMA_CONTEXT_LENGTH` sigue en 32768 dentro del contenedor (ver la nota
  de `OLLAMA_NUM_CTX` arriba) y `/system_stats` de ComfyUI responde.

Si se pasa de las 03:20, el `run` de ianews de esa hora falla sus llamadas y
reintenta en la corrida siguiente: la cadena no se corta ante un fallo.
Open-WebUI también se reinicia (está en el mismo compose).

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

GPU: blackmamba tiene una única GPU, la Strix (Radeon 880M/890M) integrada — la misma familia que usa el contenedor `comfyui` en alphaprime (`gfx1150`, no la discreta RX 9060 XT del `ollama` de alphaprime). El override de arquitectura que se usaba ya no hace falta (ver nota abajo):

```
ROCR_VISIBLE_DEVICES=0            # única GPU del host
OLLAMA_IGPU_ENABLE=1              # Ollama descarta las iGPU por defecto; sin esto cae a CPU (ver nota)
OLLAMA_FLASH_ATTENTION=true
OLLAMA_KV_CACHE_TYPE=q8_0
OLLAMA_DEBUG=0
OLLAMA_CONTEXT_LENGTH=65536       # 64k para agentes (OpenCode)
OLLAMA_KEEP_ALIVE=30m             # no descargar el modelo entre turnos del agente
OLLAMA_NUM_PARALLEL=2             # 2 slots de KV para subagentes (el KV se duplica)
OLLAMA_MAX_LOADED_MODELS=1        # un solo modelo en VRAM
```

> **Sin `HSA_OVERRIDE_GFX_VERSION` (desde 2026-11-08).** La imagen `ollama/ollama:rocm` (Ollama 0.40.13, `rocm_v7_2`) compila `libggml-hip.so` y rocBLAS con kernels nativos `gfx1150`/`gfx1151`. El override `11.0.0` que se usaba antes forzaba kernels gfx1100 (RDNA3 discreta). Sin override, Ollama detecta `library=ROCm compute=gfx1150 "AMD Radeon 890M Graphics" type=iGPU total="48.0 GiB"` (GTT, ver abajo) y la inferencia corre `100% GPU`. Si una imagen futura deja de traer gfx1150, volver a `HSA_OVERRIDE_GFX_VERSION=11.0.0`.

### Memoria de la GPU (GTT)

La 890M no reserva memoria en la BIOS: el UMA Frame Buffer está en **1 GB** (mínimo práctico, alcanza para el escritorio) y la GPU usa **48 GiB de GTT**, RAM del sistema que toma a medida que la necesita. Sin modelo cargado Ubuntu ve ~60 GiB; con 32 GiB de carve-out veía ~30.

El kernel limita la GTT por defecto a la mitad de la RAM. El playbook la sube con parámetros de TTM en `/etc/default/grub.d/90-amdgpu-gtt.cfg` (variable `gtt_gib`, en páginas de 4 KiB: `48 * 1024 * 1024 / 4 = 12582912`):

```
ttm.pages_limit=12582912 ttm.page_pool_size=12582912
```

El playbook corre `update-grub` pero **no reinicia**: el cambio aplica en el próximo arranque. Si estaban cargados a mano en `/etc/default/grub`, los quita de ahí para no duplicarlos. Verificar después de reiniciar:

```bash
grep -o 'ttm[^ ]*' /proc/cmdline
awk '{print $1/1024/1024/1024 " GiB"}' /sys/class/drm/card*/device/mem_info_vram_total /sys/class/drm/card*/device/mem_info_gtt_total   # 1 GiB / 48 GiB
docker logs ollama 2>&1 | grep "inference compute"                                                                                # total="48.0 GiB"
```

`rocm-smi` muestra en «VRAM%» solo el 1 GB de la BIOS; para la GTT: `rocm-smi --showmeminfo vram gtt`.

Rendimiento GTT vs carve-out (gemma-4-26B-A4B IQ4_XS, mismo prompt, 64k ctx, 2026-11-11): 19,78 y 19,67 tok/s con 48 GiB de GTT contra 21,37 con 32 GiB de carve-out (~7–8 % menos), a cambio de 16 GiB más para la GPU y la RAM libre para el sistema cuando no hay modelo cargado.

### Dimensionamiento para agentes (64k de contexto)

Memoria de la GPU: 48 GiB de GTT (ver arriba). KV cache q8_0 a 64k medido/calculado: flint ~0,9 GiB (14 de 49 capas con atención completa, el resto sliding window de 513), Qwen3-Coder-30B-A3B ~3,2 GiB. Con modelos MoE de ~22 GB el total queda en ~25 GiB de 48.

Benchmark 2026-11-08 (con 32 GiB de carve-out UMA, antes del cambio a GTT; 64k ctx, KV q8_0, todos `100% GPU`):

| Modelo | VRAM | Gen tok/s | Prompt ~12k tok/s |
|---|---|---|---|
| `flint:40b` (MoE 2,5B activos) | 21,0 GiB | 31,6 | 406 |
| `hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q4_K_XL` | 19,7 GiB | 30,0 | 455 |
| `ornith-1.5:35b` (35B-A3B) | 20,6 GiB | 26,2 | 501 |
| `nemotron-3.5-lightning:30b` | 23,8 GiB | 24,6 | 394 |
| gemma-4-26B-A4B IQ4_XS | 14,1 GiB | 23,0 | 433 |
| `qwen3.8:27b` (denso) | 16,6 GiB | 6,9 | 110 |

Los modelos densos son ~4–5x más lentos en esta iGPU (limitada por ancho de banda de memoria): para agentes usar MoE.

Variables de entorno: mismas optimizaciones que alphaprime, sin `OLLAMA_ORIGINS` porque no hay WebUI/extensión detrás.

> **`OLLAMA_IGPU_ENABLE=1` es obligatorio acá.** Ollama (≥0.34) descarta automáticamente las GPU integradas ("dropping integrated GPU; to enable, set OLLAMA_IGPU_ENABLE=1") y cae a CPU — se detectó en el primer deploy de prueba (`default_num_ctx=4096`, `total_vram=0B`, inference compute `id=cpu`). Con la variable seteada, Ollama reconoce la Radeon 890M como `type=iGPU` (en ese momento `total="32.0 GiB"` del carve-out; hoy 48 GiB de GTT) y sube el contexto default a 32768 (sobrescrito a 65536 por `OLLAMA_CONTEXT_LENGTH`). No aplica en alphaprime porque ahí Ollama usa la GPU discreta (no es una iGPU).

Estado de blackmamba (Ubuntu 26.04.1 LTS): Docker 29.1.3, `/mnt/storage` (NFS) montado. Onboarding Ansible completado el 2026-09-16 — usuario `ansible` (uid/gid 1001, igual que alphaprime) creado, sudoers `NOPASSWD: ALL`, clave pública de `ansible@alphaprime` autorizada, más `systemd-resolved.yml` y `local-ca.yml` aplicados (`--limit blackmamba.sismonda.local`).

**Deploy verificado el 2026-09-16**: `ollama-blackmamba.yml` corrido dos veces (la primera sin `OLLAMA_IGPU_ENABLE`, corregido y re-aplicado); contenedor `healthy`, prueba de inferencia con `qwen2.5:0.5b` corrió `100% GPU` (`ollama ps`), modelo de prueba eliminado después.

Modelos en `/opt/docker/ollama/ollama/` (local al host, no NFS). Gestión con el mismo `do.sh` que alphaprime (`start`, `stop`, `upgrade`, `models_list`, `model_pull`, `model_rm`, `models_update`, `models_opencode`).
