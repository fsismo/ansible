---
tags: [servicio, ai, agente, llm, docker]
---

# Hermes Agent

Agente de IA con API compatible con OpenAI, dashboard web y memoria persistente. Se conecta a Ollama como backend de inferencia.

## Datos del servicio

| Parámetro | Valor |
|---|---|
| **Host** | `alphaprime.sismonda.local` |
| **Imagen** | `nousresearch/hermes-agent:latest` |
| **Playbook** | `ubu2404/hermes-agent/hermes-agent.yml` |
| **Compose** | `/opt/docker/hermes-agent/compose.yml` |
| **Datos** | `/var/docker-data/hermes-agent/` |

## Puertos

| Puerto | Servicio |
|---|---|
| `8642` | Gateway API (compatible con OpenAI) |
| `9119` | Dashboard web |

## Almacenamiento

```
/opt/docker/hermes-agent/
├── compose.yml
├── .env             ← API_SERVER_KEY (no commitear)
└── do.sh

/var/docker-data/hermes-agent/
├── config.yaml      ← configuración del agente y modelo
├── .env             ← claves de proveedores externos (opcional)
├── sessions/        ← historial de conversaciones
├── memories/        ← memoria persistente del agente
├── skills/          ← plugins de skills instalados
└── logs/            ← logs del gateway
```

## Configuración del modelo

El playbook consulta la API de Ollama (`http://localhost:11434/api/tags`) y selecciona automáticamente el primer modelo `hermes3.*` disponible. Si no hay ninguno, usa `hermes3:8b` como fallback.

El archivo `/var/docker-data/hermes-agent/config.yaml` se genera/actualiza en cada ejecución del playbook:

```yaml
model:
  provider: custom
  model: "hermes3:8b"        # autodetectado desde Ollama
  base_url: http://ollama:11434/v1
  api_key: "none"
```

Para forzar un modelo específico, re-ejecutar el playbook después de hacer `ollama pull <modelo>`.

## Variables de entorno

`/opt/docker/hermes-agent/.env` (generado automáticamente por el playbook):

```
API_SERVER_KEY=<clave-aleatoria-32-bytes-hex>
```

## Variables en compose

| Variable | Valor | Descripción |
|---|---|---|
| `HERMES_DASHBOARD` | `1` | Activa el dashboard web |
| `HERMES_DASHBOARD_INSECURE` | `1` | Omite OAuth (red interna de confianza) |
| `API_SERVER_ENABLED` | `true` | Expone la API Gateway |
| `API_SERVER_HOST` | `0.0.0.0` | Escucha en todas las interfaces |
| `API_SERVER_KEY` | desde `.env` | Token de autenticación de la API |

## Red Docker

Usa la red externa `ai-stack` (definida en el compose de Ollama) para acceder al contenedor `ollama` por hostname interno.

## Systemd

Servicio: `hermes-agent.service`
```
WorkingDirectory=/opt/docker/hermes-agent/
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
```

## Gestión con `do.sh`

```bash
./do.sh start    # inicia los contenedores
./do.sh stop     # detiene los contenedores
./do.sh upgrade  # pull de imagen + recrear contenedor
./do.sh status   # estado del agente y contenedor
./do.sh logs     # logs en tiempo real
```

## Actualizaciones automáticas

Cron job: domingos 23:45 via `cron-update-hermes-agent.yml`.
Log: `/var/log/ansible-update-hermes-agent.log`

## Notas

- Primera ejecución: el playbook crea un `config.yaml` mínimo. Verificar el modelo configurado antes de iniciar.
- Para una configuración avanzada (skills, memoria, múltiples perfiles), ejecutar el wizard interactivo manualmente: `docker run -it --rm -v /var/docker-data/hermes-agent:/opt/data nousresearch/hermes-agent setup`
- La imagen usa `:latest` ya que no se publican tags de versión semántica.
