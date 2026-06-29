# SonarQube Community + PostgreSQL — Code Quality Analysis

SonarQube is an open-source platform for continuous code quality and security inspection. This template runs the Community Edition alongside a dedicated PostgreSQL 12 database. It supports static analysis of 30+ languages including Java, C#, JavaScript, TypeScript, Python, and Go.

## Prerequisites

- Docker and Docker Compose v2
- At least 4 GB of RAM available for Docker
- The host kernel must have `vm.max_map_count` set to at least 524288 (required by the embedded Elasticsearch)
- Port 9000 free on the host (configurable via `.env`)

### Setting `vm.max_map_count`

**Linux:**
```bash
sudo sysctl -w vm.max_map_count=524288
# To persist across reboots:
echo "vm.max_map_count=524288" | sudo tee -a /etc/sysctl.conf
```

**Docker Desktop (Mac/Windows):**
Go to **Settings → Resources → Advanced** and set the value there, or run:
```bash
docker run --rm --privileged alpine sysctl -w vm.max_map_count=524288
```

## Ports

| Port | Purpose |
|------|---------|
| 9000 | SonarQube web UI and API |

The PostgreSQL port is not exposed to the host by default — it is only accessible within the internal Docker network.

## Volumes

| Volume | Purpose |
|--------|---------|
| `sonarqube_data` | SonarQube application data |
| `sonarqube_extensions` | Plugins and extensions |
| `sonarqube_logs` | Application logs |
| `postgresql` | PostgreSQL base directory |
| `postgresql_data` | PostgreSQL data files |

## Setup

```bash
cp .env.example .env
```

> **CRITICAL — Set `SONAR_DB_PASSWORD` before starting.** This variable has no default. SonarQube will fail to start without it. Use a strong, unique password.

```bash
# Edit .env and set:
SONAR_DB_PASSWORD=your-strong-password-here
```

> **WARNING:** Changing `SONAR_DB_PASSWORD` after the first start requires reinitialising the database (`docker compose down -v`), which permanently deletes all analysis data.

## Start

```bash
docker compose up -d
```

SonarQube takes 1–2 minutes to start. Monitor progress:

```bash
docker compose logs -f sonarqube
```

Access at `http://localhost:9000`.

**Default SonarQube credentials:**
- Username: `admin`
- Password: `admin`

> **SECURITY:** Change the default admin password immediately on first login via **Administration → Security → Users**.

## Stop & Cleanup

```bash
# Stop (all analysis data preserved)
docker compose down

# Stop and remove all data including analysis results and database
docker compose down -v
```

> **WARNING:** `docker compose down -v` permanently deletes all SonarQube projects, analysis results, quality gates, and the PostgreSQL database.

## Deploy with Portainer

1. In Portainer, go to **Stacks → Add stack**.
2. Paste the compose file content.
3. Add `SONAR_DB_PASSWORD` and `SONARQUBE_PORT` under **Environment variables**.
4. Ensure `vm.max_map_count` is configured on the host before deploying.
5. Click **Deploy the stack**.

## Docker Desktop Notes

- Set `vm.max_map_count` via Docker Desktop's **Settings → Resources → Advanced** before starting.
- Allocate at least 4 GB of memory in Docker Desktop's resource settings.

## Using with Nginx Proxy Manager

1. Ensure `proxy-net` exists: `docker network create proxy-net`
2. Uncomment the NPM block at the bottom of `docker-compose.yml`.
3. Restart: `docker compose up -d`
4. In NPM, add a proxy host pointing to `sonarqube:9000`.

## References

- [SonarQube documentation](https://docs.sonarqube.org/)
- [SonarQube Docker Hub](https://hub.docker.com/_/sonarqube)
