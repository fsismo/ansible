# Ansible — Infraestructura Sismonda

## Documentación

Este proyecto tiene documentación completa en `obsidian/`. **Antes de responder cualquier pregunta sobre la infraestructura, leer primero:**

1. `obsidian/Home.md` — índice general, topología y tabla de servicios
2. El archivo específico del servicio o área consultada (ver tabla en Home.md)

Esto evita explorar el repositorio desde cero en cada conversación.

## Estructura del proyecto

- `ubu2404/` — playbooks principales (Ubuntu 24.04)
- `docker/` — playbooks legacy con Docker directo
- `containerd/` — playbooks con runtime containerd/nerdctl
- `utils/` — playbooks utilitarios reutilizables
- `hosts` — inventario de hosts administrados
- `obsidian/` — documentación completa del proyecto

## Documentación de servicios nuevos

Al crear o modificar un servicio, **siempre actualizar la documentación** como parte del mismo trabajo:

1. Crear `obsidian/Services/{NombreServicio}.md` con esta estructura:
   - Datos del servicio (host, imagen, playbook, compose path)
   - Puertos expuestos
   - Volúmenes y almacenamiento
   - Dependencias con otros servicios
   - Configuración de systemd
   - Notas relevantes

2. Agregar el servicio en la tabla de `obsidian/Home.md` (columnas: Servicio, Host, Función)

3. Si el servicio usa un host nuevo, actualizar `obsidian/Infrastructure/Hosts.md`

4. Si introduce una subred, IP fija o cambio de DNS, actualizar `obsidian/Infrastructure/Red.md`

5. Si agrega un volumen NFS o directorio de storage nuevo, actualizar `obsidian/Infrastructure/Almacenamiento.md`

6. Crear `ubu2404/{servicio}/cron-update-{servicio}.yml` que instale el cron job en localhost (ver `ubu2404/collabora/cron-update-collabora.yml` como referencia). Agregar una fila en `obsidian/Playbooks/Actualizaciones Automáticas.md` con el horario, el cron file y el log. Escalonar el horario para que no coincida con otros servicios.

La documentación se actualiza en la misma sesión que el playbook, no después.

## Convenciones

Ver `obsidian/Convenciones.md` para las reglas completas. Resumen:

- Docker siempre via Compose v2: `docker compose` (no `docker-compose`)
- Compose files: `/opt/docker/{servicio}/compose.yml`
- Storage persistente: `/var/docker-data/{servicio}/`
- Script de gestión: `/opt/docker/{servicio}/do.sh`
- Todos los servicios se inician como **systemd units**
- Timezone: `America/Argentina/Buenos_Aires`
