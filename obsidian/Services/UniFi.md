---
tags: [servicio, unifi, red, networking, docker]
---

# UniFi Network Application

Controlador para dispositivos de red Ubiquiti (access points, switches).

## Datos del servicio

| Parámetro | Valor |
|---|---|
| **Host** | `rbpi5001.sismonda.local` |
| **Imagen** | `lscr.io/linuxserver/unifi-network-application:latest` |
| **Playbook** | `ubu2404/una/una.yml` |
| **Compose** | `/opt/docker/una/compose.yml` |
| **Runtime** | Docker Compose v2 |

## Puertos

| Puerto | Función |
|---|---|
| `8443` | WebUI HTTPS |
| `8080` | Device communication |
| `3478/udp` | STUN (para adopción de dispositivos) |
| `10001/udp` | Device discovery |
| `1900/udp` | UPnP (opcional) |
| `8843` | Guest portal HTTPS (opcional) |
| `8880` | Guest portal HTTP (opcional) |
| `6789` | Mobile speed test (opcional) |
| `5514/udp` | Remote syslog (opcional) |

## Volúmenes

| Ruta en host | Uso |
|---|---|
| `/var/docker-data/una/app-data` | Configuración de la app UniFi |
| `/var/docker-data/una/mongo-db/data` | Base de datos MongoDB |
| `/var/docker-data/una/mongo-db/init-mongo.sh` | Script de inicialización de MongoDB |

## Backend — MongoDB

```yaml
image: mongo:3.6
environment:
  MONGO_USER: unifi
  MONGO_DBNAME: unifi
  MONGO_AUTHSOURCE: admin
```

## Recursos

```yaml
MEM_LIMIT: 1024
MEM_STARTUP: 1024
```

## Systemd

Servicio: `una.service` — `/etc/systemd/system/una.service`
