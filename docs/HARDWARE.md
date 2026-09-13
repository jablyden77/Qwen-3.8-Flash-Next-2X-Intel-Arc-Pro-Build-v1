# Hardware

## Validated host

The working system is an AM5 workstation built around:

- CPU: **AMD Ryzen 9 9900X**
- Motherboard: **GIGABYTE B850 AI TOP** class platform
- System memory: **64 GB DDR5**
- GPUs: **2x Intel Arc Pro B70**, 32 GiB VRAM each
- Aggregate VRAM: **64 GiB**
- GPU link width: each card negotiated at **PCIe 5.0 x8**
- Storage: NVMe storage for the model and container/runtime data is strongly preferred
- Power and cooling: size PSU and chassis airflow for two workstation GPUs running sustained inference loads

The exact chassis, PSU brand, fans and NVMe brand are not material to the inference recipe as long as both GPUs remain electrically stable and thermally unconstrained.

## PCIe topology

The important topology requirement is that both B70s operate at high-bandwidth PCIe links. The validated host ran both cards at PCIe Gen5 x8.

Verify with tools available on your distribution, for example:

```bash
lspci -vv | grep -A20 -Ei 'VGA|Display'
```

and Intel tooling:

```bash
xpu-smi discovery
xpu-smi stats -d 0
xpu-smi stats -d 1
```

Do not assume the BIOS `Auto` setting negotiated the intended link generation. During bring-up, explicitly setting the relevant PEG/PCIe slots to **Gen5** avoided ambiguity.

## BIOS notes

The following settings were relevant during the validated dual-card bring-up:

- PCIe generation for both GPU slots: **Gen5**
- Above 4G Decoding: enabled when required by the platform
- Resizable BAR / Smart Access Memory equivalent: enabled when supported
- Memory profile: EXPO/XMP as appropriate for the installed DIMMs
- High Bandwidth Memory support: enabled/tested on the board when available
- IOMMU: leave enabled unless a specific driver/container issue requires otherwise
- CSM: disabled for a modern UEFI-only Linux installation

The inference recipe does not require overclocking. Stability is more important than marginal CPU or RAM frequency gains.

## Memory constraint

This build intentionally assumes **64 GB host RAM**. Linux exposes roughly 59 GiB usable after firmware/kernel reservations on the validated system.

That constraint is important because it rules out brute-force strategies that keep a very large PLE table plus many gigabytes of CPU-offloaded model weights fully resident at the same time.

The working llama.cpp/GGUF path avoids that problem by relying heavily on mmap and page cache. The process RSS stays far below the total GGUF size.

## VRAM target

The final `ngl=47` profile runs at approximately:

- GPU 0: **27.6 GiB used**
- GPU 1: **27.2 GiB used**

This leaves several GiB of useful margin per card compared with the original all-GPU profile, which sat around 30.1 / 29.8 GiB.

The intent is not to maximize VRAM occupancy. The intent is to keep enough headroom for stable runtime behavior without materially sacrificing decode speed.