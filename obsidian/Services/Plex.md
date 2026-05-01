---
tags: [servicio, plex, media, streaming, docker, gpu]
---

# Plex Media Server

Servidor de streaming multimedia con transcodificación por hardware.

## Datos del servicio

| Parámetro | Valor |
|---|---|
| **Host** | `alphaprime.sismonda.local` |
| **Imagen** | `plexinc/pms-docker` |
| **Playbook** | `ubu2404/plex/plex.yml` |
| **Compose** | `/opt/docker/plex/compose.yml` |
| **Advertise IP** | `10.0.0.11:32400` |

## Puertos

| Puerto | Función |
|---|---|
| `32400` | Plex Media Server (principal) |
| `32469` | DLNA |
| `3005` | Plex Companion |
| `8324` | Roku via Plex Companion |

## GPU — Transcodificación por hardware

```yaml
devices:
  - /dev/dri    # Intel/AMD GPU para transcodificación HW
```

## Volúmenes

| Volumen | Ruta local | Contenido |
|---|---|---|
| config | `./config` | Base de datos, metadata, thumbnails |
| media1 | `/mnt/storage/Plex/Videos` | Películas y series (via NFS) |
| media2 | `/mnt/storage/Videos` | Videos adicionales (via NFS) |

Ver [[../Infrastructure/Almacenamiento|Almacenamiento NFS]] para detalles del mount.

## Integración con stack de torrents

El contenido se descarga automáticamente via [[Torrents|stack Arr]]:
- **Radarr** → `/mnt/storage/Plex/Videos/Movies`
- **Sonarr** → `/mnt/storage/Plex/Videos/TV Shows`

Plex monitorea estas carpetas y actualiza la biblioteca automáticamente.

## Systemd

Servicio: `plex.service`
```
WorkingDirectory=/opt/docker/plex/
ExecStart=/usr/bin/docker compose up -d
```
