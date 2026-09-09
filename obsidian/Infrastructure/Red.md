---
tags: [infraestructura, red, networking, vpn, dns]
---

# Arquitectura de Red

## Subredes

| Red | Uso |
|---|---|
| `10.0.0.0/24` | LAN principal (`sismonda.local`) |
| `10.13.13.0/24` | VPN WireGuard (clientes) |
| `172.20.0.0/24` | Red interna Docker phwrgrd |
| `172.31.0.0/24` | Red interna Docker ext-www (rbpi5002) |

## Hosts con IPs conocidas

| Host | IP |
|---|---|
| `alphaprime` | `10.0.0.11` |
| `printer` (impresora) | `10.0.0.80` |
| `www.sismonda.com.ar` | `10.0.0.52` |
| NFS server | `10.0.0.9` |

## DNS

### Resolución interna

- **Servidor DNS**: [[../Services/Pi-Hole + WireGuard|Pi-Hole]] en `rbpi4001/4002/5001`
- Los hosts usan `127.0.0.1` como DNS (systemd-resolved deshabilitado)
- Definiciones LAN sincronizadas desde NFS: `/mnt/storage/pihole/`
- Zona: `sismonda.local`
- Registro OCI privado: **[[../Services/Zot|Zot]]** en `rbpi4002.sismonda.local:5000` (HTTP plano, sólo LAN; opcionalmente alias `registry.sismonda.local`)

### Validación de DNS (en playbook de update)

```yaml
- printer.sismonda.local → 10.0.0.80
- www.sismonda.com.ar    → 10.0.0.52
```

### rbpi3-001 (DNS standalone)

- Pi-Hole v5.7 sin WireGuard
- Puertos: 53 (DNS), 80, 443, 67/udp (DHCP)
- Playbook: `docker/pi-hole/pi-hole.yml`

## VPN — WireGuard

- **Servidor**: `rbpi4001`, `rbpi4002`, `rbpi5001`
- **Puerto**: `51820/udp`
- **Subnet clientes**: `10.13.13.0/24`
- Integrado con Pi-Hole para DNS filtrado dentro de la VPN
- Playbook: [[../Services/Pi-Hole + WireGuard|Pi-Hole + WireGuard]]

## Flujo de tráfico externo

```
Cliente externo
     │
     ▼ HTTPS 443
[Nginx Proxy Manager] rbpi5001
     │
     ├── sismonda.com.ar  ──► [WordPress]       rbpi5002:172.31.0.22
     ├── cloud.sismonda.* ──► [Nextcloud]       rbpi5002:172.31.0.20
     ├── audiobooks.*     ──► [AudioBookShelf]  rbpi5002:172.31.0.24
     └── otros subdominios
     
Cliente VPN
     │
     ▼ WireGuard :51820/udp
[Pi-Hole + WireGuard] rbpi4001/4002/5001
     │
     └── Acceso completo a red local 10.0.0.0/24
```

## Sincronización de tiempo

- Servicio: **Chrony** (NTP)
- Hosts: todos excepto `rbpi3-001` (DNS)
- Template: `utils/chrony/chrony.conf`
- Playbook: [[../Playbooks/Utilidades|Utilidades]]
