---
tags: [servicio, nextcloud, wordpress, mariadb, docker, web]
aliases: [ext-www]
---

# Nextcloud & WordPress (ext-www)

Stack de servicios web externos: cloud personal, blog y base de datos compartida.

## Datos del servicio

| Parámetro | Valor |
|---|---|
| **Host** | `rbpi5002.sismonda.local` |
| **Playbook** | `ubu2404/ext-www/ext-www.yml` |
| **Compose** | `/opt/docker/ext-www/compose.yml` |
| **Red Docker** | `172.31.0.0/24` |

## Contenedores

### MariaDB 11

| Parámetro | Valor |
|---|---|
| Imagen | `fsismo/mariadb-11-noble-auto-backups` |
| Puerto | `3306` |
| IP interna | `172.31.0.10` |
| Backups | automáticos (retención 30 días) |

Variables de entorno relevantes:
```
MARIADB_ROOT_PASSWORD: S3CR3T0
MARIADB_BACKUP_RETENTION: 30
```

### Nginx Proxy Manager (interno)

| Puerto | Función |
|---|---|
| `80` | HTTP |
| `81` | Admin WebUI |
| `443` | HTTPS |

### Nextcloud

| Parámetro | Valor |
|---|---|
| Imagen | `fsismo/ubuntu-24.04-apache-php` |
| IP interna | `172.31.0.20` |
| Storage | `/var/docker-data/ext-www/nextcloud` |

Dependencias:
- **Redis** (`172.31.0.21`) — caché de sesiones y archivos

### WordPress

| Parámetro | Valor |
|---|---|
| Imagen | `fsismo/ubuntu-24.04-apache-php` |
| IP interna | `172.31.0.22` |
| Storage | `/var/docker-data/ext-www/wordpress` |

Dependencias:
- **Redis** (`172.31.0.23`) — caché de objetos

### AudioBookShelf

| Parámetro | Valor |
|---|---|
| Imagen | `ghcr.io/advplyr/audiobookshelf:2.36.0` |
| IP interna | `172.31.0.24` |
| Storage | `/var/docker-data/ext-www/audiobookshelf` |
| Librería | `/mnt/storage/Downloads/AudioLibros` (NFS) → `/audiobooks` |

Corre como `user: 1000:1000` para que coincida con el dueño de los archivos en `AudioLibros`. Tiene el perfil `nfs` y lo arranca su propio unit, `ext-www-audiobookshelf.service`. Ver [[AudioBookShelf|AudioBookShelf]] para el detalle completo.

### Postfix — SMTP Relay

| Parámetro | Valor |
|---|---|
| Puerto | `25` |
| Relay | `smtp.gmail.com:587` |
| Redes permitidas | `172.31.0.0/24`, `10.0.0.0/24` |

### Cloudflare Tunnel

| Parámetro | Valor |
|---|---|
| Imagen | `cloudflare/cloudflared:latest` |
| IP interna | `172.31.0.12` |
| Token | `CLOUDFLARE_TUNNEL_TOKEN` en `.env` |

Expone servicios del stack hacia internet vía Cloudflare sin abrir puertos adicionales; depende de `npm`.

## Red Docker

```
172.31.0.0/24
├── 172.31.0.10  MariaDB
├── 172.31.0.11  Nginx Proxy Manager (interno)
├── 172.31.0.12  Cloudflare Tunnel
├── 172.31.0.20  Nextcloud
├── 172.31.0.21  Redis (Nextcloud)
├── 172.31.0.22  WordPress
├── 172.31.0.23  Redis (WordPress)
├── 172.31.0.24  AudioBookShelf
└── 172.31.0.254 SMTP relay
```

## Almacenamiento

```
/var/docker-data/ext-www/
├── mysql/          ← MariaDB data + backups automáticos
├── nextcloud/      ← archivos de usuario
├── wordpress/      ← archivos WordPress
└── audiobookshelf/ ← config y metadata de AudioBookShelf
```

## Timezone

`America/Argentina/Buenos_Aires`

## Systemd

Servicio: `ext-www.service`
```
Wants=network-online.target ext-www-audiobookshelf.service
After=docker.service network-online.target
StartLimitIntervalSec=0
WorkingDirectory=/opt/docker/ext-www/
ExecStart=/usr/bin/docker compose up -d
Restart=on-failure
RestartSec=30
```

Reintenta cada 30 s sin límite si falla el arranque. AudioBookShelf **no** se levanta con este `up -d`: tiene el perfil `nfs` en el compose y su propio unit, `ext-www-audiobookshelf.service`. Ver [[AudioBookShelf#Systemd|AudioBookShelf → Systemd]].

## Arranque sin NFS

Los sitios y el túnel de Cloudflare no dependen del NFS: si `/mnt/storage` no está disponible en el boot, solo queda pendiente AudioBookShelf.

Antes un solo `docker compose up -d` levantaba todo. El 2026-11-03, tras un corte de luz, el NFS no estaba listo: AudioBookShelf no pudo montar su librería, compose abortó, cloudflared quedó en `Created` y el sitio devolvía **Error 1033**.

Si vuelve a aparecer el 1033, revisar primero que cloudflared esté corriendo:

```bash
systemctl status ext-www ext-www-audiobookshelf
sudo docker compose -f /opt/docker/ext-www/compose.yml ps -a
```

Las piezas de red y NFS que acompañan este esquema están en [[../Infrastructure/Almacenamiento#Recuperación tras un corte de luz|Almacenamiento → Recuperación tras un corte de luz]].

`./do.sh update` hace `down` y `up -d` del stack, y al final reinicia `ext-www-audiobookshelf.service` para volver a levantar AudioBookShelf. No le hace `pull` a AudioBookShelf: su imagen se actualiza con `update-audiobookshelf.yml`.
