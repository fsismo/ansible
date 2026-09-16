---
tags: [servicio, docker, ianews, scraper, processor]
updated: 2026-09-16
---

# Ianews

Proyecto **ianews** (agregador de noticias), pipeline scraper → processor →
builder → publisher. El contrato de despliegue (imagen, env vars, volúmenes)
vive en el repo de la app (`/mnt/storage/Code/ianews`), no acá — este repo
solo lo consume. Ver:

- `/mnt/storage/Code/ianews/docker-compose.yml`
- `/mnt/storage/Code/ianews/wiki/Arquitectura.md` → sección "Despliegue"
- `/mnt/storage/Code/ianews/wiki/Scraper-Operacion.md` / `wiki/Processor.md`
- `/mnt/storage/Code/ianews/wiki/Decisiones.md`

Todas las piezas construidas hoy (**scraper**, **processor**) corren en el
mismo host y comparten un solo `/opt/docker/ianews/` (un solo `compose.yml`,
un solo `.env`) — es un único `docker-compose.yml` del lado de ianews, no uno
por pieza. Cada pieza tiene su propio systemd unit
(`ianews-{pieza}.service`/`.timer`) y su propio playbook de despliegue/
actualización/cron, pero comparten los templates y las vars en
`ubu2404/ianews/`.

## Infraestructura compartida

| | |
|---|---|
| Host | `rbpi4004.sismonda.local` |
| Compose dir | `/opt/docker/ianews/` (`compose.yml` + `compose.override.yml` + `.env` + `do.sh`) |
| Templates/vars compartidos | `ubu2404/ianews/` (sin playbook propio — `vars.yml` + `opt/docker/ianews/*`) |
| Gestión | `/opt/docker/ianews/do.sh [run|logs|pull] <scraper\|processor>`, `do.sh status` (ambas) |

**No son servicios persistentes**: cada `ENTRYPOINT` corre `python main.py run`
una vez y termina. No se levantan con `docker compose up`, se invocan con
`docker compose run --rm <pieza>` vía un **systemd timer** propio por pieza.

### Por qué no se clonó el repo de ianews en la Pi

El `docker-compose.yml` de ianews espera correr desde la raíz de ese repo
(monta `./scraper/output` relativo). Para no clonar el repo entero en la Pi
(y tener que mantenerlo actualizado ahí), se copió el `docker-compose.yml`
**literalmente** a `/opt/docker/ianews/compose.yml` (no se edita a mano — si
el contrato cambia del lado de ianews, hay que volver a copiarlo) y se agregó
un `compose.override.yml` propio de este repo que remapea el volumen
compartido a storage persistente del host. `docker compose` lo mergea
automático por estar en el mismo directorio.

### Por qué `/opt/docker/ianews` y no un directorio por pieza

El `docker-compose.yml` de ianews es único para todo el proyecto. Por eso
`/opt/docker/ianews/` es compartido entre piezas — **no** uno por pieza como
el resto de los servicios de este repo. Se renombró desde `ianews-scraper`
el 2026-09-15, antes de que existiera `processor` (sin impacto en datos: se
migró `output/` preservando el dedup). Al día de hoy: `scraper` y `processor`
comparten literalmente el mismo volumen (`/var/docker-data/ianews/scraper/output`)
porque `processor` no tiene salida propia, solo reescribe in-place los JSON
del scraper.

### Dependencias comunes

- **Zot Registry** ([[Zot]], `rbpi4002`) — de ahí salen las imágenes. Pull
  anónimo, pero el host tiene que confiar en la CA del registry:
  `ansible-playbook -i hosts utils/local-ca/local-ca.yml --limit rbpi4004.sismonda.local`
  (correr antes del primer deploy de cualquier pieza nueva, y de nuevo si
  Docker se instala después que la CA — el playbook solo toca
  `/etc/docker/certs.d/` si `/etc/docker` ya existe).
- **DNS interno** (`utils/systemd-resolved.yml`) — necesario para resolver
  `registry.sismonda.local` y `alphaprime.sismonda.local` (dominio `.local`,
  si no systemd-resolved lo manda por mDNS y falla con "server misbehaving").

---

## Pieza: Scraper

| | |
|---|---|
| Imagen | `registry.sismonda.local:5000/ianews-scraper:latest` (zot) |
| Playbook de despliegue | `ubu2404/ianews-scraper/ianews-scraper.yml` |
| Playbook de actualización | `ubu2404/ianews-scraper/update-ianews-scraper.yml` |
| Cron de actualización | `ubu2404/ianews-scraper/cron-update-ianews-scraper.yml` (sábados 23:45) |
| Systemd | `ianews-scraper.service` (`oneshot`, `docker compose run --rm scraper`) + `ianews-scraper.timer` (`OnCalendar=hourly`) |

### Volúmenes y almacenamiento

