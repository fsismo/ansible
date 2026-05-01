---
tags: [convenciones, guidelines, ansible, docker]
---

# Convenciones del Proyecto

Reglas y estándares definidos en `.continue/rules/context.md`.

## Estructura de directorios

Los playbooks se organizan por funcionalidad dentro de `ubu2404/`:

```
ubu2404/
├── {servicio}/
│   ├── {servicio}.yml          ← playbook principal
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
