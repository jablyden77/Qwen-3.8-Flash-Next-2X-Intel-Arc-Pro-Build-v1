# Qwen3.8 Flash-Next on 2x Intel Arc Pro B70

A reproducible build record for running **Qwen3.8-Flash-Next** on **two Intel Arc Pro B70 32 GiB GPUs** with **64 GB host RAM**, using the Intel/SYCL build of `llama.cpp`.

This repository documents the complete validated system: hardware, BIOS assumptions, OS/runtime, model format, container configuration, memory placement, launch scripts, health checks, benchmarks, tuning history, failure modes, and the separate vLLM/XPU research lane.

No private hostnames, IP addresses, internal certificates, usernames, or site-specific device names are included. Examples use neutral names and localhost-only endpoints.

## Validated production-style profile

- Model: `Qwen3.8-Flash-Next-AD-4.27bpw-Q4_K_M-M64`
- Format: sharded GGUF, 33 files, about 89 GB on disk
- Runtime: `ghcr.io/ggml-org/llama.cpp:server-intel`
- Compute backend: Intel SYCL / Level Zero
- GPUs: 2x Intel Arc Pro B70, 32 GiB each
- GPU split: `SYCL0,SYCL1`, layer split, `1,1`
- GPU layers: **47**
- Context: **32,768 tokens**
- Parallel streams: 1
- Batch / ubatch: 2048 / 2048
- Flash attention: auto
- Host RAM: 64 GB installed, roughly 59 GiB visible to Linux
- Measured steady-state VRAM: about **27.6 GiB / 27.2 GiB**
- Sustained single-stream decode: about **21–22 tok/s**
- 4,096-token generation: **21.02 tok/s average**

The key tuning result is that `--n-gpu-layers 47` retains essentially all sustained decode performance of the original all-GPU placement while recovering roughly 2.5–3 GiB of additional VRAM headroom per B70.

## Repository layout

- `start-flashnext-ngl47.sh` — validated launcher
- `scripts/healthcheck.sh` — API and memory health check
- `scripts/benchmark.py` — repeatable single-stream benchmark client
- `docs/HARDWARE.md` — hardware BOM, PCIe topology, RAM, BIOS notes
- `docs/SOFTWARE_STACK.md` — OS, Docker, Intel/SYCL and container runtime details
- `docs/MODEL.md` — checkpoint layout and storage/mmap behavior
- `docs/BUILD_AND_DEPLOY.md` — end-to-end installation and deployment procedure
- `docs/TUNING.md` — GPU layer sweep, memory-placement reasoning, context and batch notes
- `docs/VLLM_XPU_EXPERIMENTS.md` — W4A16/PLE TP2 research lane and why it currently behaves differently
- `docs/TROUBLESHOOTING.md` — OOM, startup, GPU visibility and performance troubleshooting
- `BENCHMARKS.md` — measured performance data from the validated host

## Quick start

1. Build the dual-B70 host according to `docs/HARDWARE.md`.
2. Install Linux, Docker and Intel GPU support as described in `docs/SOFTWARE_STACK.md`.
3. Place all 33 GGUF shards in a single model directory.
4. Edit `MODEL_DIR` in `start-flashnext-ngl47.sh` or export it before launch.
5. Run the launcher.
6. Verify `/health` and GPU memory with `scripts/healthcheck.sh`.
7. Run `scripts/benchmark.py` to verify decode performance.

Example:

```bash
export MODEL_DIR=/opt/models/Qwen3.8-Flash-Next-AD-4.27bpw-Q4_K_M-M64
export PORT=18126
bash ./start-flashnext-ngl47.sh
```

The server is intentionally published to localhost by default. Put a reverse proxy or authenticated API gateway in front of it if remote access is required.

## Why this configuration exists

The first working configuration placed effectively the maximum possible model state on both B70s and used around 30.1 / 29.8 GiB of VRAM. It ran correctly at roughly 21–22 tok/s but left little safety margin for allocator growth, KV/runtime changes, experimentation, or larger ancillary buffers.

A controlled `n-gpu-layers` sweep showed that 47 GPU layers reduced steady-state VRAM to about 27.6 / 27.2 GiB while maintaining roughly the same sustained generation speed. The remaining model data is handled through host memory and mmap/page-cache behavior rather than being eagerly duplicated into process RSS.

That is why `ngl=47` is the recommended 64-GB-host-RAM baseline.

## Status

This repository documents the **known-good SYCL/llama.cpp deployment**. A separate vLLM XPU TP2/EP2 W4A16 path is under active investigation and is documented separately because its model-loading and host-memory behavior is currently different from the working llama.cpp path.