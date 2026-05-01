---
tags: [servicio, pihole, wireguard, vpn, dns, docker]
aliases: [phwrgrd]
---

# Pi-Hole + WireGuard (phwrgrd)

Stack combinado de VPN y DNS con filtrado de publicidad. El nombre del proyecto es `phwrgrd` (Pi-hole + WireGuard).

## Datos del servicio

| Parámetro | Valor |
|---|---|
| **Hosts** | `rbpi4001`, `rbpi4002`, `rbpi5001` |
| **Playbook principal** | `ubu2404/phwrgrd/phwrgrd.yml` |
| **Playbook update** | `ubu2404/phwrgrd/update-phwrgrd.yml` |
| **Playbook cron** | `ubu2404/phwrgrd/cron-update-phwrgrd.yml` |
| **Compose** | `/opt/docker/phwrgrd/compose.yml` |

## Contenedores

### WireGuard

| Parámetro | Valor |
|---|---|
| Imagen | `lscr.io/linuxserver/wireguard` |
| Puerto | `51820/udp` |
| Subnet clientes | `10.13.13.0/24` |
| Red interna Docker | `172.20.0.0/24` |

### Pi-Hole

| Parámetro | Valor |
|---|---|
| Imagen | `pihole/pihole` |
| Puerto HTTP | `9080` |
| Puerto HTTPS | `9443` |
| Puerto DNS | `53/tcp+udp` |

## Almacenamiento

```
/opt/docker/phwrgrd/
├── compose.yml
├── pihole/
│   ├── etc-pihole/        ← config Pi-Hole
│   └── etc-dnsmasq.d/     ← configuración DNS adicional
└── wireguard/
    └── config/            ← configuración WireGuard (clientes)
```

## Sincronización de DNS

Las definiciones de LAN se sincronizan desde NFS para resolución interna:
```
/mnt/storage/pihole/ → /opt/docker/phwrgrd/pihole/
```

Servicio systemd: `phwrgrd-sync.service` + `phwrgrd-sync.timer`

## Systemd services

| Servicio | Función |
|---|---|
| `phwrgrd.service` | Stack Docker Compose |
| `phwrgrd-sync.service` | Sincronización config Pi-Hole |
| `phwrgrd-sync.timer` | Timer para sync periódico |

## DNS local

- `systemd-resolved` **deshabilitado** en estos hosts
- DNS resuelve via `127.0.0.1` (Pi-Hole local)
- Zona interna: `sismonda.local`

Ver [[../Infrastructure/Red|Arquitectura de Red]] para detalles de DNS.

## Actualización automática

### Playbook de update (`update-phwrgrd.yml`)

1. Pull de imágenes nuevas
2. Recrear contenedores
3. **Validar DNS**:
   - `printer.sismonda.local` → `10.0.0.80`
   - `www.sismonda.com.ar` → `10.0.0.52`
4. Si falla la validación → **rollback automático** con restore de backup

### Cron semanal

```
# Todos los domingos a las 23:00
0 23 * * 0 ansible-playbook update-phwrgrd.yml >> /var/log/ansible-update-phwrgrd.log
```

Playbook: `ubu2404/phwrgrd/cron-update-phwrgrd.yml`

## Versión legacy

`docker/pi-hole-wireguard/` — versión anterior usando `docker` directo (sin compose v2).
`docker/pi-hole/pi-hole.yml` — Pi-Hole standalone en `rbpi3-004` (v5.7, sin WireGuard).
