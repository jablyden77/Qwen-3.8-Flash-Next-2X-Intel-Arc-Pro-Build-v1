# vLLM XPU research lane

The working reference in this repository is the SYCL/llama.cpp GGUF deployment. A separate vLLM XPU experiment was also tested on the same two B70 GPUs.

That experiment used a roughly 72 GiB W4A16 model body plus a separate roughly 48 GiB FP8 PLE table, with TP=2, expert parallelism, lazy safetensors loading and UVA offload.

The important finding was that model compatibility was not the problem. One TP rank could load successfully, but building the second rank created much higher peak host-memory pressure than the llama.cpp GGUF path on a 64 GB host.

The PLE table was already file-backed rather than copied eagerly into normal host memory. The larger difference was the transient memory behavior of the safetensors/TP worker initialization path.

Future vLLM work should focus on lowering peak TP2 initialization memory, preserving several GiB of VRAM margin per B70, validating MTP0 first, then adding XPU Graph and deeper MTP only after correctness is stable.

Until that path matches the memory efficiency and reliability of the llama.cpp build, `ngl=47` remains the known-good reference configuration.