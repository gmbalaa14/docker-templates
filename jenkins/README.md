# Jenkins — CI/CD Automation Server

Jenkins is a widely-used open-source automation server for building, testing, and deploying software. This template runs the LTS release with Docker-in-Docker support so Jenkins pipelines can build and push Docker images.

## Prerequisites

- Docker and Docker Compose v2
- Docker CLI installed on the host (see `DOCKER_BIN` in `.env`)
- Ports 8080 and 50000 free on the host (configurable via `.env`)

## Security Warnings

> **WARNING — Privileged Mode + Root User:** This compose file sets `privileged: true` and `user: root`. This gives the Jenkins container unrestricted access to the host kernel. Only run this in isolated, trusted environments. Never expose port 8080 directly to the internet without placing it behind a reverse proxy with authentication.

> **WARNING — Docker Socket:** The Docker socket (`/var/run/docker.sock`) is mounted so Jenkins pipelines can run Docker commands. This gives Jenkins root-equivalent access to all containers on the host.

## Ports

| Port | Purpose |
|------|---------|
| 8080 | Web UI and REST API |
| 50000 | JNLP agent connection port |

> **Port conflict:** Port 8080 is also the default for Kafka UI. Change `JENKINS_PORT` or `KAFKA_UI_PORT` in the respective `.env` if running both.

## Volumes

| Volume | Purpose |
|--------|---------|
| `jenkins_home` | Jenkins home: jobs, plugins, credentials, workspace |
| `/var/run/docker.sock` | Docker API (bind mount) |
| `${DOCKER_BIN}` | Docker CLI binary (bind mount) |

## Setup

```bash
cp .env.example .env
```

Edit `.env`:

- **`DOCKER_BIN`** — path to the Docker CLI on your host. Find it with `which docker`.
- Change `JENKINS_PORT` if port 8080 is in use.

## Start

```bash
docker compose up -d
```

On first start Jenkins generates an initial admin password. Retrieve it with:

```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

Access the setup wizard at `http://localhost:8080`.

## Stop & Cleanup

```bash
# Stop (jobs and config preserved)
docker compose down

# Stop and remove all data including jobs and plugins
docker compose down -v
```

> **WARNING:** `docker compose down -v` permanently deletes all Jenkins jobs, plugins, credentials, and build history.

## Deploy with Portainer

1. In Portainer, go to **Stacks → Add stack**.
2. Paste the compose file content.
3. Add environment variables from `.env.example` under **Environment variables**.
4. Click **Deploy the stack**.

## Docker Desktop Notes

- **Docker socket:** Docker Desktop on Mac and Windows provides `/var/run/docker.sock` via a compatibility socket — the volume mount works as-is.
- **Docker CLI path:** On Docker Desktop, `docker` is typically at `/usr/local/bin/docker`. Verify with `which docker` in your terminal.

## Using with Nginx Proxy Manager

1. Ensure `proxy-net` exists: `docker network create proxy-net`
2. Uncomment the NPM block at the bottom of `docker-compose.yml`.
3. Restart: `docker compose up -d`
4. In NPM, add a proxy host pointing to `jenkins:8080`.

## References

- [Jenkins Docker Hub](https://hub.docker.com/r/jenkins/jenkins)
- [Jenkins documentation](https://www.jenkins.io/doc/)
