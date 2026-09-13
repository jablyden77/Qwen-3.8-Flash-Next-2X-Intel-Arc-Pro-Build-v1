# Build and deployment

## Host preparation

Install Ubuntu 26.04 on the dual-B70 workstation. Confirm that both Intel Arc Pro B70 cards are visible before installing the inference runtime.

Use `lspci` and `xpu-smi discovery` to confirm two discrete Intel GPUs. Verify each card reports 32 GiB VRAM and that both PCIe links are operating at the intended generation and width.

## Docker

Install Docker Engine and verify the current user can run containers. The validated runtime uses the Intel llama.cpp server image:

`ghcr.io/ggml-org/llama.cpp:server-intel`

For long-term reproducibility, record the exact image digest after validating a known-good image.

## Render devices

The launcher exposes two DRM render nodes to the container. On another machine, confirm which render nodes belong to the B70s and identify the local render-group id before launching.

The known-good profile passes two render nodes, adds the render group, and sets `GGML_SYCL_FA_ONEDNN=0`.

## Model placement

Place all 33 GGUF shards of `Qwen3.8-Flash-Next-AD-4.27bpw-Q4_K_M-M64` in one directory on local NVMe storage. The complete set is about 89 GB.

A neutral example path is `/opt/models/Qwen3.8-Flash-Next-AD-4.27bpw-Q4_K_M-M64`.

The directory is mounted read-only at `/model` inside the container.

## Validated runtime arguments

The final production-style profile is:

```text
--device SYCL0,SYCL1
--n-gpu-layers 47
--split-mode layer
--tensor-split 1,1
--ctx-size 32768
--parallel 1
--flash-attn auto
--batch-size 2048
--ubatch-size 2048
```

The host-side listener is bound to localhost only. The container listens on port 8000; the example launcher maps it to local port 18126.

## Launch

Export a neutral model location and run the checked-in launcher:

```bash
export MODEL_DIR=/opt/models/Qwen3.8-Flash-Next-AD-4.27bpw-Q4_K_M-M64
export PORT=18126
bash ./start-flashnext-ngl47.sh
```

Follow initialization with `docker logs -f flashnext-m64-ngl47`.

## Validation

After startup, verify the health endpoint on localhost. Then verify both GPUs with `xpu-smi stats -d 0` and `xpu-smi stats -d 1`.

A normal idle/ready state for the validated profile is approximately 27.6 GiB used on one B70 and 27.2 GiB on the other. Small boot-to-boot differences are expected.

Run a short completion before benchmarking. The model should return a valid response without OOM events, container restarts, or growing VRAM usage.

## Benchmark expectation

Steady-state single-stream decode should land close to 21-22 tokens per second. The validated 4096-token output test averaged 21.02 tok/s.

## Remote access

Keep the raw llama.cpp server on localhost. If another machine needs access, put an authenticated reverse proxy or application gateway in front of the local endpoint. This repository intentionally contains no real IP addresses, private hostnames, credentials, or certificates.