---
tags: [servicio, zot, registry, oci, docker, tls]
---

# Zot — Registro OCI privado

Registro de contenedores OCI ([zot](https://zotregistry.dev)) para alojar imágenes propias
en la LAN sin depender de Docker Hub / GHCR. Ligero, sin base de datos, pensado para correr
en una Raspberry Pi. Sirve por **HTTPS** con certificado de la CA local.

## Datos del servicio

| Parámetro | Valor |
|---|---|
| **Host** | `rbpi4002.sismonda.local` (`10.0.0.42`) |
| **URL** | `https://registry.sismonda.local:5000` |
| **Imagen** | `ghcr.io/project-zot/zot:v2.1.21` (manifest multi-arch, usa `linux/arm64`) |
| **Playbook** | `ubu2404/zot/zot.yml` |
| **Update** | `ubu2404/zot/update-zot.yml` |
| **Compose** | `/opt/docker/zot/compose.yml` |
| **Config** | `/opt/docker/zot/config.json` |

`registry.sismonda.local` es alias de `rbpi4002` en `/mnt/storage/pihole/lan.list`
(ver [[../Infrastructure/Red|Red]]).

## Puertos expuestos

| Puerto | Función |
|---|---|
| `5000` | API OCI / Docker Registry v2 **y** web UI — **HTTPS** (TLS con cert de la CA local) |

## Web UI

zot sirve su UI web (zui) en la raíz: `https://registry.sismonda.local:5000/`. Es de **solo
lectura**: navegar repos, tags, tamaño, capas, historial. No hay gestión de usuarios ni
configuración por UI (eso sigue en `htpasswd` + `config.json`).

Habilitada vía `config.json`:

```json
"extensions": {
  "search": { "enable": true },
  "ui":     { "enable": true }
}
```

`search` es requisito de `ui` (la UI consulta por GraphQL en `/v2/_zot/ext/search`).
**Sin CVE scanning**: no se define `search.cve`, así que no descarga la base de Trivy
(pesada para la RPi4). El acceso a la UI respeta el mismo `accessControl` que la API.

## Volúmenes y almacenamiento

| Ruta host | Ruta contenedor | Contenido |
|---|---|---|
| `/var/docker-data/zot/` | `/var/lib/registry` | blobs y manifests del registro |
| `/opt/docker/zot/config.json` | `/etc/zot/config.json` (ro) | configuración |
| `/opt/docker/zot/htpasswd` | `/etc/zot/htpasswd` (ro) | credenciales de push (bcrypt) |
| `/opt/docker/zot/certs/` | `/etc/zot/certs/` (ro) | cert + key TLS de `registry.sismonda.local` |

El contenedor corre como `user: 1000:1000`; `/var/docker-data/zot/` y `/opt/docker/zot/certs/`
deben pertenecer a ese uid/gid (el playbook lo normaliza).

El GC está activo (`gc: true`, `gcInterval: 24h`) para reclamar espacio de blobs sin referencias.

## TLS

zot termina TLS directamente (`http.tls` en `config.json`), no hay proxy delante.

| Archivo | Origen |
|---|---|
| `certs/registry.sismonda.local.crt` | `/mnt/storage/ca/certs/registry.sismonda.local.crt` |
| `certs/registry.sismonda.local.key` | `/mnt/storage/ca/private/registry.sismonda.local.www.pem` (key **sin passphrase**) |

El playbook **aborta** si falta cualquiera de los dos. No se commitean (`ubu2404/zot/opt/docker/zot/certs/`
está en `.gitignore`).

### Generar / renovar el certificado

Con el script de la CA (interactivo, pide la contraseña de la CA):

```bash
/mnt/storage/ca/crt-new-srv-v2.sh
#   nombre del servidor : registry
#   IP                  : 10.0.0.42
#   SANs adicionales     : rbpi4002.sismonda.local
```

Produce `certs/registry.sismonda.local.crt` y `private/registry.sismonda.local.www.pem`
en `/mnt/storage/ca/`. Copiarlos a `rbpi4002:/opt/docker/zot/certs/` como
`registry.sismonda.local.crt` / `registry.sismonda.local.key` y `systemctl restart zot`.

### Confianza en la CA

Para que Docker (y el resto de los hosts) confíen en el registro, instalar la CA local con
[[../Playbooks/Utilidades#CA local — trust store|`utils/local-ca/local-ca.yml`]]. Ese playbook
deja el cert en el trust store del OS y en
`/etc/docker/certs.d/registry.sismonda.local:5000/ca.crt`. Sin eso, `docker` falla con
`x509: certificate signed by unknown authority`.

## Autenticación

- **Pull anónimo**: permitido a nivel política (`anonymousPolicy: ["read"]`) — funciona con
  clientes OCI (`skopeo`, `crane`, `containerd`, `podman`, `curl`). **El CLI de Docker NO** puede
  pullear anónimo: zot devuelve `401` en `/v2/` a cualquier cliente cuyo `User-Agent` contenga
  `docker`, así que los hosts con Docker deben hacer `docker login` una vez (ver más abajo).
- **Push / update**: requiere usuario autenticado vía htpasswd (`defaultPolicy: ["read", "create", "update"]`).
- **Delete**: sólo el usuario `admin` (`adminPolicy`).

> `compat: ["docker2s2"]` en `config.json` — sin esto zot rechaza (`manifest invalid`) los
> manifests Docker V2 Schema 2 que produce `docker push` de imágenes de Docker Hub.

### `htpasswd` — alta y baja de usuarios

El archivo `/opt/docker/zot/htpasswd` vive **en rbpi4002** y no se commitea (`.gitignore`).
El playbook `zot.yml` **aborta** si no existe. zot lo **recarga en caliente** (fsnotify),
no hace falta reiniciar.

Gestión con `do.sh` (correr como root en `/opt/docker/zot`):

```bash
./do.sh adduser <nombre> [password]   # alta o cambio de contraseña (pide el password si se omite)
./do.sh rmuser  <nombre>              # baja (sin argumento lista los usuarios)
```

`adduser` usa bcrypt (`htpasswd -B`) vía un contenedor `httpd:2.4-alpine` efímero.
`rmuser` se niega a borrar el último usuario. Para el bootstrap del primer `admin` antes
de tener `do.sh` desplegado:

```bash
docker run --rm httpd:2.4-alpine htpasswd -Bbn admin 'MI_PASSWORD' | sudo tee /opt/docker/zot/htpasswd
```

Todos los usuarios del htpasswd obtienen `defaultPolicy` (`read`+`create`+`update` en `**`);
para roles acotados hay que editar `accessControl` en `config.json`.

## Uso

```bash
# login — necesario para push Y para pull con el CLI de Docker (una vez por host)
docker login registry.sismonda.local:5000 -u admin

# push
docker tag miapp:latest registry.sismonda.local:5000/miapp:latest
docker push registry.sismonda.local:5000/miapp:latest

# pull
docker pull registry.sismonda.local:5000/miapp:latest
```

Pull anónimo con clientes OCI (sin `docker login`):

```bash
skopeo copy docker://registry.sismonda.local:5000/miapp:latest oci:/tmp/miapp
curl https://registry.sismonda.local:5000/v2/_catalog        # requiere auth
curl https://registry.sismonda.local:5000/v2/miapp/tags/list  # anónimo OK
```

Requiere haber corrido `utils/local-ca/local-ca.yml` en el host (confianza en la CA). Con TLS
válido **no** hace falta `insecure-registries`.

## Dependencias

- **CA local** (`ca.sismonda.local`) — el cert TLS lo firma esa CA; los clientes necesitan
  la CA en su trust store (`utils/local-ca/local-ca.yml`).
- **DNS** — `registry.sismonda.local` resuelve vía Pi-Hole (`lan.list`).
- Comparte host con **[[Pi-Hole + WireGuard|Pi-Hole + WireGuard]]** (réplica) en `rbpi4002`;
  el puerto `5000` no colisiona con Pi-Hole/WireGuard.
- No usa MariaDB, Redis ni NFS para su operación.

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
`systemctl start`, y verifica que el contenedor esté `running` y que `GET https://…/v2/` devuelva
`200` o `401`. Si algo falla, restaura ambos archivos y la imagen previa.

Cron: **sábados 23:30** (`ubu2404/zot/cron-update-zot.yml` → `/etc/cron.d/update-zot`,
log en `/var/log/ansible-update-zot.log`).

## Notas

- La imagen `ghcr.io/project-zot/zot` es un manifest multi-arch; Docker en la RPi4 (arm64)
  baja la variante correcta automáticamente. No usar los tags `-linux-amd64`.
- El cert de la CA vence en **2030-04-20**; el cert del servidor lo emite el script a 10 años.
- Requisitos previos del primer `zot.yml`: `htpasswd` + `certs/registry.sismonda.local.{crt,key}`.
  El resto de la config no tiene secretos.
- Si en el futuro se mueve a `:443`, ajustar `registry_ref` en `utils/local-ca/local-ca.yml`
  (queda `registry.sismonda.local`, sin puerto) y el `ports:` del compose.
