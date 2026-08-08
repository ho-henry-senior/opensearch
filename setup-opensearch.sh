#!/bin/sh
set -eu

OPENSEARCH_URL="${OPENSEARCH_URL:-http://opensearch:9200}"
DASHBOARDS_URL="${DASHBOARDS_URL:-http://dashboards:5601}"

echo "Waiting for OpenSearch at ${OPENSEARCH_URL}"
until curl -fsS "${OPENSEARCH_URL}" >/dev/null; do
  sleep 2
done

echo "Installing docker log index template"
curl -fsS -X PUT "${OPENSEARCH_URL}/_index_template/docker-logs" \
  -H "Content-Type: application/json" \
  -d '{
    "index_patterns": ["docker-logs-*"],
    "template": {
      "settings": {
        "number_of_shards": 1,
        "number_of_replicas": 0
      },
      "mappings": {
        "properties": {
          "timestamp": { "type": "date" },
          "container": { "type": "keyword" },
          "container_id": { "type": "keyword" },
          "container_name": { "type": "keyword" },
          "compose_project": { "type": "keyword" },
          "compose_service": { "type": "keyword" },
          "image": { "type": "keyword" },
          "stream": { "type": "keyword" },
          "message": { "type": "text" }
        }
      }
    }
  }' >/dev/null

echo "Normalising existing docker log indices"
curl -fsS -X PUT "${OPENSEARCH_URL}/docker-logs-*/_settings" \
  -H "Content-Type: application/json" \
  -d '{ "index": { "number_of_replicas": 0 } }' >/dev/null || true

echo "Waiting for OpenSearch Dashboards at ${DASHBOARDS_URL}"
until curl -fsS "${DASHBOARDS_URL}/api/status" >/dev/null; do
  sleep 2
done

echo "Creating docker-logs-* data view"
curl -fsS -X POST "${DASHBOARDS_URL}/api/saved_objects/index-pattern/docker-logs-*?overwrite=true" \
  -H "Content-Type: application/json" \
  -H "osd-xsrf: true" \
  -d '{
    "attributes": {
      "title": "docker-logs-*",
      "timeFieldName": "timestamp"
    }
  }' >/dev/null

echo "OpenSearch logging setup complete"
