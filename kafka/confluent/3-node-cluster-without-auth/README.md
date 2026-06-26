# Confluent Kafka — 3-Node KRaft Cluster (No Authentication)

A 3-node Apache Kafka cluster using Confluent Platform 7.8.0 in KRaft mode with plaintext listeners and no authentication.

> **WARNING — Development Use Only:** This cluster has no authentication or encryption. All data is transmitted in plaintext and any client can connect without credentials. Do not use this configuration in production or on any network accessible to untrusted parties.

For production use, see the [3-node-cluster-with-auth](../3-node-cluster-with-auth/) template.

Use the [kafka-ui](../kafka-ui/) template to manage this cluster through a web interface.

## Prerequisites

- Docker and Docker Compose v2
- At least 6 GB of RAM available for the three broker processes
- The `kafka-ui-net` shared network must exist (see below)
- Your host's IP address (required — see `.env` setup)

## Shared Network Setup

```bash
docker network create kafka-ui-net
```

## Ports

| Port (default) | Broker | Purpose |
|----------------|--------|---------|
| 9092 | kafka1 | External listener |
| 9093 | kafka1 | KRaft controller |
| 29092 | kafka1 | Internal listener |
| 9094 | kafka2 | External listener |
| 9095 | kafka2 | KRaft controller |
| 29093 | kafka2 | Internal listener |
| 9096 | kafka3 | External listener |
| 9097 | kafka3 | KRaft controller |
| 29094 | kafka3 | Internal listener |

All ports are configurable via `.env`.

## Volumes

| Volume | Purpose |
|--------|---------|
| `kafka1_data` | kafka1 log data |
| `kafka2_data` | kafka2 log data |
| `kafka3_data` | kafka3 log data |

## Setup

```bash
cp .env.example .env
```

Two variables are **required** with no defaults:

### 1. Host IP (`KAFKA_HOST_IP`)

```bash
# Linux
ip route get 1 | awk '{print $7; exit}'
# macOS
ipconfig getifaddr en0
# Docker Desktop (Mac): host.docker.internal
```

### 2. Cluster ID (`KAFKA_CLUSTER_ID`)

```bash
docker run --rm confluentinc/cp-kafka:7.8.0 kafka-storage random-uuid
```

> **WARNING:** Never reuse a Cluster ID across two different clusters.

## Start

```bash
docker compose up -d
```

## Connecting Clients

**Internal (from within Docker / kafka-ui-net):**
```
kafka1:29092,kafka2:29092,kafka3:29092
```

**External (from the host or LAN):**
```
<KAFKA_HOST_IP>:9092,<KAFKA_HOST_IP>:9094,<KAFKA_HOST_IP>:9096
```

No security properties required — plaintext connection.

## Stop & Cleanup

```bash
# Stop (topic data preserved)
docker compose down

# Stop and remove all topic data
docker compose down -v
```

> **WARNING:** `docker compose down -v` permanently deletes all topics, messages, and cluster metadata.

## Deploy with Portainer

1. Ensure `kafka-ui-net` exists: `docker network create kafka-ui-net`
2. In Portainer, go to **Stacks → Add stack**.
3. Set `KAFKA_HOST_IP` and `KAFKA_CLUSTER_ID` under **Environment variables**.
4. Click **Deploy the stack**.

## Docker Desktop Notes

- **Mac:** Set `KAFKA_HOST_IP=host.docker.internal`.
- **Windows:** Use the host machine's LAN IP.
- Allocate at least 6 GB of memory in Docker Desktop **Settings → Resources**.

## References

- [Confluent Platform documentation](https://docs.confluent.io/)
- [KRaft mode overview](https://developer.confluent.io/learn/kraft/)
