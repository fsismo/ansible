---
tags: [servicio, n8n, automation, workflows, docker]
---

# n8n

Plataforma de automatización de workflows (low-code) con editor visual y nodos para
integrar servicios, APIs y tareas programadas.

## Datos del servicio

| Parámetro | Valor |
|---|---|
| **Host** | `alphaprime.sismonda.local` |
| **Playbook** | `ubu2404/n8n/n8n.yml` |
| **Update** | `ubu2404/n8n/update-n8n.yml` |
| **Cron update** | `ubu2404/n8n/cron-update-n8n.yml` |
| **Compose** | `/opt/docker/n8n/compose.yml` |
| **Imagen** | `docker.n8n.io/n8nio/n8n:2.8.3` |
| **URL** | `http://n8n.sismonda.local/` |

## Puertos expuestos

| Puerto | Función |
|---|---|
| `5678` | UI web / API / webhooks |

## Volúmenes y almacenamiento

| Bind mount | Contenedor | Contenido |
|---|---|---|
| `/var/docker-data/n8n/node` | `/home/node` | Home del usuario `node`: base SQLite, credenciales, config |
| `/var/docker-data/n8n/local-files` | `/files` | Archivos locales accesibles desde workflows |

- Base de datos: **SQLite** en `/var/docker-data/n8n/node/.n8n/database.sqlite` (sin Postgres dedicado).
- Los directorios de datos son de UID/GID `1000` (el contenedor corre como usuario `node`).

> [!warning] Clave de encriptación
> `/var/docker-data/n8n/node/.n8n/config` contiene el `encryptionKey` que cifra todas
> las credenciales guardadas en n8n. **Debe respaldarse junto con la base**: si se
> pierde, todas las credenciales almacenadas quedan inutilizables.

## Configuración

Variables en `/opt/docker/n8n/.env` (no se commitea; ver `.env.example`):

| Variable | Valor |
|---|---|
| `DOMAIN_NAME` | `sismonda.local` |
| `SUBDOMAIN` | `n8n` |
| `GENERIC_TIMEZONE` | `America/Argentina/Buenos_Aires` |
| `SSL_EMAIL` | `fernando@sismonda.com.ar` |

El compose deriva `N8N_HOST`, `WEBHOOK_URL` (`http://n8n.sismonda.local/`) y `TZ` a
partir de esas variables. `N8N_PROTOCOL=http`, `NODE_ENV=production`.

## Dependencias

- Ninguna dependencia dura con otros servicios. Los workflows pueden consumir APIs
  internas (Ollama, Nextcloud, etc.) según se configuren.

## Systemd

Servicio: `n8n.service`

```
WorkingDirectory=/opt/docker/n8n
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
```

## Actualización

Automática los **domingos 22:30** vía `/etc/cron.d/update-n8n` →
`update-n8n.yml` (con rollback). Log en `/var/log/ansible-update-n8n.log`.
Ver [[../Playbooks/Actualizaciones Automáticas]].

## Notas

- El despliegue original fue manual (compose project `n8n`, contenedor `n8n-n8n-1`,
  imagen `:latest`). El playbook fija el tag `:2.8.3` y nombra el contenedor `n8n`,
  por lo que la primera corrida recrea el contenedor una vez (los datos viven en los
  bind mounts, no se pierden).
