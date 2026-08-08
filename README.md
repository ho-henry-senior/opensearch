# Local OpenSearch Logging

Local Docker logging stack using OpenSearch, OpenSearch Dashboards, and Vector.

Vector reads logs from the local Docker daemon, enriches them with Docker/Compose
metadata, and writes them into daily OpenSearch indices.

The Compose stack also runs a one-shot setup container that installs the
OpenSearch index template and creates the `docker-logs-*` Dashboards data view.

This setup is intended for local development only. OpenSearch security is
disabled.

## Prerequisites

- Docker
- Docker Compose v2
- Access to the local Docker socket

## Services

- OpenSearch: <http://localhost:9200>
- OpenSearch Dashboards: <http://localhost:5601>
- Vector API: internal only, `0.0.0.0:8686` inside the container

## Start

```sh
docker compose up -d
```

OpenSearch can take a minute or two to become ready on first start. The `setup`
service waits for OpenSearch and Dashboards, then creates:

- an index template for `docker-logs-*`
- the `docker-logs-*` Dashboards data view
- a `timestamp` time field for the data view

## Check Logs Are Arriving

```sh
curl "http://localhost:9200/_cat/indices/docker-logs-*?v"
```

You should see an index like:

```text
docker-logs-2026.08.08
```

## Open Logs

Open <http://localhost:5601>, then go to Discover and select:

```text
docker-logs-*
```

## Useful Fields

The log documents include:

- `timestamp`: ingestion timestamp
- `message`: log line
- `container`: Docker container name
- `container_id`: Docker container ID
- `compose_project`: Docker Compose project name, when present
- `compose_service`: Docker Compose service name, when present
- `image`: container image
- `stream`: stdout or stderr

Example filters in Discover:

```text
compose_service.keyword: "gateway-api"
container.keyword: "some-container-name"
stream.keyword: "stderr"
```

## Stop

```sh
docker compose down
```

To remove persisted OpenSearch and Vector data:

```sh
docker compose down -v
```

## Troubleshooting

Check container status:

```sh
docker compose ps
```

Check service logs:

```sh
docker compose logs --tail=100 opensearch
docker compose logs --tail=100 dashboards
docker compose logs --tail=100 vector
docker compose logs setup
```

If Dashboards says the server is not ready yet, first check that OpenSearch is
running:

```sh
curl http://localhost:9200
```

If the data view is missing, rerun the one-shot setup service:

```sh
docker compose up setup
```

The setup service sets `number_of_replicas` to `0` for `docker-logs-*`, so the
log indices should be green in this single-node stack.
