---
tags: [infraestructura, inventario, hosts]
---

# Hosts e Inventario

Archivo de inventario: `hosts`

## Grupos

### `[servidores]` — Servidores principales

| Host | Estado | Notas |
|---|---|---|
| `alphaprime.sismonda.local` | ✅ Activo | Servidor principal (GPU AMD). **Nodo de control Ansible** (`ansible_connection=local`) |
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
| `rbpi3-001.sismonda.local` | SSH normal (host gestionado, ya no es el nodo de control) |

### `[rbpi4]` — Raspberry Pi 4

- `rbpi4001.sismonda.local`
- `rbpi4002.sismonda.local`
- `rbpi4003.sismonda.local` — incorporado 2026-09-15, Ubuntu 26.04, sin servicio asignado todavía
- `rbpi4004.sismonda.local` — incorporado 2026-09-15, Ubuntu 26.04. Corre [[../Services/Ianews|Ianews (scraper + processor)]]

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
alphaprime        → Ollama (AI), Plex, Collabora Online
rbpi4001          → Pi-Hole+WireGuard (master), SearXNG, NUT server, UniFi
rbpi4002          → Pi-Hole+WireGuard (replica), Zot Registry (OCI)
rbpi5001          → Nginx Proxy Manager, Pi-Hole+WireGuard, Torrents (Arr)
rbpi5002          → Nextcloud, WordPress, MariaDB, NPM, AudioBookShelf
rbpi3-001         → DNS (Pi-Hole standalone)
rbpi4004          → Ianews (Scraper + Processor)
alphaprime-dev    → Syncthing, Minecraft
```

## Configuración Ansible

**Nodo de control:** `alphaprime.sismonda.local` (migrado desde `rbpi3-001` el 2026-09-15).
El repo vive en `/mnt/storage/ansible`, montado por NFS y visible igual en todos los hosts,
así que no hace falta clonar nada al migrar el control node — solo mover credenciales y cron jobs.

**Usuario:** todos los playbooks se ejecutan como el usuario de sistema `ansible`
(uid propio, `sudo NOPASSWD: ALL` vía `/etc/sudoers.d/ansible`) en cada host, incluido el
nodo de control. `ansible@alphaprime` tiene un par de claves SSH propio (`~ansible/.ssh/id_ed25519`)
autorizado en el `authorized_keys` de `ansible` en el resto de los hosts.

```bash
sudo -u ansible ansible-playbook -i hosts <playbook>
```

`ansible.cfg` está deshabilitado (es el ejemplo comentado que genera `ansible-config init --disabled`),
por lo que no hay `remote_user` configurado: Ansible se conecta con el mismo usuario que ejecuta el
comando, de ahí que todo corra como `ansible`.

> Nota: en esta shell puede aparecer `ERROR: Ansible requires blocking IO...` — ver
> [[../Convenciones#Ansible — blocking IO|Convenciones]] para el workaround (`os.set_blocking`).
