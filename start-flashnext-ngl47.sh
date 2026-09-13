#!/usr/bin/env bash
set -euo pipefail

NAME=${NAME:-flashnext-m64-ngl47}
MODEL_DIR=${MODEL_DIR:-/opt/models/Qwen3.8-Flash-Next-AD-4.27bpw-Q4_K_M-M64}
MODEL=${MODEL:-Qwen3.8-Flash-Next-AD-4.27bpw-Q4_K_M-M64-00001-of-00033.gguf}
PORT=${PORT:-18126}
IMAGE=${IMAGE:-ghcr.io/ggml-org/llama.cpp:server-intel}
GPU0=${GPU0:-/dev/dri/renderD128}
GPU1=${GPU1:-/dev/dri/renderD129}
RENDER_GID=${RENDER_GID:-$(stat -c '%g' "$GPU0")}

for path in "$GPU0" "$GPU1" "$MODEL_DIR/$MODEL"; do
  [[ -e "$path" ]] || { echo "Missing required path: $path" >&2; exit 1; }
done

docker rm -f "$NAME" >/dev/null 2>&1 || true

exec docker run --name "$NAME" \
  --device "$GPU0:$GPU0" \
  --device "$GPU1:$GPU1" \
  --group-add "$RENDER_GID" \
  -e GGML_SYCL_FA_ONEDNN=0 \
  -v "$MODEL_DIR:/model:ro" \
  -p "127.0.0.1:${PORT}:8000" \
  "$IMAGE" \
  --model "/model/$MODEL" \
  --host 0.0.0.0 \
  --port 8000 \
  --jinja \
  --device SYCL0,SYCL1 \
  --n-gpu-layers 47 \
  --split-mode layer \
  --tensor-split 1,1 \
  --ctx-size 32768 \
  --parallel 1 \
  --flash-attn auto \
  --batch-size 2048 \
  --ubatch-size 2048