| Volumen | Contenedor | Host |
|---|---|---|
| Salida del scraper (JSON por nota, dedup) | `/app/output` | `/var/docker-data/ianews/scraper/output` |

`output/.last_run.json` tiene el resultado de la última corrida
(`nuevos`/`actualizados`/`sin_cambios`/`ya_estaban`/`errores`).

### Notas relevantes

- **`.env` sin secretos**: valores de producción (UA, timeouts) en
  `ubu2404/ianews/vars.yml` (compartido con `processor`), versionados sin
  vault (así lo indicó el contrato de ianews — no hay credenciales). Se usa
  el mismo UA de navegador que el `.env` de desarrollo del repo ianews (no el
  `.env.example`, que trae un UA de bot) porque varios medios
  bloquean/degradan clientes no-browser.
- **Actualización de imagen** adapta el flujo genérico
  (`utils/update-template.yml`) al hecho de que no hay contenedor
  persistente: "arrancar el servicio" dispara una corrida real como
  verificación end-to-end, y se chequea el contador `errores` de
  `.last_run.json` en vez de "todos los contenedores running". Como
  `compose.yml` es compartido con `processor`, el pull/tag/rollback van
  scoped a `scraper` explícitamente (`docker compose ... config --images scraper`,
  `... pull scraper`) para no tocar la imagen de la otra pieza.
- **Primera corrida verificada** (2026-09-15): 277 notas nuevas, 1 error
  (autorecuperable — ver "Reintentos" en `/mnt/storage/Code/ianews/wiki/Scraper-Operacion.md`,
  no es un archivo de este vault).
- **Umbral de error por tasa, no por conteo (2026-09-16)**: el chequeo de
  `errores` en `update-ianews-scraper.yml` pasó de "cualquier `errores>0`
  aborta" a "tasa de error sobre el total procesado > 5% aborta". Motivo:
  una URL que falla siempre (self-healing por diseño, sin caché de
  negativos) da un `errores=1` estable en cada corrida y bloqueaba **todo**
  update real con un rollback automático, no solo el que de verdad rompía
  algo — pasó en vivo el 2026-09-16 al desplegar el informe de URLs.

---

## Pieza: Processor

Primera pieza real del análisis (paso 1 de 4: entidades vía LLM). Ver
`/mnt/storage/Code/ianews/wiki/Processor.md` para el detalle de qué hace y
qué falta (clustering, redacción, sesgo — no empezados).

| | |
|---|---|
| Imagen | `registry.sismonda.local:5000/ianews-processor:latest` (zot) |
| Playbook de despliegue | `ubu2404/ianews-processor/ianews-processor.yml` |
| Playbook de actualización | `ubu2404/ianews-processor/update-ianews-processor.yml` |
| Cron de actualización | `ubu2404/ianews-processor/cron-update-ianews-processor.yml` (sábados 23:15) |
| Systemd | `ianews-processor.service` (`oneshot`, `docker compose run --rm processor`) + `ianews-processor.timer` (diario/horario a `:20`, 20' después del scraper) |

**No tiene volumen propio**: lee y reescribe **in-place** los mismos JSON del
scraper (`/var/docker-data/ianews/scraper/output`, montado igual en ambos
contenedores vía `compose.override.yml`), agregándoles la clave `entidades`.

### Dependencia: Ollama

El processor le pega a Ollama por red — **no** está en este compose, corre en
otro host: `IANEWS_OLLAMA_BASE_URL=http://alphaprime.sismonda.local:11434`
([[Ollama]]). Sin esto no hace falta ninguna config de red adicional (mismo
LAN, puerto `11434` expuesto a toda la interfaz).

### Notas relevantes

- **Primera corrida = catch-up del backlog completo**: a diferencia del
  scraper (acotado por feed), la corrida inicial del processor procesa TODO
  lo que el scraper ya había acumulado sin `entidades` — en el deploy inicial
  (2026-09-15) fueron ~786 notas a ~8-15s cada una vía Ollama (~2hs). El
  playbook de despliegue dispara esa corrida pero **no aborta** si no termina
  rápido (ver comentario en `ianews-processor.yml`) — es esperable, no un
  error. Corridas siguientes son incrementales (solo notas nuevas de esa
  hora) y rápidas.
- **Bug de Ollama (`think` + `format: "json"`)**: con `gemma4:26b-iq4xs`
  (modelo con razonamiento interno), pedir `format: "json"` sin también
  `"think": false` degenera en un loop de repetición — JSON sintácticamente
  válido pero con contenido basura. `processor/ollama_client.py` siempre
  manda `think: false`. Verificado con Ollama 0.32.6. Documentado también en
  `wiki/Decisiones.md` del repo ianews — aplica a **cualquier** llamado a
  este servidor Ollama con `format=json` sobre un modelo que razona, no es
  específico de esta pieza.
- **Idempotente por presencia**, no por contenido: si una nota "vivo" se
  re-scrapea y cambia el `cuerpo`, el processor no la vuelve a analizar.
