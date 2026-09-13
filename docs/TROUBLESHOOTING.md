# Troubleshooting

## Model loads but performance is low

Confirm both B70s are active, both PCIe links are operating at the intended width and generation, and the container sees `SYCL0` and `SYCL1`. Use a 512-token or longer output when measuring sustained decode; very short requests are noisy.

## VRAM is higher than expected

Confirm `--n-gpu-layers 47`, `--split-mode layer`, and `--tensor-split 1,1`. The older all-GPU profile intentionally used close to 30 GiB per card.

## Host RAM appears full

Linux page cache is reclaimable. Check the `available` value from `free -h`, not only the `free` column. The validated llama.cpp profile kept more than 50 GiB available during long runs.

## Server is not healthy yet

Follow container logs until the model-loaded message appears and the server begins listening. Cold loading from slow storage can take much longer than NVMe.

## One GPU is missing

Check the DRM render nodes, their permissions, and the container device mappings. Verify both cards with `xpu-smi discovery` before starting the model.

## Throughput falls during long generation

A mild decline is normal as context grows. The 4096-token test averaged 21.02 tok/s and ended with short-window throughput around 20.4-20.6 tok/s. A much larger drop suggests a changed runtime, GPU throttling, PCIe issues, or storage pressure.

## Competing model service

Do not benchmark while another inference service is using the same B70s. Check running containers and local model services first.

## Known-good reference

If tuning becomes unstable, return to the checked-in `start-flashnext-ngl47.sh` profile before changing one variable at a time.