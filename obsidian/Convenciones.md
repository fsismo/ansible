---
tags: [convenciones, guidelines, ansible, docker]
---

# Convenciones del Proyecto

## Estructura de directorios

Los playbooks se organizan por funcionalidad dentro de `ubu2404/`:

```
ubu2404/
├── {servicio}/
│   ├── {servicio}.yml          ← despliegue inicial
│   ├── update-{servicio}.yml   ← actualización de imágenes
│   └── opt/docker/{servicio}/
│       ├── compose.yml         ← definición del stack
│       └── do.sh               ← script de gestión
```

## Reglas para Docker

| Regla | Detalle |
|---|---|
| Runtime | Docker Compose v2 (`docker compose`, no `docker-compose`) |
| Nombre del archivo | `compose.yml` (nunca `docker-compose.yml`) |
| Ubicación compose | `/opt/docker/{servicio}/compose.yml` |
| Storage persistente | `/var/docker-data/{servicio}/` |
| Script de gestión | `/opt/docker/{servicio}/do.sh` |
| Inicio del servicio | Como **systemd unit** |

## Naming y organización

- Seguir convenciones de nombres existentes en el repo
- No mezclar Docker y Containerd en el mismo playbook
- Los hosts de containerd usan `nerdctl compose` en lugar de `docker compose`

## Systemd para contenedores

Todos los servicios Docker se registran como systemd para inicio automático:

```ini
[Unit]
Description={Nombre del Servicio}
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/docker/{servicio}/
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
```

## Convenciones de storage

```
/opt/docker/{servicio}/          ← configuración y compose
/var/docker-data/{servicio}/     ← datos persistentes
/var/docker/{servicio}/          ← caché (ej: searxng)
/mnt/storage/                    ← NFS compartido (media, backups)
```

## Imágenes Docker

- Preferir imágenes de `lscr.io/linuxserver/` para servicios Arr
- Imágenes propias prefijadas con `fsismo/` (ej: `fsismo/mariadb-11-noble-auto-backups`)
- Siempre especificar tag de versión (evitar `:latest` cuando sea posible)

## Variables de entorno sensibles

Las variables sensibles (passwords, tokens) se definen en archivos `.env` junto al compose.yml y **no se commitean** al repositorio.

## Timezone

Todos los servicios usan: `America/Argentina/Buenos_Aires`

## Playbooks de actualización

Todo servicio con contenedores Docker debe incluir un `update-{servicio}.yml` junto al playbook principal. Usar `utils/update-template.yml` como punto de partida.

### Flujo obligatorio

| Paso | Acción |
|---|---|
| 1 | Log de versiones previas |
| 2 | Copiar `compose.yml` actualizado (`backup: yes`) |
| 3 | Etiquetar imágenes actuales como `:_rollback` |
| 4 | `systemctl stop` — respeta hooks de ExecStop |
| 5 | `docker_compose_v2_pull` — pull de nuevas imágenes |
| 6 | `systemctl start` — respeta hooks de ExecStartPre |
| 7 | **Verificación genérica**: todos los contenedores en estado `running` |
| 8 | Verificaciones específicas del servicio (puerto, API, DNS…) — opcionales |
| 9 | Log de versiones nuevas |
| rescue | Restaurar `compose.yml` + imágenes `:_rollback` + reiniciar + fail |

### Por qué systemctl y no docker compose directamente

`systemctl stop/start` garantiza que se ejecuten los hooks `ExecStartPre` y `ExecStop` de la unit (sincronización de datos, etc.) y que el estado de systemd quede consistente con la realidad.

### Cron job de actualización

Todo servicio con `update-{servicio}.yml` debe incluir también un `cron-update-{servicio}.yml` que instale el cron job en localhost. Usar `ubu2404/collabora/cron-update-collabora.yml` como referencia.

**Agregar una fila en [[Playbooks/Actualizaciones Automáticas]]** con el horario, el cron file y el log. Escalonar los horarios para que no coincidan con otros servicios.
