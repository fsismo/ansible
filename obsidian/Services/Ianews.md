---
tags: [servicio, docker, ianews, scraper]
updated: 2026-09-15
---

# Ianews — Scraper

Pieza "scraper" del proyecto **ianews** (agregador de noticias). El contrato de
despliegue (imagen, env vars, volúmenes) vive en el repo de la app
(`/mnt/storage/Code/ianews`), no acá — este repo solo lo consume. Ver:

- `/mnt/storage/Code/ianews/docker-compose.yml`
- `/mnt/storage/Code/ianews/wiki/Arquitectura.md` → sección "Despliegue"
- `/mnt/storage/Code/ianews/wiki/Scraper-Operacion.md` → sección "Cron"
- `/mnt/storage/Code/ianews/wiki/Decisiones.md` → sección "Imágenes Docker multi-arch y registry"

## Datos del servicio

| | |
|---|---|
| Host | `rbpi4004.sismonda.local` |
| Imagen | `registry.sismonda.local:5000/ianews-scraper:latest` (zot) |
| Playbook de despliegue | `ubu2404/ianews-scraper/ianews-scraper.yml` |
| Playbook de actualización | `ubu2404/ianews-scraper/update-ianews-scraper.yml` |
| Cron de actualización | `ubu2404/ianews-scraper/cron-update-ianews-scraper.yml` |
| Compose path | `/opt/docker/ianews/compose.yml` + `compose.override.yml` |
| Gestión | `/opt/docker/ianews/do.sh` |

**No es un servicio persistente**: el `ENTRYPOINT` del contenedor corre
`python main.py run` una vez y termina. No se levanta con `docker compose up`,
se invoca con `docker compose run --rm scraper` vía un **systemd timer**
(`ianews-scraper.timer`, cada 60 min / `OnCalendar=hourly`) que dispara
`ianews-scraper.service` (`Type=oneshot`).

## Por qué no se clonó el repo de ianews en la Pi

El `docker-compose.yml` de ianews espera correr desde la raíz de ese repo
(monta `./scraper/output` relativo). Para no clonar el repo entero en la Pi
(y tener que mantenerlo actualizado ahí), se copió el `docker-compose.yml`
**literalmente** a `/opt/docker/ianews/compose.yml` (no se edita a mano — si
el contrato cambia del lado de ianews, hay que volver a copiarlo) y se agregó
un `compose.override.yml` propio de este repo que remapea el único volumen a
storage persistente del host. `docker compose` lo mergea automático por estar
en el mismo directorio.

## Por qué `/opt/docker/ianews` y no `/opt/docker/ianews-scraper`

El `docker-compose.yml` de ianews es único para todo el proyecto (hoy solo
`scraper`; `processor`/`builder`/`publisher` se van a sumar ahí mismo a
medida que existan, ver `wiki/Arquitectura.md` del repo ianews). Por eso
`/opt/docker/ianews/` y `/var/docker-data/ianews/` son compartidos entre
piezas — **no** uno por pieza como el resto de los servicios de este repo.
Cada pieza sí tiene su propio systemd unit (`ianews-{pieza}.service/.timer`)
y su propio subdirectorio de datos (`/var/docker-data/ianews/{pieza}/`).
Se renombró desde `ianews-scraper` el 2026-09-15, antes de que hubiera otras
piezas desplegadas (sin impacto en datos: se migró `output/` preservando el
dedup).

## Puertos expuestos

Ninguno — no es un servicio de red, solo hace requests salientes.

## Volúmenes y almacenamiento

| Volumen | Contenedor | Host |
|---|---|---|
| Salida del scraper (JSON por nota, dedup) | `/app/output` | `/var/docker-data/ianews/scraper/output` |

`output/.last_run.json` tiene el resultado de la última corrida
(`nuevos`/`actualizados`/`sin_cambios`/`ya_estaban`/`errores`) — ver
`do.sh status`.

## Dependencias con otros servicios

- **Zot Registry** ([[Zot]], `rbpi4002`) — de ahí sale la imagen. Pull anónimo,
  pero el host tiene que confiar en la CA del registry:
  `ansible-playbook -i hosts utils/local-ca/local-ca.yml --limit rbpi4004.sismonda.local`
  (correr antes del primer deploy, y de nuevo si Docker se instala después que
  la CA — el playbook solo toca `/etc/docker/certs.d/` si `/etc/docker` ya existe).
- **DNS interno** (`utils/systemd-resolved.yml`) — necesario para resolver
  `registry.sismonda.local` (dominio `.local`, si no systemd-resolved lo manda
  por mDNS y falla con "server misbehaving"). rbpi4004 lo tenía pendiente al
  incorporarse: se corrió como parte de este despliegue.

## Configuración de systemd

| Unit | Tipo | Rol |
|---|---|---|
| `ianews-scraper.service` | `oneshot` | `docker compose run --rm scraper` |
| `ianews-scraper.timer` | `OnCalendar=hourly` | dispara el service cada 60 min |

`do.sh run` dispara una corrida manual (`systemctl start ianews-scraper.service`);
`do.sh logs [N]` para journal; `do.sh status` para el timer + `.last_run.json`;
`do.sh pull` para traer una imagen nueva sin esperar al cron semanal.

## Notas relevantes

- **`.env` sin secretos**: valores de producción (UA, timeouts) templados
  directamente en las vars de `ianews-scraper.yml`, versionados en este repo
  sin vault (así lo indicó el contrato de ianews — no hay credenciales).
  Se usa el mismo UA de navegador que el `.env` de desarrollo del repo ianews
  (no el `.env.example`, que trae un UA de bot) porque varios medios
  bloquean/degradan clientes no-browser.
- **Actualización de imagen** (`update-ianews-scraper.yml`) adapta el flujo
  genérico (`utils/update-template.yml`) al hecho de que no hay contenedor
  persistente: "arrancar el servicio" dispara una corrida real como
  verificación end-to-end, y se chequea el contador `errores` de
  `.last_run.json` en vez de "todos los contenedores running".
- **Primera corrida verificada** (2026-09-15): 277 notas nuevas, 1 error
  (autorecuperable — ver "Reintentos" en `/mnt/storage/Code/ianews/wiki/Scraper-Operacion.md`,
  no es un archivo de este vault).
