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

### Postfix — SMTP Relay

| Parámetro | Valor |
|---|---|
| Puerto | `25` |
| Relay | `smtp.gmail.com:587` |
| Redes permitidas | `172.31.0.0/24`, `10.0.0.0/24` |

## Red Docker

```
172.31.0.0/24
├── 172.31.0.10  MariaDB
├── 172.31.0.20  Nextcloud
├── 172.31.0.21  Redis (Nextcloud)
├── 172.31.0.22  WordPress
└── 172.31.0.23  Redis (WordPress)
```

## Almacenamiento

```
/var/docker-data/ext-www/
├── mysql/          ← MariaDB data + backups automáticos
├── nextcloud/      ← archivos de usuario
└── wordpress/      ← archivos WordPress
```

## Timezone

`America/Argentina/Buenos_Aires`

## Systemd

Servicio: `ext-www.service`
```
WorkingDirectory=/opt/docker/ext-www/
ExecStart=/usr/bin/docker compose up -d
```
