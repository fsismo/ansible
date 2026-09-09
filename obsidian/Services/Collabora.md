---
tags: [servicio, collabora, nextcloud, docker, office]
---

# Collabora Online

Editor de documentos en línea integrado con Nextcloud.

## Datos del servicio

| Parámetro | Valor |
|---|---|
| **Host** | `alphaprime.sismonda.local` |
| **Playbook** | `ubu2404/collabora/collabora.yml` |
| **Update** | `ubu2404/collabora/update-collabora.yml` |
| **Compose** | `/opt/docker/collabora/compose.yml` |
| **Imagen** | `collabora/code:latest` |

## Puertos expuestos

| Puerto | Función |
|---|---|
| `9980` | WebSocket / API Collabora |

## Volúmenes y almacenamiento

Sin volúmenes persistentes. El servicio es stateless.

## Dependencias

- **Nextcloud** (`rbpi5002`) — integración vía WOPI protocol
- Nextcloud debe tener configurado `collabora.sismonda.com.ar` como servidor CODE

## Configuración

| Variable | Valor |
|---|---|
| `domain` | `nextcloud.sismonda.com.ar` |
| `server_name` | `collabora.sismonda.com.ar` |
| `dictionaries` | `es_AR es_ES en_GB en_US` |
| `TZ` | `America/Argentina/Buenos_Aires` |

### `.env` requerido

El playbook aborta si no existe `/opt/docker/collabora/.env`. Crearlo manualmente en el host (no se commitea):

```
COLLABORA_PASSWORD=<clave-del-panel-admin>
```

El usuario del panel admin es `admin` (fijo en el compose.yml); la contraseña sale de `COLLABORA_PASSWORD`.

## Systemd

Servicio: `collabora.service`

```
WorkingDirectory=/opt/docker/collabora/
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
```
