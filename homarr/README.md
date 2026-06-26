# Homarr — Server Dashboard

Homarr is an open-source, customizable dashboard for self-hosted services. It lets you pin apps, view statuses, and integrate with Docker to automatically discover and display running containers.

## Prerequisites

- Docker and Docker Compose v2
- Port 7575 free on the host (configurable via `.env`)

## Ports

| Port | Purpose |
|------|---------|
| 7575 | Web UI |

## Volumes

| Volume | Purpose |
|--------|---------|
| `homarr_configs` | Dashboard configuration files |
| `homarr_icons` | Custom service icons |
| `homarr_data` | Application data |

## Setup

```bash
cp .env.example .env
```

No required changes — defaults are ready to use.

> **SECURITY — Docker Socket:** The Docker socket (`/var/run/docker.sock`) is mounted to enable automatic container discovery. Mounting the Docker socket gives the container root-equivalent access to the host. If you do not need Docker integration, remove the `/var/run/docker.sock` volume line from `docker-compose.yml`.

## Start

```bash
docker compose up -d
```

Access the dashboard at `http://localhost:7575`.

Authentication is managed through Homarr's own user settings in the web UI.

## Stop & Cleanup

```bash
# Stop (data preserved)
docker compose down

# Stop and remove all data including your dashboard configuration
docker compose down -v
```

> **WARNING:** `docker compose down -v` permanently deletes your dashboard layout, app pins, and icons.

## Deploy with Portainer

1. In Portainer, go to **Stacks → Add stack**.
2. Paste the compose file content or point to the repository.
3. Add `HOMARR_PORT` under **Environment variables** if you need a non-default port.
4. Click **Deploy the stack**.

## Docker Desktop Notes

Named volumes are used — no path configuration needed on any platform.

## Using with Nginx Proxy Manager

1. Ensure `proxy-net` exists: `docker network create proxy-net`
2. Uncomment the NPM block at the bottom of `docker-compose.yml`.
3. Restart: `docker compose up -d`
4. In NPM, add a proxy host pointing to `homarr:7575`.

## References

- [Homarr GitHub](https://github.com/ajnart/homarr)
