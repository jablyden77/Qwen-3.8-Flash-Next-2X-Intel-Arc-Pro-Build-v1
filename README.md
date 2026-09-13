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
- Context: **65,536 tokens (64K)**
- Parallel streams: 1
- Batch / ubatch: 2048 / 2048
- Flash attention: auto
- Host RAM: 64 GB installed, roughly 59 GiB visible to Linux
- 32K steady-state VRAM baseline: about **27.6 GiB / 27.2 GiB**
- 64K deep-context VRAM: about **29.4 GiB / 28.9 GiB**
- Short-context sustained decode: about **21–22 tok/s**
- Deep-context decode near 57K: about **14.9 tok/s**
- Deep-context decode near 62.7K: about **14.4 tok/s**
- Largest validated request: about **62,660 prompt tokens + 256 generated tokens**

The key tuning result is that `--n-gpu-layers 47` retains essentially all sustained decode performance of the original all-GPU placement while recovering several GiB of additional VRAM headroom per B70. The 64K profile uses some of that margin for KV/context growth while remaining stable near the top of the window.

## Repository layout

- `start-flashnext-ngl47.sh` — validated 32K launcher/reference profile
- `BENCHMARKS.md` — 32K and 64K benchmark results, including deep-context PP/TG measurements
- `scripts/healthcheck.sh` — API and memory health check
- `scripts/benchmark.py` — repeatable single-stream benchmark client
- `docs/HARDWARE.md` — hardware BOM, PCIe topology, RAM, BIOS notes
- `docs/SOFTWARE_STACK.md` — OS, Docker, Intel/SYCL and container runtime details
- `docs/MODEL.md` — checkpoint layout and storage/mmap behavior
- `docs/BUILD_AND_DEPLOY.md` — end-to-end installation and deployment procedure
- `docs/TUNING.md` — GPU layer sweep, memory-placement reasoning, context and batch notes
- `docs/VLLM_XPU_EXPERIMENTS.md` — W4A16/PLE TP2 research lane and why it currently behaves differently
- `docs/TROUBLESHOOTING.md` — OOM, startup, GPU visibility and performance troubleshooting

## Current recommendation

Use the same `ngl=47` placement with:

```text
--ctx-size 65536
--parallel 1
--batch-size 2048
--ubatch-size 2048
--flash-attn auto
```

The validated 64K context ladder shows a gradual decode decline rather than a cliff:

```text
short context     ~21-22 tok/s
11K               ~19.4 tok/s
22K               ~18.1 tok/s
33K               ~16.9 tok/s
41K               ~16.0 tok/s
57K               ~14.9 tok/s
62.7K             ~14.4 tok/s
```

At the deepest tested point, VRAM remained around 29.4 / 28.9 GiB and host RAM still had roughly 49 GiB available. No OOM or late-context instability was observed.

## Quick start

1. Build the dual-B70 host according to `docs/HARDWARE.md`.
2. Install Linux, Docker and Intel GPU support as described in `docs/SOFTWARE_STACK.md`.
3. Place all 33 GGUF shards in a single model directory.
4. Edit `MODEL_DIR` in the launcher or export it before launch.
5. Set `--ctx-size 65536` for the recommended profile.
6. Verify `/health` and GPU memory with `scripts/healthcheck.sh`.
7. Run `scripts/benchmark.py` to verify decode performance.

The server is intentionally published to localhost by default. Put a reverse proxy or authenticated API gateway in front of it if remote access is required.

## Why this configuration exists

The first working configuration placed effectively the maximum possible model state on both B70s and used around 30.1 / 29.8 GiB of VRAM. It ran correctly at roughly 21–22 tok/s but left little safety margin for allocator growth, KV/runtime changes, experimentation, or larger ancillary buffers.

A controlled `n-gpu-layers` sweep showed that 47 GPU layers reduced steady-state VRAM to about 27.6 / 27.2 GiB at 32K while maintaining roughly the same sustained generation speed. The 64K configuration uses about 29.4 / 28.9 GiB at deep context and has been validated beyond 62K prompt tokens.

That is why **`ngl=47` + 64K context** is now the recommended 64-GB-host-RAM baseline.

## Status

This repository documents the **known-good SYCL/llama.cpp deployment**. A separate vLLM XPU TP2/EP2 W4A16 path is under active investigation and is documented separately because its model-loading and host-memory behavior is currently different from the working llama.cpp path.