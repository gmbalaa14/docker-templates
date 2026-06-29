# Portainer — Docker Management UI

Portainer Community Edition is a lightweight, web-based Docker management interface. It provides a visual dashboard for managing containers, images, volumes, networks, and stacks across one or more Docker environments.

## Prerequisites

- Docker and Docker Compose v2
- Ports 9443 and 8000 free on the host (configurable via `.env`)

## Security Notes

> **SECURITY — Docker Socket:** Portainer mounts the Docker socket to manage the Docker daemon. This gives it full control over all containers on the host. Use a strong admin password and restrict network access to port 9443 if running on an internet-facing host.

## Ports

| Port | Purpose |
|------|---------|
| 9443 | HTTPS web UI |
| 8000 | Edge agent tunnel server |

## Volumes

| Volume | Purpose |
|--------|---------|
| `portainer_data` | Portainer configuration and user data |
| `/var/run/docker.sock` | Docker API (bind mount) |

## Setup

```bash
cp .env.example .env
```

Edit `.env` and set `PORTAINER_ADMIN_PASSWORD_HASH`:

```bash
# Generate a bcrypt hash of your chosen admin password:
docker run --rm httpd:2.4-alpine htpasswd -nbB admin 'your-password' | cut -d ':' -f 2
```

Paste the resulting hash (e.g., `$2y$05$...`) into `.env`:

```
PORTAINER_ADMIN_PASSWORD_HASH=$2y$05$your-hash-here
```

> If you leave `PORTAINER_ADMIN_PASSWORD_HASH` blank, Portainer will prompt you to set a password through the web UI on first access. You must do this within a few minutes of starting or the setup window will close and you will need to restart the container.

## Start

```bash
docker compose up -d
```

Access the UI at `https://localhost:9443`. Accept the self-signed certificate warning on first access.

## Stop & Cleanup

```bash
# Stop (configuration preserved)
docker compose down

# Stop and remove all Portainer data
docker compose down -v
```

> **WARNING:** `docker compose down -v` removes all Portainer stacks, users, environments, and settings.

## Deploy with Portainer

Portainer can manage itself. To deploy via an existing Portainer instance, add the compose file as a new stack and set the environment variables under **Environment variables**.

## Docker Desktop Notes

- The Docker socket at `/var/run/docker.sock` is available via Docker Desktop's compatibility layer on Mac and Windows.
- The HTTPS UI uses a self-signed certificate by default. You can configure a trusted certificate via NPM after initial setup.

## Using with Nginx Proxy Manager

1. Ensure `proxy-net` exists: `docker network create proxy-net`
2. Uncomment the NPM block at the bottom of `docker-compose.yml`.
3. Restart: `docker compose up -d`
4. In NPM, add a proxy host pointing to `portainer:9443` with **Scheme: https** and **SSL Verification disabled**.

## References

- [Portainer documentation](https://docs.portainer.io/)
- [Portainer CE GitHub](https://github.com/portainer/portainer)
