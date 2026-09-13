# Benchmarks

Validated on 2x Intel Arc Pro B70 with 64 GB host RAM using the SYCL/llama.cpp `ngl=47` profile.

## Sustained single-stream decode

| Output tokens | Decode throughput |
|---:|---:|
| 128 | 21.12 tok/s |
| 256 | 21.80 tok/s |
| 512 | 21.92 tok/s |
| 1,024 | ~21.8 tok/s |
| 2,048 | 21.65 tok/s |
| 4,096 | 21.02 tok/s |

The 4,096-token run completed with stable VRAM use and no OOM event. Near the end of that run, short-window decode remained around 20.4 tok/s.

## VRAM / host memory

`ngl=47` under generation load:

- B70 #0: about 27.6 GiB VRAM used
- B70 #1: about 27.2 GiB VRAM used
- Host actively used: about 6-7 GiB
- Host available: about 52-53 GiB

## GPU-layer sweep

| Configuration | B70 #0 | B70 #1 | Decode |
|---|---:|---:|---:|
| `ngl=999` | ~30.1 GiB | ~29.8 GiB | ~21.6-22 tok/s |
| `ngl=40` | ~23.0 GiB | ~23.9 GiB | 15.65 tok/s |
| `ngl=44` | ~25.1 GiB | ~26.1 GiB | 18.52 tok/s |
| `ngl=46` | ~26.4 GiB | ~27.2 GiB | 19.77 tok/s |
| `ngl=47` | ~27.6 GiB | ~27.2 GiB | 20.65-21.92 tok/s |

`ngl=47` is the current recommended configuration because it preserves nearly all all-GPU decode performance while reclaiming roughly 2.5-3 GiB of VRAM headroom per B70.
