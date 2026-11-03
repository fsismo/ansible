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

`ubu2404/modules/nfs.yml` — instala `nfs-common`, crea el mount en `/etc/fstab` e instala las protecciones de la sección siguiente. Lo incluyen `ubu2404/basic/basic.yml` y `ubu2404/ext-www/ext-www.yml`.

## Recuperación tras un corte de luz

Después de un corte, el host puede arrancar antes que la red o que el NAS. Si eso pasa, el automount falla varias veces seguidas, queda en `mount-start-limit-hit` y systemd no lo reintenta aunque el NFS vuelva. Dos piezas lo cubren:

| Pieza | Qué hace |
|---|---|
| `nfs-automount-recover.timer` + `/usr/local/sbin/nfs-automount-recover` | Cada minuto, si `mnt-storage.automount` está en `failed` y `/mnt/storage` no está montado, hace `reset-failed` y lo vuelve a arrancar |
| `ubu2404/modules/network-online.yml` | Habilita `systemd-networkd-wait-online` para la interfaz principal, con timeout de 60 s, para que `network-online.target` signifique que hay ruta |

Habilitar `wait-online` no alcanza en los hosts con `optional: true` en netplan: netplan agrega una condición que lo saltea y esa interfaz no cuenta para "online". Por eso hay un drop-in, `50-interfaz-principal.conf`, que anula esa condición y nombra la interfaz. Con NetworkManager el módulo no hace nada.

Estas piezas no reemplazan los reintentos: un NAS lento puede responder después de que la red ya esté lista. Los servicios que usan el NFS tienen que tolerar que no esté al arrancar. Ver [[../Services/Nextcloud y WordPress#Arranque sin NFS|ext-www → Arranque sin NFS]].

**Dónde está aplicado:** solo en rbpi5002 (2026-11-03). El resto de los hosts lo recibe al correr `basic.yml`.

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
| [[../Services/Torrents\|Bazarr]] | `/mnt/storage/Plex/Videos/Movies`, `/mnt/storage/Plex/Videos/TV Shows` |
| [[../Services/Torrents\|Transmission]] | `/mnt/storage/Downloads/transmission` |
| [[../Services/Syncthing\|Syncthing]] | `/mnt/storage/Photos`, `/mnt/storage/Videos` |
| [[../Services/Pi-Hole + WireGuard\|Pi-Hole]] | `/mnt/storage/pihole` |
| [[../Services/AudioBookShelf\|AudioBookShelf]] | `/mnt/storage/Downloads/AudioLibros` |

## Storage local persistente (por servicio)

Cada servicio mantiene sus datos en el host local bajo `/var/docker-data/`:

```
/var/docker-data/
├── npm/                    ← Nginx Proxy Manager (certs, DB)
├── torrents/               ← Prowlarr, Radarr, Sonarr, Bazarr configs
│   ├── prowlarr/
│   ├── radarr/
│   ├── sonarr/
│   ├── bazarr/
│   └── transmission/
├── ext-www/                ← Nextcloud, WordPress, MariaDB, AudioBookShelf
│   ├── mysql/
│   ├── nextcloud/
│   ├── wordpress/
│   └── audiobookshelf/
├── zot/                    ← Zot OCI Registry — blobs y manifests (rbpi4002)
└── ianews/                 ← compartido entre piezas del proyecto ianews (rbpi4004)
    └── scraper/
        └── output/         ← JSON por nota, dedup
```
