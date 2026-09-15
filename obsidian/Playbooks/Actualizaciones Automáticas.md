---
tags: [playbooks, actualizaciones, cron, docker]
---

# Actualizaciones Automáticas

Cada servicio con contenedores Docker tiene un playbook `update-{servicio}.yml` con rollback automático, y un `cron-update-{servicio}.yml` que instala el cron job en localhost.

`localhost` es el **nodo de control Ansible** (ver [[../Infrastructure/Hosts#Configuración Ansible|Hosts → Configuración Ansible]]): `alphaprime.sismonda.local` desde el 2026-09-15 (antes era `rbpi3-001`). Los cron jobs corren ahí, como usuario `ansible`.

## Flujo general

Ver [[../Convenciones#Playbooks de actualización|Convenciones → Playbooks de actualización]] para el detalle completo del flujo (log previo, tag rollback, pull, verificación, log posterior, rescue).

## Cron jobs configurados

| Servicio | Horario | Cron file | Log |
|---|---|---|---|
| phwrgrd | Domingos 23:00 | `/etc/cron.d/update-phwrgrd` | `/var/log/ansible-update-phwrgrd.log` |
| Immich | Domingos 23:15 | `/etc/cron.d/update-immich` | `/var/log/ansible-update-immich.log` |
| Collabora | Domingos 23:30 | `/etc/cron.d/update-collabora` | `/var/log/ansible-update-collabora.log` |
| Hermes Agent | Domingos 23:45 | `/etc/cron.d/update-hermes-agent` | `/var/log/ansible-update-hermes-agent.log` |
| Torrents | Sábados 23:00 | `/etc/cron.d/update-torrents` | `/var/log/ansible-update-torrents.log` |
| Zot | Sábados 23:30 | `/etc/cron.d/update-zot` | `/var/log/ansible-update-zot.log` |
| AudioBookShelf | Domingos 22:45 | `/etc/cron.d/update-audiobookshelf` | `/var/log/ansible-update-audiobookshelf.log` |
| n8n | Domingos 22:30 | `/etc/cron.d/update-n8n` | `/var/log/ansible-update-n8n.log` |

## Playbooks

| Servicio | Despliegue | Actualización | Cron |
|---|---|---|---|
| phwrgrd | `ubu2404/phwrgrd/` | `update-phwrgrd.yml` | `cron-update-phwrgrd.yml` |
| Immich | `ubu2404/immich/` | `update-immich.yml` | `cron-update-immich.yml` |
| Collabora | `ubu2404/collabora/` | `update-collabora.yml` | `cron-update-collabora.yml` |
| Hermes Agent | `ubu2404/hermes-agent/` | `update-hermes-agent.yml` | `cron-update-hermes-agent.yml` |
| Torrents | `ubu2404/torrents/` | `update-torrents.yml` | `cron-update-torrents.yml` |
| Zot | `ubu2404/zot/` | `update-zot.yml` | `cron-update-zot.yml` |
| AudioBookShelf | `ubu2404/ext-www/` | `update-audiobookshelf.yml` | `cron-update-audiobookshelf.yml` |
| n8n | `ubu2404/n8n/` | `update-n8n.yml` | `cron-update-n8n.yml` |

## Aplicar un cron job

```bash
ansible-playbook -i hosts ubu2404/{servicio}/cron-update-{servicio}.yml
```

Esto crea `/etc/cron.d/update-{servicio}` en localhost y el archivo de log con los permisos correctos.

## Ejecutar una actualización manualmente

```bash
ansible-playbook -i hosts ubu2404/{servicio}/update-{servicio}.yml
```
