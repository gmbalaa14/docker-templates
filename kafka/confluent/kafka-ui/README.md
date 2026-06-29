# Kafka UI — Multi-Cluster Web Interface

Kafka UI (by Provectus) is a free, open-source web interface for managing Apache Kafka clusters. This template runs a single Kafka UI instance that can connect to any number of Kafka clusters and supports full authentication configuration through the UI.

Cluster configuration is managed entirely through the web UI — no environment variables or container restarts are needed to add, edit, or remove clusters.

## Prerequisites

- Docker and Docker Compose v2
- The `kafka-ui-net` shared network must exist (see [Shared Network Setup](#shared-network-setup))
- Port 8080 free on the host (configurable via `.env`)

## Ports

| Port | Purpose |
|------|---------|
| 8080 | Web UI |

> **Port conflict:** Port 8080 is also the default for Jenkins. Change `KAFKA_UI_PORT` or `JENKINS_PORT` in the respective `.env` if running both.

## Volumes

| Volume | Purpose |
|--------|---------|
| `kafka_ui_config` | Persists cluster configurations added via the UI |

## Shared Network Setup

Kafka UI communicates with Kafka clusters via the `kafka-ui-net` bridge network. Create it once on your host before starting:

```bash
docker network create kafka-ui-net
```

This command is safe to run again on an already-created network.

## Setup

```bash
cp .env.example .env
```

No required changes — `KAFKA_UI_PORT=8080` is the only variable. Change it if port 8080 is in use.

## Start

```bash
docker compose up -d
```

Access at `http://localhost:8080`.

## Adding Kafka Clusters

1. Open the Kafka UI web interface.
2. Go to **Settings → Configure new cluster** (or the gear icon).
3. Fill in the cluster details:
   - **Cluster name** — a descriptive label
   - **Bootstrap servers** — use the broker's **internal** address if the cluster is on `kafka-ui-net` (e.g., `kafka1:29092,kafka2:29092,kafka3:29092`), or the **external** host IP and ports for remote clusters
4. For authenticated clusters (SASL/PLAIN), set:
   - **Security protocol:** `SASL_PLAINTEXT`
   - **SASL mechanism:** `PLAIN`
   - **SASL JAAS config:** `org.apache.kafka.common.security.plain.PlainLoginModule required username="admin" password="your-password";`
5. Click **Submit**. The configuration is saved automatically to the `kafka_ui_config` volume.

## Stop & Cleanup

```bash
# Stop (cluster configurations preserved)
docker compose down

# Stop and remove all saved cluster configurations
docker compose down -v
```

> **WARNING:** `docker compose down -v` removes all cluster configurations you have added through the UI. You will need to re-add them.

## Deploy with Portainer

1. In Portainer, go to **Stacks → Add stack**.
2. Paste the compose file content.
3. Add `KAFKA_UI_PORT` under **Environment variables** if needed.
4. Ensure `kafka-ui-net` is created on the host before deploying.
5. Click **Deploy the stack**.
6. Add clusters through the Kafka UI web interface after the stack is running.

## Docker Desktop Notes

- Named volume works on all platforms.
- When adding a cluster that uses `KAFKA_HOST_IP`, use `host.docker.internal` (Mac) or the host machine's LAN IP (Windows).

## References

- [Kafka UI GitHub](https://github.com/provectus/kafka-ui)
- [Kafka UI documentation](https://docs.kafka-ui.provectus.io/)
