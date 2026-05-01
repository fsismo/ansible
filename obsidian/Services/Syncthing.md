---
tags: [servicio, syncthing, sync, archivos, docker]
---

# Syncthing — Sincronización de Archivos

Sincronización P2P de archivos entre dispositivos (sin servidor central en la nube).

## Datos del servicio

| Parámetro | Valor |
|---|---|
| **Host** | `alphaprime-dev.sismonda.local` |
| **Imagen** | `syncthing/syncthing` |
| **Playbook** | `ubu2404/syncthing/syncthing.yml` |
| **Compose** | `/opt/docker/syncthing/compose.yml` |

## Puertos

| Puerto | Protocolo | Función |
|---|---|---|
| `8384` | TCP | WebUI |
| `22000` | TCP/UDP | Transferencia de archivos |
| `21027` | UDP | Discovery de dispositivos |

## Volúmenes sincronizados

| Volumen | Ruta | Contenido |
|---|---|---|
| config | `./config` | Configuración Syncthing |
| Photos | `/mnt/storage/Photos` | Fotos (via NFS) |
| Videos | `/mnt/storage/Videos` | Videos (via NFS) |

## Systemd

Servicio: `syncthing.service`
```
WorkingDirectory=/opt/docker/syncthing/
ExecStart=/usr/bin/docker compose up -d
```

> Nota: Actualmente en `alphaprime-dev` (host comentado en inventario). Mover a `alphaprime` si se activa ese host.
