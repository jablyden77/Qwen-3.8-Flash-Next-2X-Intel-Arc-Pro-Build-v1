# Benchmarks

Validated on 2x Intel Arc Pro B70 with 64 GB host RAM using the SYCL/llama.cpp `ngl=47` profile.

## Test conditions

- single request stream
- 32,768-token configured context
- `--parallel 1`
- `--batch-size 2048`
- `--ubatch-size 2048`
- `--flash-attn auto`
- `GGML_SYCL_FA_ONEDNN=0`
- layer split across `SYCL0,SYCL1`
- equal tensor split `1,1`
- 47 GPU layers
- no second model service sharing the B70s during the benchmark

The llama.cpp server timing lines are the authoritative decode numbers below. Client wall-clock timing can be lower on short tests because request setup and prompt handling are included.

## Sustained single-stream decode

| Output tokens | Decode throughput |
|---:|---:|
| 128 | 21.12 tok/s |
| 256 | 21.80 tok/s |
| 512 | 21.92 tok/s |
| 1,024 | about 21.8 tok/s |
| 2,048 | 21.65 tok/s |
| 4,096 | 21.02 tok/s |

The 4,096-token run required about 194.8 seconds of decode time. At roughly 3,900 generated tokens the running average was still about 21.05 tok/s, while the short-window rate near the end remained around 20.4-20.6 tok/s.

That slow decline is expected as the active context grows. There was no throughput collapse.

## VRAM and host memory

`ngl=47` during generation:

- B70 #0: about 27.6 GiB VRAM used
- B70 #1: about 27.2 GiB VRAM used
- Host actively used: about 6-7 GiB
- Host available: about 52-53 GiB
- VRAM remained essentially flat through the 4K output run
- no OOM event was observed in the validated llama.cpp profile

## Original working all-GPU profile

The first successful Flash-Next build used effectively all GPU layers:

- B70 #0: about 30.1 GiB
- B70 #1: about 29.8 GiB
- sustained decode: roughly 20-22 tok/s depending on request/context
- larger-prompt prefill observed around 430-515 tok/s in captured runs

It was functional and stable, but left little VRAM safety margin.

## GPU-layer sweep

| Configuration | B70 #0 | B70 #1 | 256-token decode |
|---|---:|---:|---:|
| `ngl=999` | ~30.14 GiB | ~29.81 GiB | ~21.61 tok/s |
| `ngl=40` | ~23.03 GiB | ~23.92 GiB | 15.65 tok/s |
| `ngl=44` | ~25.10 GiB | ~26.14 GiB | 18.52 tok/s |
| `ngl=46` | ~26.38 GiB | ~27.16 GiB | 19.77 tok/s |
| `ngl=47` | ~27.61 GiB | ~27.16 GiB | 20.65 tok/s |

Longer `ngl=47` runs subsequently stabilized around 21-22 tok/s, showing that the short 256-token test slightly understated steady-state performance.

## Conclusion

`ngl=47` is the recommended configuration. It gives back roughly 2.5-3 GiB of VRAM headroom per B70 versus the original all-GPU build while preserving nearly all sustained decode performance.

For comparison work, use at least 512 generated tokens. Very short outputs are too noisy to characterize sustained Flash-Next decode on this platform.