---
tags: [servicio, torrents, arr, radarr, sonarr, bazarr, prowlarr, transmission, docker]
---

# Torrents — Stack Arr

Stack completo de gestión automática de descargas: indexadores, gestión de películas/series y cliente torrent.

## Datos del servicio

| Parámetro | Valor |
|---|---|
| **Host** | `rbpi5001.sismonda.local` |
| **Playbook** | `ubu2404/torrents/torrents.yml` |
| **Update** | `ubu2404/torrents/update-torrents.yml` |
| **Compose** | `/opt/docker/torrents/compose.yml` |

## Contenedores

### Prowlarr — Indexer Manager

| Parámetro | Valor |
|---|---|
| Imagen | `lscr.io/linuxserver/prowlarr` |
| Puerto | `9696` |
| Función | Gestiona indexadores (trackers), los sincroniza a Radarr/Sonarr |

### Radarr — Películas

| Parámetro | Valor |
|---|---|
| Imagen | `lscr.io/linuxserver/radarr` |
| Puerto | `7878` |
| Descarga a | `/mnt/storage/Plex/Videos/Movies` |

### Sonarr — Series de TV

| Parámetro | Valor |
|---|---|
| Imagen | `lscr.io/linuxserver/sonarr` |
| Puerto | `8989` |
| Descarga a | `/mnt/storage/Plex/Videos/TV Shows` |

### Bazarr — Subtítulos

| Parámetro | Valor |
|---|---|
| Imagen | `lscr.io/linuxserver/bazarr` |
| Puerto | `6767` |
| Función | Descarga automática de subtítulos para Radarr/Sonarr |
| Bibliotecas | `/mnt/storage/Plex/Videos/Movies`, `/mnt/storage/Plex/Videos/TV Shows` |

### Transmission — Cliente Torrent

| Parámetro | Valor |
|---|---|
| Imagen | `lscr.io/linuxserver/transmission` |
| Puerto WebUI | `9091` |
| Puerto P2P | `51413/udp` |
| Descargas | `/mnt/storage/Downloads/transmission` |

### FlareSolverr — CAPTCHA Solver

| Parámetro | Valor |
|---|---|
| Imagen | `ghcr.io/flaresolverr/flaresolverr` |
| Puerto | `8191` |
| Función | Bypass de CloudFlare para indexadores que lo requieren |

## Flujo de trabajo

```
Usuario
  │
  ▼ Busca película/serie
[Radarr / Sonarr]
  │
  ├── Consulta indexadores via [Prowlarr]
  │     └── [FlareSolverr] (si hay CloudFlare)
  │
  ├── Envía torrent a [Transmission]
  │
  ▼
/mnt/storage/Plex/Videos/
  ├── [Bazarr] descarga subtítulos
  └── [Plex] detecta y agrega a biblioteca
```

## Almacenamiento

```
/var/docker-data/torrents/
├── prowlarr/       ← config y DB
├── radarr/         ← config y DB
├── sonarr/         ← config y DB
├── bazarr/         ← config y DB
└── transmission/   ← config, watchdir
```

Ver [[../Infrastructure/Almacenamiento|Almacenamiento NFS]] para rutas NFS.

## Systemd

Servicio: `torrents.service`
```
Requires=docker.service
Wants=network-online.target
After=docker.service network-online.target
StartLimitIntervalSec=0
WorkingDirectory=/opt/docker/torrents/
ExecStart=/opt/docker/torrents/do.sh start
ExecStop=/opt/docker/torrents/do.sh stop
Restart=on-failure
RestartSec=30
[Install]
WantedBy=docker.service
```

## Arranque sin NFS

Todos los servicios menos Prowlarr y FlareSolverr usan el NFS. El NAS tarda más que las Raspberry en levantar, así que el stack espera:

- **`do.sh start`, `restart` y `upgrade`** verifican `/mnt/storage/Downloads/transmission` y fallan si no está. Así Docker no crea las rutas en el disco local, lo que dejaría las carpetas vacías. `do.sh stop` no necesita el NFS.
- **`torrents.service`** reintenta cada 30 s, sin límite, hasta que el NFS aparece. Por eso ya no hace falta el `sleep 30` que tenía antes.
- **`WantedBy=docker.service`:** si colgara de `multi-user.target`, los reintentos dejarían el boot "en curso" mientras el NFS no esté disponible.
- **`update-torrents.yml`** espera hasta 300 s al iniciar el servicio. Si el NFS está caído durante el cron, hace rollback en vez de colgarse.

Ver [[../Infrastructure/Almacenamiento#Recuperación tras un corte de luz|Almacenamiento → Recuperación tras un corte de luz]].
