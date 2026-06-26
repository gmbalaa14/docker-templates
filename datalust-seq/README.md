# Seq — Structured Log Server

Seq is a self-hosted log aggregation and search platform built by Datalust. It ingests structured (JSON) events over HTTP and exposes a web UI for real-time querying, alerting, and dashboards. Free for single-user use.

## Prerequisites

- Docker and Docker Compose v2
- Ports 5341 and 8090 free on the host (configurable via `.env`)

## Ports

| Port | Purpose |
|------|---------|
| 5341 | Ingestion endpoint (Serilog, NLog, etc.) |
| 8090 | Web UI |

## Volumes

| Volume | Purpose |
|--------|---------|
| `seq_data` | All Seq data including logs and configuration |

## Setup

```bash
cp .env.example .env
```

Edit `.env` and set:

- **`SEQ_ADMIN_PASSWORD_HASH`** — bcrypt hash of the initial admin password. Generate with:
  ```bash
  echo 'your-password' | docker run --rm -i datalust/seq config hash
  ```
  Leave blank to set a password interactively on first login via the UI.

## Start

```bash
docker compose up -d
```

Access the web UI at `http://localhost:8090`.

## Stop & Cleanup

```bash
# Stop (data preserved)
docker compose down

# Stop and remove all data
docker compose down -v
```

> **WARNING:** `docker compose down -v` permanently deletes all ingested logs and configuration.

## Deploy with Portainer

1. In Portainer, go to **Stacks → Add stack**.
2. Choose **Repository** or paste the compose file content.
3. Add environment variables from `.env.example` under the **Environment variables** section.
4. Click **Deploy the stack**.

## Docker Desktop Notes

No special configuration required. The named volume `seq_data` is managed by Docker and works on all platforms.

## Using with Nginx Proxy Manager

1. Ensure `proxy-net` exists: `docker network create proxy-net`
2. Uncomment the NPM block at the bottom of `docker-compose.yml`.
3. Restart: `docker compose up -d`
4. In NPM, add a proxy host pointing to `seq:80`.

## References

- [Seq documentation](https://docs.datalust.co/docs)
- [Seq Docker Hub](https://hub.docker.com/r/datalust/seq)
