# Nginx Proxy Manager — Reverse Proxy with Let's Encrypt

Nginx Proxy Manager provides a web UI to manage Nginx reverse proxy hosts, SSL certificates via Let's Encrypt, stream proxying, and access control. It is the recommended way to route traffic to other services in this collection without manually editing configuration files.

## Prerequisites

- Docker and Docker Compose v2
- **Ports 80 and 443 must be free on the host** — required for HTTP/HTTPS traffic and Let's Encrypt certificate issuance
- A domain name pointing to your server's public IP (required to issue SSL certificates)
- The `proxy-net` shared network must exist (see [Shared Network Setup](#shared-network-setup))

## Ports

| Port | Purpose |
|------|---------|
| 80 | HTTP traffic (also used for Let's Encrypt HTTP-01 challenge) |
| 443 | HTTPS traffic |
| 81 | Admin web UI |

## Volumes

| Volume | Purpose |
|--------|---------|
| `npm_data` | Proxy configuration and SQLite database |
| `npm_letsencrypt` | TLS certificates |

## Shared Network Setup

Nginx Proxy Manager uses `proxy-net` to reach other containers. Create it once on your host before starting:

```bash
docker network create proxy-net
```

This command is safe to run again on an already-created network.

## Setup

```bash
cp .env.example .env
```

Default port values are ready to use. Change `NPM_HTTP_PORT` / `NPM_HTTPS_PORT` only if another service already occupies ports 80 or 443.

## Start

```bash
docker compose up -d
```

Access the admin UI at `http://localhost:81`.

**Default credentials (change immediately):**
- Email: `admin@example.com`
- Password: `changeme`

> **SECURITY:** Change the default admin credentials on first login. The admin panel must be secured or restricted to trusted networks — never leave default credentials in place.

## Adding Other Services to NPM

To reverse-proxy another service from this collection:

1. Uncomment the NPM opt-in block at the bottom of that service's `docker-compose.yml`:
   ```yaml
   networks:
     default:
     proxy-net:
       external: true
       name: proxy-net
   ```
2. Restart that service: `docker compose up -d`
3. In the NPM admin UI, go to **Proxy Hosts → Add Proxy Host**.
4. Set the **Forward Hostname** to the container name (e.g., `homarr`) and the **Forward Port** to the service's internal port (e.g., `7575`).

## Stop & Cleanup

```bash
# Stop (certificates and config preserved)
docker compose down

# Stop and remove all proxy config and certificates
docker compose down -v
```

> **WARNING:** `docker compose down -v` removes all proxy host configuration and Let's Encrypt certificates. You will need to re-issue certificates if you bring the stack back up.

## Deploy with Portainer

1. In Portainer, go to **Stacks → Add stack**.
2. Paste the compose file content.
3. Add environment variables from `.env.example` under **Environment variables**.
4. Ensure `proxy-net` is created on the host before deploying.
5. Click **Deploy the stack**.

## Docker Desktop Notes

- Ports 80 and 443 must not be used by another application (e.g., IIS on Windows or Apache on macOS).
- On Docker Desktop for Mac, you may need to allow port 80 and 443 in your firewall settings.

## References

- [Nginx Proxy Manager documentation](https://nginxproxymanager.com/guide/)
- [Nginx Proxy Manager GitHub](https://github.com/NginxProxyManager/nginx-proxy-manager)
