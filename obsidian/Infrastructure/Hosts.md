---
tags: [infraestructura, inventario, hosts]
---

# Hosts e Inventario

Archivo de inventario: `hosts`

## Grupos

### `[servidores]` — Servidores principales

| Host | Estado | Notas |
|---|---|---|
| `alphaprime.sismonda.local` | ✅ Activo | Servidor principal (GPU AMD) |
| `alphaprime-dev.sismonda.local` | 💤 Comentado | Dev / staging |
| `blackmamba.sismonda.local` | 💤 Comentado | — |
| `sandbox.sismonda.local` | 💤 Comentado | — |

### `[rack10inch]` — Rack de 10 pulgadas (Raspberry Pi)

| Host | Modelo |
|---|---|
| `rbpi4001.sismonda.local` | RPi 4 |
| `rbpi4002.sismonda.local` | RPi 4 |
| `rbpi5001.sismonda.local` | RPi 5 |
| `rbpi5002.sismonda.local` | RPi 5 |

### `[rbpi3]` — Raspberry Pi 3

| Host | Conexión |
|---|---|
| `rbpi3-001.sismonda.local` | `ansible_connection=local` |

### `[rbpi4]` — Raspberry Pi 4

- `rbpi4001.sismonda.local`
- `rbpi4002.sismonda.local`

### `[rbpi5]` — Raspberry Pi 5

- `rbpi5001.sismonda.local`
- `rbpi5002.sismonda.local`

### `[dns]`

- `rbpi3-001.sismonda.local` — servidor DNS primario

### `[phwrgrd]` — Hosts con Pi-Hole + WireGuard

- `rbpi4001`, `rbpi4002`, `rbpi5001`
- Ver [[../Services/Pi-Hole + WireGuard|Pi-Hole + WireGuard]]

---

## Diagrama de servicios por host

```
alphaprime        → Ollama (AI), Plex
rbpi4001          → Pi-Hole+WireGuard (master), SearXNG, NUT server, UniFi
rbpi4002          → Pi-Hole+WireGuard (replica)
rbpi5001          → Nginx Proxy Manager, Pi-Hole+WireGuard, Torrents (Arr)
rbpi5002          → Nextcloud, WordPress, MariaDB, NPM
rbpi3-001         → DNS (Pi-Hole standalone)
alphaprime-dev    → Syncthing, Minecraft
```

## Configuración Ansible

Archivo: `ansible.cfg`

```ini
[defaults]
inventory = hosts
remote_user = ubuntu          # usuario SSH
host_key_checking = False
roles_path = roles/
```
