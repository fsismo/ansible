---
tags: [servicio, audiolibros, media, docker]
---

# AudioBookShelf — Servidor de audiolibros y podcasts

Servidor self-hosted para organizar y reproducir audiolibros (y podcasts), con apps cliente y web player.

Corre como un contenedor más dentro del stack [[Nextcloud y WordPress|ext-www]] (rbpi5002), junto a Nextcloud, WordPress, MariaDB y la NPM interna. No tiene systemd unit ni compose propios.

## Datos del servicio

| Parámetro | Valor |
|---|---|
| **Host** | `rbpi5002.sismonda.local` |
| **Imagen** | `ghcr.io/advplyr/audiobookshelf:2.36.0` |
| **Playbook** | `ubu2404/ext-www/ext-www.yml` |
| **Compose** | `/opt/docker/ext-www/compose.yml` (servicio `audiobookshelf`) |
| **IP interna** | `172.31.0.24` |

## Puertos

No publica puertos al host. Se accede vía la NPM interna del stack `ext-www` (`172.31.0.11`), que enruta por nombre de contenedor sobre la red Docker `172.31.0.0/24`, igual que Nextcloud y WordPress.

## Almacenamiento

```
/var/docker-data/ext-www/audiobookshelf/
├── config/         ← configuración y base de datos
└── metadata/        ← metadata, portadas, cache
```

Librería de audiolibros montada desde NFS (solo lectura/escritura para permitir escaneo y metadata embebida):
- `/mnt/storage/Downloads/AudioLibros` → `/audiobooks`

Ver [[../Infrastructure/Almacenamiento|Almacenamiento NFS]].

El contenedor corre como `user: 1000:1000` para que coincida con el dueño de los archivos en `AudioLibros` (usuario `sismo`, uid/gid 1000).

## Dependencias

- Requiere el mount NFS `/mnt/storage` (10.0.0.9:/storage), ya presente en rbpi5002 para Nextcloud/WordPress.
- Comparte systemd unit y ciclo de vida con el resto de [[Nextcloud y WordPress|ext-www]] (`ext-www.service`).

## Gestión

Como forma parte del stack `ext-www`, se administra desde `/opt/docker/ext-www/`:

```bash
docker compose ps audiobookshelf
docker compose stop audiobookshelf
docker compose pull audiobookshelf && docker compose up -d audiobookshelf
```

`./do.sh update` (en `/opt/docker/ext-www/`) actualiza **todo** el stack (Nextcloud, WordPress, MariaDB incluidos) — para actualizar solo AudioBookShelf usar el playbook de abajo, no `do.sh`.

## Systemd

Comparte el unit del stack completo:
```
WorkingDirectory=/opt/docker/ext-www/
ExecStart=/usr/bin/docker compose up -d
```

## Actualizaciones automáticas

Playbook y cron dedicados que actualizan **únicamente** el contenedor `audiobookshelf`, sin tocar el resto del stack:

- Playbook: `ubu2404/ext-www/update-audiobookshelf.yml`
- Cron: `ubu2404/ext-www/cron-update-audiobookshelf.yml` — domingos 22:45
- Log: `/var/log/ansible-update-audiobookshelf.log`

Ver [[Playbooks/Actualizaciones Automáticas]] para el flujo completo con rollback.

## Historial

Antes vivía como servicio standalone en `rbpi5001` (compose y systemd unit propios, puerto `13378` publicado directo al host). Se migró a `rbpi5002` para consolidarlo dentro del stack `ext-www` y exponerlo vía la misma cadena de reverse proxy que Nextcloud/WordPress.
