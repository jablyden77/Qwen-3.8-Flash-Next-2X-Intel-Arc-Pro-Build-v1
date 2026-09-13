#!/usr/bin/env bash
set -euo pipefail

PORT=${PORT:-18126}
NAME=${NAME:-flashnext-m64-ngl47}

echo "== API health =="
curl -fsS "http://127.0.0.1:${PORT}/health"
echo

echo "== Container =="
docker ps --filter "name=${NAME}"

echo "== GPU 0 =="
xpu-smi stats -d 0 | grep -E 'GPU Memory Used|GPU Memory Util|GPU Power|GPU Frequency' || true

echo "== GPU 1 =="
xpu-smi stats -d 1 | grep -E 'GPU Memory Used|GPU Memory Util|GPU Power|GPU Frequency' || true

echo "== Host memory =="
free -h
