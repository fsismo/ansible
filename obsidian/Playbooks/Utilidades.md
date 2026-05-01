---
tags: [playbook, utilidades, ntp, dns, chrony]
---

# Playbooks de Utilidades

Playbooks de soporte y mantenimiento del sistema.

---

## Chrony — Sincronización NTP

**Archivo:** `utils/chrony.yml`
**Hosts:** todos excepto `rbpi3-001` (DNS server)

```yaml
packages: [chrony]
template: utils/chrony/chrony.conf → /etc/chrony/chrony.conf
service: chrony (started + enabled)
```

Asegura que todos los hosts tengan el tiempo sincronizado correctamente.

---

## systemd-resolved — DNS Resolver

**Archivo:** `utils/systemd-resolved.yml`
**Hosts:** todos excepto hosts DNS (`rbpi3-001`)

```yaml
template: utils/systemd/resolved.conf → /etc/systemd/resolved.conf
service: systemd-resolved (restarted)
```

> En hosts con [[../Services/Pi-Hole + WireGuard|Pi-Hole]], systemd-resolved está **deshabilitado** y reemplazado por Pi-Hole en 127.0.0.1.

---

## Backup de Raspberry Pi

**Archivo:** `utils/rbpi.yml`
**Hosts:** `rbpi3`, `rbpi4`, `rbpi5`

```bash
/opt/utils/rbpi-backup.sh   # copia de configuraciones
/opt/utils/rbpi-temp.sh     # monitoreo de temperatura CPU
```

Cron: `rbpi-backup-crond` — backup periódico automático.

---

## Resumen de playbooks disponibles

| Playbook | Hosts | Función |
|---|---|---|
| `utils/basic.yml` | all | Herramientas básicas del sistema |
| `utils/chrony.yml` | all (excl. DNS) | Sincronización NTP |
| `utils/systemd-resolved.yml` | all (excl. DNS) | DNS resolver |
| `utils/rbpi.yml` | rbpi3/4/5 | Setup específico RPi |
| `utils/nut-client.yml` | all (excl. rbpi4003) | NUT UPS client |
