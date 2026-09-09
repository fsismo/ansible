---
tags: [servicio, fotos, media, docker]
---

# Immich — Backup y gestión de fotos/videos

Servidor self-hosted de backup y organización de fotos y videos (alternativa a Google Photos).

## Datos del servicio

| Parámetro | Valor |
|---|---|
| **Host** | `alphaprime.sismonda.local` |
| **Imagen Server** | `ghcr.io/immich-app/immich-server:${IMMICH_VERSION:-release}` |
| **Imagen ML** | `ghcr.io/immich-app/immich-machine-learning:${IMMICH_VERSION:-release}` |
| **Imagen DB** | `ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0` |
| **Imagen Redis** | `docker.io/valkey/valkey:8` |
| **Playbook** | `ubu2404/immich/immich.yml` |
| **Compose** | `/opt/docker/immich/compose.yml` |

## Puertos

| Puerto | Servicio |
|---|---|
| `2283` | Immich Server (API + web) |

## Almacenamiento

```
/opt/docker/immich/
├── library/        ← fotos/videos subidos (UPLOAD_LOCATION)
├── postgres/       ← datos de la base (DB_DATA_LOCATION)
├── compose.yml
├── hwaccel.transcoding.yml
├── hwaccel.ml.yml
├── do.sh
└── .env            ← no se commitea, contiene secretos
```

> Nota: a diferencia de la convención general (`/var/docker-data/{servicio}/`), los datos quedan
> dentro de `/opt/docker/immich/` porque el servicio ya estaba desplegado manualmente así antes de
> incorporarlo a Ansible. No se migraron para evitar el riesgo de mover ~datos reales de fotos.

Además monta como solo lectura, para importar contenido existente:
- `/mnt/storage/Photos/JPG` → `/mnt/JPG`
- `/mnt/storage/Videos/MP4` → `/mnt/MP4`

## Variables de entorno requeridas

Crear `/opt/docker/immich/.env` manualmente (contiene secretos, **no se commitea**):

```
UPLOAD_LOCATION=./library
DB_DATA_LOCATION=./postgres
TZ=America/Argentina/Buenos_Aires
IMMICH_VERSION=release
DB_PASSWORD=<password-aleatorio>
DB_USERNAME=postgres
DB_DATABASE_NAME=immich
HSA_OVERRIDE_GFX_VERSION=<solo si se habilita aceleración ROCm>
```

El playbook `immich.yml` **aborta si `.env` no existe** — no lo genera automáticamente porque
contiene la contraseña de la base de datos.

## Aceleración por hardware

`hwaccel.transcoding.yml` y `hwaccel.ml.yml` están presentes pero **sin activar** (el servicio usa
el backend `cpu` en ambos casos). Para habilitar transcodificación o inferencia acelerada, editar
`compose.yml` y descomentar la sección `extends` correspondiente con el backend adecuado
(`vaapi`, `rocm`, etc. — ver comentarios en cada archivo).

## Gestión con `do.sh`

```bash
./do.sh start      # inicia los contenedores
./do.sh stop        # detiene los contenedores
./do.sh upgrade      # pull de imágenes + recrear contenedores
```

## Systemd

Servicio: `immich.service`
```
WorkingDirectory=/opt/docker/immich/
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
```

## Actualizaciones automáticas

- Playbook: `ubu2404/immich/update-immich.yml`
- Cron: `ubu2404/immich/cron-update-immich.yml` — domingos 23:15
- Log: `/var/log/ansible-update-immich.log`

Ver [[Playbooks/Actualizaciones Automáticas]] para el flujo completo con rollback.
