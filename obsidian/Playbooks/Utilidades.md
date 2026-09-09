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

## CA local — trust store

**Archivo:** `utils/local-ca/local-ca.yml`
**Hosts:** `all`

```yaml
copy: utils/local-ca/sismonda-ca.crt → /usr/local/share/ca-certificates/sismonda-ca.crt
command: update-ca-certificates            # sólo si cambió el cert
# además, donde exista /etc/docker:
copy: sismonda-ca.crt → /etc/docker/certs.d/registry.sismonda.local:5000/ca.crt
```

Instala el certificado **público** de la CA `ca.sismonda.local` (copia de `/mnt/storage/ca/cacert.pem`)
para que los hosts confíen en los certificados internos, en particular en
**[[../Services/Zot|registry.sismonda.local]]**. La entrada en `/etc/docker/certs.d/` hace que
Docker confíe en el registro sin reiniciar el daemon.

Correr en un host puntual: `ansible-playbook -i hosts utils/local-ca/local-ca.yml --limit <host>`.

---

## Resumen de playbooks disponibles

| Playbook | Hosts | Función |
|---|---|---|
| `utils/basic.yml` | all | Herramientas básicas del sistema |
| `utils/chrony.yml` | all (excl. DNS) | Sincronización NTP |
| `utils/systemd-resolved.yml` | all (excl. DNS) | DNS resolver |
| `utils/rbpi.yml` | rbpi3/4/5 | Setup específico RPi |
| `utils/nut-client.yml` | all (excl. rbpi4003) | NUT UPS client |
| `utils/local-ca/local-ca.yml` | all | Instala la CA local en el trust store (OS + Docker) |
