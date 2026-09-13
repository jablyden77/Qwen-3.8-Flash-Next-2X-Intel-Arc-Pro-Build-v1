# Model layout and memory behavior

## Validated checkpoint

The working deployment uses `Qwen3.8-Flash-Next-AD-4.27bpw-Q4_K_M-M64` in GGUF format.

The checkpoint is split into 33 GGUF files and uses about 89 GB of storage. Keep all shards together in one directory.

Example first shard:

`Qwen3.8-Flash-Next-AD-4.27bpw-Q4_K_M-M64-00001-of-00033.gguf`

The rest continue through shard 33.

## Why the model can run with 64 GB host RAM

The model is larger than available host RAM, but the working llama.cpp path does not require all 89 GB to live in anonymous process memory at once. The GGUF files are mapped and Linux can retain useful file-backed pages in page cache while reclaiming them when memory pressure changes.

On the validated host, 64 GB is installed and Linux exposes about 59 GiB. During the final `ngl=47` benchmark runs, roughly 6-7 GiB was counted as actively used while more than 50 GiB remained available because much of the model-backed memory was reclaimable cache.

This behavior is materially different from the experimental vLLM W4A16 TP2 path, where concurrent worker initialization caused host-memory pressure and OOM events.

## GPU placement

The original all-GPU llama.cpp configuration used about 30.1 GiB on GPU 0 and 29.8 GiB on GPU 1. It worked and sustained roughly 21-22 tok/s, but left little VRAM margin.

The optimized configuration uses 47 GPU layers and settles near 27.6 GiB and 27.2 GiB. This moves a modest portion of the model out of VRAM and recovers about 2.5-3 GiB of extra headroom per card without materially reducing sustained decode throughput.

## Storage recommendation

Use local NVMe storage for the GGUF shard set. A mechanical disk can make cold startup and page-fault-heavy operation much slower.

A neutral layout is:

```text
/opt/models/
└── Qwen3.8-Flash-Next-AD-4.27bpw-Q4_K_M-M64/
    ├── ...-00001-of-00033.gguf
    ├── ...-00002-of-00033.gguf
    ├── ...
    └── ...-00033-of-00033.gguf
```

## Integrity and reproducibility

Record the exact model source, quant name, file count and checksums used for a benchmark. Also record the exact container image digest. Performance and memory figures in this repository apply to the tested GGUF quant and runtime combination, not to every Flash-Next checkpoint.