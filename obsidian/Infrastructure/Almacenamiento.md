---
tags: [infraestructura, nfs, storage, almacenamiento]
---

# Almacenamiento NFS

## Servidor NFS

| Parámetro | Valor |
|---|---|
| Servidor | `10.0.0.9` |
| Export | `/storage` |
| Mount local | `/mnt/storage` |

## Opciones de montaje

```
rw, soft, x-systemd.automount
rsize=131072, wsize=131072
```

- `rsize/wsize = 131072` (128 KB) — optimizado para throughput
- `x-systemd.automount` — montaje automático bajo demanda
- `soft` — falla suavemente ante timeouts (no bloquea)

## Playbook

`ubu2404/modules/nfs.yml` — instala `nfs-common` y crea el mount en `/etc/fstab`.

## Estructura de directorios en NFS

```
/mnt/storage/
├── Plex/
│   └── Videos/
│       ├── Movies/         ← Radarr
│       └── TV Shows/       ← Sonarr
├── Videos/                 ← Videos generales (Plex)
├── Photos/                 ← Syncthing
├── Downloads/
│   └── transmission/       ← Transmission torrent client
└── pihole/                 ← Configuración Pi-Hole sincronizada
```

## Servicios que usan NFS

| Servicio | Ruta |
|---|---|
| [[../Services/Plex\|Plex]] | `/mnt/storage/Plex`, `/mnt/storage/Videos` |
| [[../Services/Torrents\|Radarr]] | `/mnt/storage/Plex/Videos/Movies` |
| [[../Services/Torrents\|Sonarr]] | `/mnt/storage/Plex/Videos/TV Shows` |
| [[../Services/Torrents\|Transmission]] | `/mnt/storage/Downloads/transmission` |
| [[../Services/Syncthing\|Syncthing]] | `/mnt/storage/Photos`, `/mnt/storage/Videos` |
| [[../Services/Pi-Hole + WireGuard\|Pi-Hole]] | `/mnt/storage/pihole` |

## Storage local persistente (por servicio)

Cada servicio mantiene sus datos en el host local bajo `/var/docker-data/`:

```
/var/docker-data/
├── npm/                    ← Nginx Proxy Manager (certs, DB)
├── torrents/               ← Prowlarr, Radarr, Sonarr configs
│   ├── prowlarr/
│   ├── radarr/
│   ├── sonarr/
│   └── transmission/
└── ext-www/                ← Nextcloud, WordPress, MariaDB
    ├── mysql/
    ├── nextcloud/
    └── wordpress/
```
