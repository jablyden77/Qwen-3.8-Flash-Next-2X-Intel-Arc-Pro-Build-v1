# Qwen3.8 Flash-Next on 2x Intel Arc Pro B70

Validated SYCL/llama.cpp configuration for Qwen3.8-Flash-Next on two Intel Arc Pro B70 GPUs with 32 GiB VRAM each and 64 GB host RAM.

## Recommended profile

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

The tested model is `Qwen3.8-Flash-Next-AD-4.27bpw-Q4_K_M-M64` running in the Intel llama.cpp server container.

The `ngl=47` profile gave the best balance between decode speed and VRAM headroom. See `BENCHMARKS.md` for measured results.

Use `start-flashnext-ngl47.sh` to launch the validated configuration. Adjust the model path and port variables at the top of the script if needed.
