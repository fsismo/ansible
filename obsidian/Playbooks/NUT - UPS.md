---
tags: [playbook, nut, ups, monitoreo]
---

# NUT — Monitoreo de UPS

Network UPS Tools para monitorear el estado del SAI/UPS y actuar ante cortes de energía.

## Arquitectura

```
[UPS físico]
     │ USB
     ▼
[rbpi4001] ← NUT Server (upsd) — expone estado en :3493
     │
     ├── rbpi4002  ←─┐
     ├── rbpi5001  ←─┤  NUT Clients (upsmon)
     └── rbpi5002  ←─┘
```

---

## NUT Server

**Archivo:** `ubu2404/nut-server/rbpi4001.yml`
**Host:** `rbpi4001.sismonda.local`

### Configuración (templates Jinja2)

| Template | Destino | Función |
|---|---|---|
| `nut.conf.j2` | `/etc/nut/nut.conf` | Modo: `netserver` |
| `upsd.conf.j2` | `/etc/nut/upsd.conf` | Escucha en `0.0.0.0:3493` |
| `upsd.users.j2` | `/etc/nut/upsd.users` | Usuarios y permisos |
| `upsmon.conf.j2` | `/etc/nut/upsmon.conf` | Monitor local del UPS |
| `ups.conf.j2` | `/etc/nut/ups.conf` | Definición del UPS (driver, puerto) |

### Health check

- Script: `/opt/nut/check-status.sh`
- Cron: `/etc/cron.d/nut-status`

### Servicio

```bash
systemctl enable --now nut-server
```

---

## NUT Client

**Archivo:** `ubu2404/nut-client/rack10inch.yml`
**Hosts:** grupo `rack10inch` excepto `rbpi4001`

### Configuración

| Archivo | Función |
|---|---|
| `/etc/nut/nut.conf` | Modo: `netclient` |
| `/etc/nut/upsmon.conf` | Conecta a `rbpi4001:3493` |
| `/etc/nut/upssched.conf` | Acciones programadas ante eventos |

### Servicio

```bash
systemctl enable --now nut-client
```

---

## Utilidad general

**Archivo:** `utils/nut-client.yml`
**Hosts:** all excepto `rbpi4003`

Templates desde: `/etc/ansible/utils/nut/`
