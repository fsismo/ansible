---
tags: [servicio, zot, registry, oci, docker]
---

# Zot — Registro OCI privado

Registro de contenedores OCI ([zot](https://zotregistry.dev)) para alojar imágenes propias
en la LAN sin depender de Docker Hub / GHCR. Ligero, sin base de datos, pensado para correr
en una Raspberry Pi.

## Datos del servicio

| Parámetro | Valor |
|---|---|
| **Host** | `rbpi4002.sismonda.local` |
| **Imagen** | `ghcr.io/project-zot/zot:v2.1.21` (manifest multi-arch, usa `linux/arm64`) |
| **Playbook** | `ubu2404/zot/zot.yml` |
| **Update** | `ubu2404/zot/update-zot.yml` |
| **Compose** | `/opt/docker/zot/compose.yml` |
| **Config** | `/opt/docker/zot/config.json` |

## Puertos expuestos

| Puerto | Función |
|---|---|
| `5000` | API OCI / Docker Registry v2 (HTTP, sin TLS — termina en la LAN) |

## Volúmenes y almacenamiento

| Ruta host | Ruta contenedor | Contenido |
|---|---|---|
| `/var/docker-data/zot/` | `/var/lib/registry` | blobs y manifests del registro |
| `/opt/docker/zot/config.json` | `/etc/zot/config.json` (ro) | configuración |
| `/opt/docker/zot/htpasswd` | `/etc/zot/htpasswd` (ro) | credenciales de push (bcrypt) |

El contenedor corre como `user: 1000:1000`; `/var/docker-data/zot/` debe pertenecer a ese uid/gid
(el playbook lo crea con esos permisos).

El GC está activo (`gc: true`, `gcInterval: 24h`) para reclamar espacio de blobs sin referencias.

## Autenticación

- **Pull anónimo**: permitido para cualquier cliente de la LAN (`anonymousPolicy: ["read"]`).
- **Push / update**: requiere usuario autenticado vía htpasswd (`defaultPolicy: ["read", "create", "update"]`).
- **Delete**: sólo el usuario `admin` (`adminPolicy`).

### `htpasswd` requerido

El playbook **aborta** si no existe `/opt/docker/zot/htpasswd`. Crearlo manualmente en el host
(no se commitea — está en `.gitignore`). Ejemplo con un contenedor efímero:

```bash
docker run --rm httpd:2.4-alpine htpasswd -Bbn admin 'MI_PASSWORD' | sudo tee /opt/docker/zot/htpasswd
# agregar más usuarios:
docker run --rm httpd:2.4-alpine htpasswd -Bbn ci 'OTRO_PASSWORD' | sudo tee -a /opt/docker/zot/htpasswd
```

`-B` fuerza bcrypt (recomendado por zot). Tras editar el htpasswd, reiniciar: `systemctl restart zot`.

## Uso

```bash
# login (sólo necesario para push)
docker login rbpi4002.sismonda.local:5000 -u admin

# push
docker tag miapp:latest rbpi4002.sismonda.local:5000/miapp:latest
docker push rbpi4002.sismonda.local:5000/miapp:latest

# pull (anónimo)
docker pull rbpi4002.sismonda.local:5000/miapp:latest
```

Como el registro habla HTTP plano, cada host que quiera usarlo debe listarlo como
*insecure registry* en `/etc/docker/daemon.json`:

```json
{ "insecure-registries": ["rbpi4002.sismonda.local:5000"] }
```

> Opcional: dar de alta `registry.sismonda.local` como alias de `rbpi4002` en Pi-Hole
> (ver [[../Infrastructure/Red|Red]]) para no acoplar el nombre del host.

## Dependencias

- Ninguna. Servicio autónomo (no usa MariaDB, Redis ni NFS).
- Comparte host con **[[Pi-Hole + WireGuard|Pi-Hole + WireGuard]]** (réplica) en `rbpi4002`;
  el puerto `5000` no colisiona con Pi-Hole/WireGuard.

## Systemd

Servicio: `zot.service`

```
WorkingDirectory=/opt/docker/zot
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
```

## Actualización

`update-zot.yml` sigue el flujo estándar con rollback (ver [[../Playbooks/Actualizaciones Automáticas]]):
copia `config.json` + `compose.yml`, etiqueta imágenes como `:_rollback`, `systemctl stop`, pull,
`systemctl start`, y verifica que el contenedor esté `running` y que `GET /v2/` devuelva `200` o `401`.
Si algo falla, restaura ambos archivos y la imagen previa.

Cron: **sábados 23:30** (`ubu2404/zot/cron-update-zot.yml` → `/etc/cron.d/update-zot`,
log en `/var/log/ansible-update-zot.log`).

## Notas

- La imagen `ghcr.io/project-zot/zot` es un manifest multi-arch; Docker en la RPi4 (arm64)
  baja la variante correcta automáticamente. No usar los tags `-linux-amd64`.
- Sin TLS a propósito: el tráfico no sale de la LAN. Si en algún momento se expone por NPM,
  agregar un `server_name` y que NPM haga la terminación TLS.
- El primer `zot.yml` necesita que exista el `htpasswd`; el resto de la config no tiene secretos.
