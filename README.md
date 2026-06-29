# Docker Compose Templates

A curated collection of ready-to-use Docker Compose configurations for self-hosted services. Each template is self-contained, fully parameterised via `.env` files, and compatible with Docker CLI, [Portainer](https://www.portainer.io/), and Docker Desktop.

## Table of Contents

- [Templates](#templates)
- [Shared Networks Setup](#shared-networks-setup)
- [Port Reference](#port-reference)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
- [Deployment Options](#deployment-options)
- [Contributing](#contributing)
- [License](#license)

---

## Templates

| Template | Description | Default Ports | Notes |
|---|---|---|---|
| [datalust-seq](./datalust-seq/README.md) | Structured log aggregation server | 5341 (ingest), 8090 (UI) | Auth via bcrypt hash in `.env` |
| [homarr](./homarr/README.md) | Customizable server dashboard | 7575 | Optional Docker integration |
| [jenkins](./jenkins/README.md) | CI/CD automation server | 8080 (web), 50000 (agent) | Runs as root with privileged mode |
| [nginx-proxy-manager](./nginx-proxy-manager/README.md) | Reverse proxy with Let's Encrypt SSL | 80, 443, 81 (admin) | Owns `proxy-net`; change default creds on first login |
| [portainer](./portainer/README.md) | Docker management UI | 9443 (HTTPS), 8000 (tunnel) | Auth via bcrypt hash in `.env` |
| [sonarqube](./sonarqube/README.md) | Code quality and security analysis | 9000 (UI) | Requires `SONAR_DB_PASSWORD` in `.env`; needs `vm.max_map_count=524288` |
| [kafka/confluent/kafka-ui](./kafka/confluent/kafka-ui/README.md) | Multi-cluster Kafka web UI | 8080 | Add clusters via UI; requires `kafka-ui-net` |
| [kafka/confluent/3-node-cluster-with-auth](./kafka/confluent/3-node-cluster-with-auth/README.md) | 3-node KRaft cluster (SASL/PLAIN) | 9092–9097, 29092–29094 | Requires `KAFKA_HOST_IP`, `KAFKA_CLUSTER_ID`, SASL creds in `.env` |
| [kafka/confluent/3-node-cluster-without-auth](./kafka/confluent/3-node-cluster-without-auth/README.md) | 3-node KRaft cluster (no auth) | 9092–9097, 29092–29094 | Development use only — no authentication |

---

## Shared Networks Setup

Two shared bridge networks enable cross-service communication. Create them **once** on your host before starting any service that uses them:

```bash
docker network create proxy-net
docker network create kafka-ui-net
```

These commands are idempotent — safe to re-run on an already-created network.

| Network | Purpose | Owner template |
|---|---|---|
| `proxy-net` | Allows Nginx Proxy Manager to reverse-proxy any service that opts in | nginx-proxy-manager |
| `kafka-ui-net` | Allows Kafka UI to reach any Kafka cluster that joins it | kafka/confluent/kafka-ui |

Services opt in to `proxy-net` by uncommenting the block at the bottom of their `docker-compose.yml`. See the [Nginx Proxy Manager README](./nginx-proxy-manager/README.md) for the full guide.

---

## Port Reference

All ports are configurable via `.env` variables. The table below shows defaults.

| Service | Default Ports | Override Variable(s) | Conflict |
|---|---|---|---|
| datalust-seq | 5341 (ingest), 8090 (UI) | `SEQ_INGEST_PORT`, `SEQ_UI_PORT` | — |
| homarr | 7575 | `HOMARR_PORT` | — |
| jenkins | 8080 (web), 50000 (agent) | `JENKINS_PORT`, `JENKINS_AGENT_PORT` | **8080 conflicts with Kafka UI** |
| nginx-proxy-manager | 80, 443, 81 (admin) | `NPM_HTTP_PORT`, `NPM_HTTPS_PORT`, `NPM_ADMIN_PORT` | — |
| portainer | 9443 (UI), 8000 (tunnel) | `PORTAINER_HTTPS_PORT`, `PORTAINER_TUNNEL_PORT` | — |
| sonarqube | 9000 | `SONARQUBE_PORT` | — |
| kafka-ui | 8080 | `KAFKA_UI_PORT` | **8080 conflicts with Jenkins** |
| kafka broker 1 | 9092 (ext), 9093 (ctrl), 29092 (int) | `KAFKA1_EXTERNAL_PORT`, `KAFKA1_CONTROLLER_PORT`, `KAFKA1_INTERNAL_PORT` | — |
| kafka broker 2 | 9094 (ext), 9095 (ctrl), 29093 (int) | `KAFKA2_EXTERNAL_PORT`, `KAFKA2_CONTROLLER_PORT`, `KAFKA2_INTERNAL_PORT` | — |
| kafka broker 3 | 9096 (ext), 9097 (ctrl), 29094 (int) | `KAFKA3_EXTERNAL_PORT`, `KAFKA3_CONTROLLER_PORT`, `KAFKA3_INTERNAL_PORT` | — |

---

## Prerequisites

- [Docker Engine](https://docs.docker.com/engine/install/) 20.10 or newer
- [Docker Compose v2](https://docs.docker.com/compose/install/) (the `docker compose` plugin)
- Git (to clone this repository)

Each template's own README may list additional host-level requirements (e.g., `vm.max_map_count` for SonarQube).

---

## Usage

> **Always read the per-template README before starting.** Several templates require credentials, host IPs, or other values to be set in `.env` before the first run.

```bash
# 1. Clone the repository
git clone https://github.com/gmbalaa14/docker-templates.git
cd docker-templates

# 2. (Once) Create shared networks
docker network create proxy-net
docker network create kafka-ui-net

# 3. Change into the desired template directory
cd <template-name>

# 4. Copy and fill in the environment file
cp .env.example .env
# Edit .env with your values

# 5. Start the service
docker compose up -d
```

---

## Deployment Options

### Docker CLI

Use `docker compose up -d` from within any template directory. See each template's README for specific steps.

### Portainer Stacks

1. In Portainer, go to **Stacks → Add stack**.
2. Choose **Repository** and point to this repo, or paste the compose file content.
3. Add environment variables under the **Environment variables** section (equivalent to `.env`).
4. Click **Deploy the stack**.

Note: Portainer's environment variables UI replaces the `.env` file for Git-based stacks.

### Docker Desktop

All templates use named volumes (no host-path bind mounts), making them fully compatible with Docker Desktop on Mac and Windows. Platform-specific notes (e.g., `vm.max_map_count` for SonarQube, host IP for Kafka) are documented in each template's README.

---

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](./CONTRIBUTING.md) for naming conventions, required files, Docker Compose best practices, and the PR checklist.

---

## License

This project is licensed under the Apache License 2.0. See [LICENSE](./LICENSE) for details.
