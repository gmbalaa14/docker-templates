# Confluent Kafka — 3-Node KRaft Cluster (SASL/PLAIN Authentication)

A production-style 3-node Apache Kafka cluster using Confluent Platform 7.8.0 in KRaft mode (no ZooKeeper required). Brokers run as both controllers and brokers. SASL/PLAIN authentication is enabled on all listeners.

Use the [kafka-ui](../kafka-ui/) template to manage this cluster through a web interface.

## Prerequisites

- Docker and Docker Compose v2
- At least 6 GB of RAM available for the three broker processes
- The `kafka-ui-net` shared network must exist (see below)
- Your host's IP address (required — see `.env` setup)

## Shared Network Setup

Brokers join `kafka-ui-net` so Kafka UI can reach them. Create it once on your host:

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

All ports are configurable via `.env` (see `KAFKA1_*`, `KAFKA2_*`, `KAFKA3_*` variables).

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

Edit `.env` — all three variables below are **required** with no defaults:

### 1. Host IP (`KAFKA_HOST_IP`)

The external IP of your Docker host, used in `KAFKA_ADVERTISED_LISTENERS` so clients outside Docker can connect.

```bash
# Linux
ip route get 1 | awk '{print $7; exit}'

# macOS
ipconfig getifaddr en0

# Docker Desktop (Mac)
# Use: host.docker.internal

# Docker Desktop (Windows)
# Use your host machine's LAN IP
```

### 2. Cluster ID (`KAFKA_CLUSTER_ID`)

A unique UUID for this KRaft cluster. Generate one:

```bash
docker run --rm confluentinc/cp-kafka:7.8.0 kafka-storage random-uuid
```

> **WARNING:** Never reuse a Cluster ID across two different clusters. Shared IDs corrupt KRaft metadata.

### 3. SASL Credentials (`KAFKA_ADMIN_PASSWORD`, `KAFKA_TEST_PASSWORD`)

Set strong, unique passwords for the `admin` and `test` users before connecting the cluster to any network.

## Start

```bash
docker compose up -d
```

Verify all brokers are healthy:

```bash
docker compose ps
docker compose logs kafka1 | grep "Kafka Server started"
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

**SASL/PLAIN connection properties:**
```properties
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="admin" password="<KAFKA_ADMIN_PASSWORD>";
```

## Stop & Cleanup

```bash
# Stop (topic data preserved)
docker compose down

# Stop and remove all topic and offset data
docker compose down -v
```

> **WARNING:** `docker compose down -v` permanently deletes all Kafka topics, messages, consumer group offsets, and cluster metadata.

## Deploy with Portainer

1. Ensure `kafka-ui-net` exists on the host: `docker network create kafka-ui-net`
2. In Portainer, go to **Stacks → Add stack**.
3. Paste the compose file content.
4. Set `KAFKA_HOST_IP`, `KAFKA_CLUSTER_ID`, `KAFKA_ADMIN_PASSWORD`, and `KAFKA_TEST_PASSWORD` under **Environment variables**.
5. Click **Deploy the stack**.

## Docker Desktop Notes

- **Mac:** Set `KAFKA_HOST_IP=host.docker.internal` in `.env`.
- **Windows:** Use the host machine's LAN IP address.
- Ensure Docker Desktop has at least 6 GB of memory allocated in **Settings → Resources**.

## KRaft Architecture

Each node runs as both a broker and a controller (`KAFKA_PROCESS_ROLES: 'broker,controller'`). There is no ZooKeeper dependency. The quorum is maintained via `KAFKA_CONTROLLER_QUORUM_VOTERS` across all three nodes. The `kafka-net` internal network handles inter-broker and controller traffic.

## References

- [Confluent Platform documentation](https://docs.confluent.io/)
- [KRaft mode overview](https://developer.confluent.io/learn/kraft/)
