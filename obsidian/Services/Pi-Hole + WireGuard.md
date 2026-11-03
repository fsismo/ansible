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

Servicio systemd: `phwrgrd-sync.service` + `phwrgrd-sync.timer` (cada 5 minutos)

El sync accede al NFS por el automount y no monta a mano: un `mount` manual puede trabarse minutos y deja `mnt-storage.automount` en `failed` hasta el próximo reinicio.

## Systemd services

| Servicio | Función |
|---|---|
| `phwrgrd.service` | Stack Docker Compose |
| `phwrgrd-sync.service` | Sincronización config Pi-Hole |
| `phwrgrd-sync.timer` | Timer para sync periódico |

`phwrgrd.service`:
```
Wants=network-online.target
After=docker.service network-online.target
StartLimitIntervalSec=0
ExecStartPre=-/usr/bin/timeout 60 /opt/utils/pihole-sync-slave.sh
Restart=on-failure
RestartSec=30
```

## Arranque sin NFS

El NAS tarda más que las Raspberry en levantar. En ese intervalo responde `access denied by server`, porque todavía no tiene los exports listos. El DNS no puede esperarlo, así que el sync al arrancar es opcional (prefijo `-` en `ExecStartPre`): Pi-hole levanta con la config local y `phwrgrd-sync.timer` sincroniza cuando el NFS vuelve.

Mientras el NAS no esté, `phwrgrd-sync.service` figura en `failed` y el host como `degraded`. Es esperable y se corrige solo en la siguiente corrida exitosa.

Antes el sync era obligatorio: tras un apagado limpio, el DNS no levantaba hasta que apareciera el NAS.

**Dónde está aplicado:** rbpi5001, rbpi4001 y rbpi4002 (2026-11-03). Solo se probó con reinicio en rbpi5001.

Ver [[../Infrastructure/Almacenamiento#Recuperación tras un corte de luz|Almacenamiento → Recuperación tras un corte de luz]].

## Endpoint de WireGuard por host

`SERVERURL` se define por host con la variable `wireguard_serverurl`, en el grupo `[phwrgrd]` del inventario (`hosts`):

| Host | `wireguard_serverurl` |
|---|---|
| rbpi4001, rbpi5001 | `rbpi002.freedynamicdns.org` |
| rbpi4002 | `alphaprime.freedynamicdns.org` |

No usar `www.sismonda.com.ar`: pasa por el proxy de Cloudflare, que no deja pasar el UDP de WireGuard.

Al cambiar `SERVERURL` y recrear el contenedor, la imagen regenera los `peer*.conf` del servidor con el endpoint nuevo y conserva las claves. Los clientes ya configurados guardan el endpoint viejo: hay que reimportarles el `peer*.conf` o cambiarles la línea `Endpoint`.

## DNS local

- `systemd-resolved` **deshabilitado** en estos hosts
- DNS resuelve via `127.0.0.1` (Pi-Hole local)
- Zona interna: `sismonda.local`

Ver [[../Infrastructure/Red|Arquitectura de Red]] para detalles de DNS.

## Actualización automática

### Playbook de update (`update-phwrgrd.yml`)

1. Pull de imágenes nuevas, con hasta 5 reintentos cada 5 minutos
2. Recrear contenedores, solo si cambió el compose o alguna imagen
3. **Validar DNS**: `printer.sismonda.local` → `10.0.0.80`
4. Si falla algo → **rollback automático** con restore de backup

Los hosts se actualizan de a uno. Qué pasa si falla algo:

| Falla | Qué hace |
|---|---|
| Host sin conexión | Sigue con los demás; el playbook termina con error |
| Pull | Revierte ese host, sigue con los demás; el playbook termina con error |
| Cualquier otra, después de tocar el servicio | Revierte ese host y **corta**: una imagen mala podría tirar el DNS de todos |

`serial: 1` no alcanza para seguir después de una falla: Ansible corta el play cuando falla un lote entero, y acá cada host es un lote. Por eso el `rescue` no vuelve a fallar cuando el problema fue el pull.

El pull falla con `toomanyrequests: retry-after: ...µs, allowed: 44000/minute`. Se vio en `lscr.io/linuxserver/wireguard` y no parece el límite de Docker Hub por IP; con esperas de 10 segundos seguía fallando.

### Cron semanal

```
# Todos los domingos a las 23:00
0 23 * * 0 ansible-playbook update-phwrgrd.yml >> /var/log/ansible-update-phwrgrd.log
```

Playbook: `ubu2404/phwrgrd/cron-update-phwrgrd.yml`

## Versión legacy

`docker/pi-hole-wireguard/` — versión anterior usando `docker` directo (sin compose v2).
`docker/pi-hole/pi-hole.yml` — Pi-Hole standalone en `rbpi3-004` (v5.7, sin WireGuard).
