# Tuning notes

## Goal

The tuning objective was not maximum VRAM occupancy. It was to preserve the working Flash-Next decode rate while creating enough VRAM margin for a stable 32K-context deployment on two 32-GiB B70s.

## GPU-layer sweep

The original working profile used effectively all available GPU layers and occupied about 30.1 / 29.8 GiB VRAM. A controlled layer sweep produced:

| GPU layers | GPU 0 VRAM | GPU 1 VRAM | 256-token decode |
|---:|---:|---:|---:|
| 999 | ~30.14 GiB | ~29.81 GiB | ~21.61 tok/s |
| 40 | ~23.03 GiB | ~23.92 GiB | 15.65 tok/s |
| 44 | ~25.10 GiB | ~26.14 GiB | 18.52 tok/s |
| 46 | ~26.38 GiB | ~27.16 GiB | 19.77 tok/s |
| 47 | ~27.61 GiB | ~27.16 GiB | 20.65 tok/s |

Longer tests later showed the `ngl=47` configuration sustaining about 21-22 tok/s, effectively matching the all-GPU profile once startup and short-request noise were removed.

## Why 47 layers is the baseline

`ngl=40` recovered a large amount of VRAM but lost too much decode performance. `ngl=44` was better but still gave away several tokens per second. `ngl=46` was close. `ngl=47` crossed the useful threshold: substantially more VRAM headroom than the all-GPU layout while keeping nearly all sustained decode performance.

## Context

The validated server is configured for 32,768 tokens. The long-output benchmarks in this repository primarily test decode stability as the generated context grows. A separate prompt-depth ladder should be used when characterizing very large input contexts.

## Batch settings

The known-good profile uses:

```text
--batch-size 2048
--ubatch-size 2048
```

These settings are part of the reproducible baseline. Change one variable at a time when tuning because batch changes can affect both prefill and memory behavior.

## Split mode

The final configuration uses layer split with an equal tensor ratio:

```text
--split-mode layer
--tensor-split 1,1
```

This is the tested dual-card arrangement. Do not assume another split mode will preserve the same memory use or throughput.

## Flash attention

The tested profile uses `--flash-attn auto` together with `GGML_SYCL_FA_ONEDNN=0` in the container environment.

## Practical tuning rule

Do not optimize this build by simply filling every last MiB of B70 VRAM. The all-GPU profile already proved that approach works, but the `ngl=47` result demonstrates that a modest amount of host-backed placement can recover useful GPU headroom for almost no sustained decode cost.