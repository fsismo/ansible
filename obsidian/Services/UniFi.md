---
tags: [servicio, unifi, red, networking, docker]
---

# UniFi Network Application

Controlador para dispositivos de red Ubiquiti (access points, switches).

## Datos del servicio

| Parámetro | Valor |
|---|---|
| **Host** | `rbpi4001.sismonda.local` |
| **Imagen** | `lscr.io/linuxserver/unifi-network-application:latest` |
| **Compose** | `/opt/containerd/una/compose.yml` |
| **Runtime** | Containerd (nerdctl) |

## Puertos

| Puerto | Función |
|---|---|
| `8443` | WebUI HTTPS |
| `3478/udp` | STUN (para adopción de dispositivos) |
| `10001/udp` | Device discovery |

## Backend — MongoDB

```yaml
environment:
  MONGO_USER: unifi
  MONGO_DBNAME: unifi
```

## Recursos

```yaml
deploy:
  resources:
    limits:
      memory: 1024M
```

Límite de 1 GB de RAM (importante para RPi 4 con memoria limitada).

## Notas

- Desplegado con **containerd/nerdctl** en lugar de Docker
- Archivo compose en: `containerd/una/opt/containerd/una/compose.yml`
