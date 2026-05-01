---
tags: [playbook, setup, docker, nfs, base]
---

# Playbooks de Setup Base

Playbooks de instalación inicial y módulos reutilizables.

## Herramientas comunes

### `ubu2404/basic/basic.yml`

Host: `alphaprime-dev`

Instala utilidades esenciales del sistema:

```
aria2, byobu, elinks, ethtool, exfat-fuse, fail2ban,
iperf3, iftop, mc, molly-guard, net-tools, rsync, vim, wget
```

También incluye el módulo `nfs.yml` para montar el storage.

### `utils/basic.yml`

Host: `all`

Mismas utilidades, aplicable a todos los hosts.

---

## Módulo: Docker

**Archivo:** `ubu2404/modules/docker.yml`

```yaml
packages:
  - docker.io
  - docker-compose-v2

service: docker (started + enabled)
```

> Instala Docker con Compose v2 (comando `docker compose`, no `docker-compose`).

---

## Módulo: NFS Client

**Archivo:** `ubu2404/modules/nfs.yml`

```yaml
packages:
  - nfs-common

mount:
  src: 10.0.0.9:/storage
  path: /mnt/storage
  opts: rw,soft,x-systemd.automount,rsize=131072,wsize=131072
```

Ver [[../Infrastructure/Almacenamiento|Almacenamiento NFS]].

---

## Módulo: Containerd / nerdctl

**Archivo:** `ubu2404/modules/nerdctl.yml`

Alternativa a Docker usando containerd como runtime:

```yaml
packages:
  - containerd

nerdctl-full: v1.7.6 (ARM64)
  url: https://github.com/containerd/nerdctl/releases/
  dest: /usr/local/

service: containerd (started + enabled)
```

Usado por: [[../Services/UniFi|UniFi Network App]]

---

## Raspberry Pi — Setup general

**Archivo:** `utils/rbpi.yml`
**Hosts:** `rbpi3`, `rbpi4`, `rbpi5`

- Instala NFS client + rsync
- Script de backup: `/opt/utils/rbpi-backup.sh`
- Script de temperatura: `/opt/utils/rbpi-temp.sh`
- Cron: `rbpi-backup-crond`

---

## Minecraft Java Server

**Archivo:** `ubu2404/minecraft-server/minecraft-java.yml`
**Host:** `alphaprime-dev`

```yaml
image: itzg/minecraft-server
port: 25565
environment:
  EULA: "TRUE"
volume: ./data
```
