---
tags: [ansible, homelab, index]
---

# Infraestructura Sismonda — Ansible

Repositorio de automatización Ansible para la red `sismonda.local` / `sismonda.com.ar`.

## Mapa del vault

### Infraestructura
- [[Infrastructure/Hosts|Hosts e Inventario]] — servidores administrados y grupos
- [[Infrastructure/Red|Arquitectura de Red]] — subredes, VPN, DNS
- [[Infrastructure/Almacenamiento|Almacenamiento NFS]] — storage compartido

### Servicios
| Servicio | Host | Función |
|---|---|---|
| [[Services/Nginx Proxy Manager\|Nginx Proxy Manager]] | rbpi5001 | Reverse proxy + SSL |
| [[Services/Pi-Hole + WireGuard\|Pi-Hole + WireGuard]] | rbpi4001/2, rbpi5001 | DNS + VPN |
| [[Services/Ollama\|Ollama]] | alphaprime | Inferencia AI/LLM |
| [[Services/Plex\|Plex Media Server]] | alphaprime | Streaming multimedia |
| [[Services/Torrents\|Torrents (Arr stack)]] | rbpi5001 | Descarga automática |
| [[Services/Nextcloud y WordPress\|Nextcloud & WordPress]] | rbpi5002 | Cloud personal + web |
| [[Services/SearXNG\|SearXNG]] | rbpi4001 | Metabuscador privado |
| [[Services/UniFi\|UniFi Network App]] | rbpi5001 | Gestión de red |
| [[Services/Syncthing\|Syncthing]] | alphaprime-dev | Sincronización archivos |

### Playbooks
- [[Playbooks/Setup Base|Setup Base]] — herramientas comunes, Docker, NFS
- [[Playbooks/NUT - UPS|NUT / UPS]] — monitoreo de UPS
- [[Playbooks/Utilidades|Utilidades]] — backup, NTP, DNS resolver

### Referencia
- [[Convenciones|Convenciones del proyecto]]

## Topología general

```
Internet
   │
   ▼
[Nginx Proxy Manager] rbpi5001:80/443
   │ SSL termination
   ├─── Nextcloud / WordPress ──► rbpi5002
   └─── Otros servicios internos
   
[Pi-Hole + WireGuard] rbpi4001/4002/5001
   ├─── DNS local sismonda.local
   └─── VPN (WireGuard) 10.13.13.0/24

[alphaprime] — servidor principal
   ├─── Ollama (AMD ROCm GPU)
   └─── Plex Media Server

[NFS Storage] 10.0.0.9:/storage
   └─── Montado en todos los hosts vía /mnt/storage
```

## Convenciones rápidas

- Compose files: `/opt/docker/{servicio}/compose.yml`
- Storage persistente: `/var/docker-data/{servicio}/`
- Script de gestión: `/opt/docker/{servicio}/do.sh`
- Servicios iniciados como **systemd units**
- Runtime: Docker Compose v2 (`docker compose`)
