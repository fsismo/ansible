---
tags: [servicio, nginx, proxy, ssl, docker]
---

# Nginx Proxy Manager

Reverse proxy con gestión de certificados SSL (Let's Encrypt) via interfaz web.

## Datos del servicio

| Parámetro | Valor |
|---|---|
| **Host** | `rbpi5001.sismonda.local` |
| **Imagen** | `jc21/nginx-proxy-manager` |
| **Playbook** | `ubu2404/npm/npm.yml` |
| **Compose** | `/opt/docker/npm/compose.yml` |

## Puertos

| Puerto | Función |
|---|---|
| `80` | HTTP |
| `81` | Admin WebUI |
| `443` | HTTPS |

## Almacenamiento

```
/var/docker-data/npm/
├── data/          ← configuración, hosts proxy, certificados
└── letsencrypt/   ← certificados Let's Encrypt
```

## Credenciales iniciales

```
Email:    admin@example.com
Password: changeme
```

> ⚠️ Cambiar inmediatamente al primer login.

## Systemd

```ini
[Service]
WorkingDirectory=/opt/docker/npm/
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
```

## Uso

NPM actúa como punto de entrada externo para todos los servicios web:
- `sismonda.com.ar` → WordPress (rbpi5002)
- `cloud.*` → Nextcloud (rbpi5002)
- Gestiona certificados SSL automáticamente via Let's Encrypt

Ver también: [[Nextcloud y WordPress|Nextcloud & WordPress]] (rbpi5002 tiene su propia instancia NPM interna)
