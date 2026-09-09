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
WorkingDirectory=/opt/docker/torrents/
ExecStart=/usr/bin/docker compose up -d
```
