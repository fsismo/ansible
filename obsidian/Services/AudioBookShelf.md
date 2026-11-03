---
tags: [servicio, audiolibros, media, docker]
---

# AudioBookShelf — Servidor de audiolibros y podcasts

Servidor self-hosted para organizar y reproducir audiolibros (y podcasts), con apps cliente y web player.

Corre dentro del stack [[Nextcloud y WordPress|ext-www]] (rbpi5002), junto a Nextcloud, WordPress, MariaDB y la NPM interna. Comparte el compose, pero tiene systemd unit propio para que su dependencia del NFS no frene al resto del stack.

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
- Lo arranca `ext-www.service` ([[Nextcloud y WordPress|ext-www]]) y se baja junto con él. Si AudioBookShelf falla, el resto del stack sigue funcionando.

## Gestión

Como forma parte del stack `ext-www`, se administra desde `/opt/docker/ext-www/`:

```bash
docker compose ps audiobookshelf
docker compose stop audiobookshelf
docker compose pull audiobookshelf && docker compose up -d audiobookshelf
```

Hay que nombrar el servicio: tiene el perfil `nfs`, así que un `docker compose up -d` sin argumentos no lo levanta.

`./do.sh update` (en `/opt/docker/ext-www/`) actualiza **todo** el stack (Nextcloud, WordPress, MariaDB incluidos), salvo la imagen de AudioBookShelf, a la que no le hace `pull`. Sí reinicia su contenedor. Para actualizarlo usar el playbook de abajo.

## Systemd

Servicio: `ext-www-audiobookshelf.service` (`/etc/systemd/system/`)
```
Requires=docker.service
After=docker.service ext-www.service
PartOf=ext-www.service
StartLimitIntervalSec=0
WorkingDirectory=/opt/docker/ext-www/
ExecStartPre=/usr/bin/timeout 30 /usr/bin/stat /mnt/storage/Downloads/AudioLibros
ExecStart=/usr/bin/docker compose up -d audiobookshelf
ExecStop=/usr/bin/docker compose rm -s -f audiobookshelf
Restart=on-failure
RestartSec=30
```

- **`ExecStop` con `rm`, no `stop`:** el `docker compose down` de `ext-www` borra la red, pero no un contenedor con perfil que ya esté detenido. Ese contenedor viejo después no arranca (`network ... not found`). Los datos no se pierden: están en `/var/docker-data/ext-www/audiobookshelf/` y en el NFS.

- **Reintentos:** mientras el NFS no esté disponible, reintenta cada 30 s sin límite y arranca solo cuando vuelve.
- **`ExecStartPre`:** evita que Docker cree la ruta en el disco local si el NFS no está montado, lo que dejaría la librería vacía.
- **Sin `[Install]`, a propósito:** figura como `static` y lo arranca `ext-www.service` con `Wants=`. Si colgara de `multi-user.target`, los reintentos dejarían el boot "en curso" mientras el NFS no esté disponible.

## Actualizaciones automáticas

Playbook y cron dedicados que actualizan **únicamente** el contenedor `audiobookshelf`, sin tocar el resto del stack:

- Playbook: `ubu2404/ext-www/update-audiobookshelf.yml`
- Cron: `ubu2404/ext-www/cron-update-audiobookshelf.yml` — domingos 22:45
- Log: `/var/log/ansible-update-audiobookshelf.log`

Ver [[Playbooks/Actualizaciones Automáticas]] para el flujo completo con rollback.

## Historial

Antes vivía como servicio standalone en `rbpi5001` (compose y systemd unit propios, puerto `13378` publicado directo al host). Se migró a `rbpi5002` para consolidarlo dentro del stack `ext-www` y exponerlo vía la misma cadena de reverse proxy que Nextcloud/WordPress.
