---
tags: [servicio, searxng, busqueda, privacidad, docker]
---

# SearXNG — Metabuscador Privado

Motor de búsqueda que agrega resultados de múltiples fuentes sin rastreo.

## Datos del servicio

| Parámetro | Valor |
|---|---|
| **Host** | `rbpi4001.sismonda.local` |
| **Imagen** | `searxng/searxng:latest` |
| **Playbook** | `ubu2404/searxng/searxng.yml` |
| **Compose** | `/opt/docker/searxng/compose.yml` |
| **Puerto** | `8080` |

## Almacenamiento

```
/var/docker/searxng/    ← caché
```

## Gestión

Usa script `do.sh` para gestión del contenedor (start/stop/restart/logs).

## Systemd

Servicio: `searxng.service`
```
WorkingDirectory=/opt/docker/searxng/
ExecStart=/usr/bin/docker compose up -d
```
