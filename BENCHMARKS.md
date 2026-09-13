# Benchmarks

Validated on 2x Intel Arc Pro B70 with 64 GB host RAM using the SYCL/llama.cpp `ngl=47` profile.

## Test conditions

- single request stream
- current default context: **65,536 tokens**
- `--parallel 1`
- `--batch-size 2048`
- `--ubatch-size 2048`
- `--flash-attn auto`
- `GGML_SYCL_FA_ONEDNN=0`
- layer split across `SYCL0,SYCL1`
- equal tensor split `1,1`
- 47 GPU layers
- no second model service sharing the B70s during the benchmark

The llama.cpp server timing lines are the authoritative throughput numbers below.

## 32K sustained single-stream decode baseline

| Output tokens | Decode throughput |
|---:|---:|
| 128 | 21.12 tok/s |
| 256 | 21.80 tok/s |
| 512 | 21.92 tok/s |
| 1,024 | about 21.8 tok/s |
| 2,048 | 21.65 tok/s |
| 4,096 | 21.02 tok/s |

The 4,096-token run required about 194.8 seconds of decode time. Near the end, short-window decode remained around 20.4-20.6 tok/s. There was no throughput collapse.

## 64K context validation

The same `ngl=47` placement was restarted with `--ctx-size 65536` and then tested progressively deeper into the context window.

| Actual prompt depth | Prompt processing | Decode |
|---:|---:|---:|
| ~5.5K | 575.12 tok/s | 20.21 tok/s |
| ~11K | 565.00 tok/s | 19.42 tok/s |
| ~22K | about 468 tok/s* | 18.14 tok/s |
| ~33K | about 395 tok/s* | 16.85 tok/s |
| ~41K | about 350 tok/s* | 16.01 tok/s |
| 57.4K | 390.51 tok/s | 14.86 tok/s |
| 62.7K | about 278 tok/s* | 14.37 tok/s |

`*` Some intermediate PP figures reflect partial/common-prefix reuse by llama.cpp rather than a full cold prefill. The 57.4K result is especially useful because it represents an essentially fresh large-context prefill.

The largest successful probe used approximately **62,660 prompt tokens plus 256 generated tokens**, remaining inside the 65,536-token allocation. It completed successfully with no OOM, crash or truncation.

### 64K memory footprint

At deep context the observed steady-state footprint was approximately:

- B70 #0: **29.38 GiB VRAM used**
- B70 #1: **28.89 GiB VRAM used**
- host actively used: about **9.8 GiB**
- host available: about **49 GiB**
- swap in use: about **2.8 GiB**
- no late-context VRAM growth or OOM was observed

Compared with the 32K profile at roughly 27.6 / 27.2 GiB, doubling the configured window to 64K cost only about 1.3-1.7 GiB additional VRAM per GPU while still leaving meaningful headroom.

## Practical deep-context performance curve

```text
short context     ~21-22 tok/s
11K               ~19.4 tok/s
22K               ~18.1 tok/s
33K               ~16.9 tok/s
41K               ~16.0 tok/s
57K               ~14.9 tok/s
62.7K             ~14.4 tok/s
```

The important finding is that throughput declines gradually as context grows; there is no sharp performance cliff near the top of the 64K window.

## GPU-layer sweep

| Configuration | B70 #0 | B70 #1 | 256-token decode |
|---|---:|---:|---:|
| `ngl=999` | ~30.14 GiB | ~29.81 GiB | ~21.61 tok/s |
| `ngl=40` | ~23.03 GiB | ~23.92 GiB | 15.65 tok/s |
| `ngl=44` | ~25.10 GiB | ~26.14 GiB | 18.52 tok/s |
| `ngl=46` | ~26.38 GiB | ~27.16 GiB | 19.77 tok/s |
| `ngl=47` | ~27.61 GiB | ~27.16 GiB | 20.65 tok/s |

Longer `ngl=47` runs subsequently stabilized around 21-22 tok/s at short context.

## Conclusion

`ngl=47` remains the recommended placement, and **64K is now the recommended default context window** for this build. It preserves useful VRAM headroom while supporting real prompt depths beyond 62K tokens. Short-context decode remains around 21-22 tok/s, while very deep-context decode remains around 14-15 tok/s near the top of the window.