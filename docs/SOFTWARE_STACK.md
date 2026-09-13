# Software stack

## Host OS

The validated host runs **Ubuntu 26.04** on x86-64.

A modern Linux kernel and current Intel compute stack are recommended because the Arc Pro B70 depends on recent i915/xe, Level Zero and oneAPI support.

## Container runtime

The working Flash-Next deployment uses Docker and the Intel build of llama.cpp:

```text
ghcr.io/ggml-org/llama.cpp:server-intel
```

This image supplies the SYCL-enabled llama.cpp server and Intel oneAPI runtime components needed by the container.

The image observed in the working deployment included Intel oneAPI-era components in the 2025.3 family, including compiler/runtime libraries, oneDNN, MKL and related SYCL dependencies, plus oneCCL/MPI components from the Intel stack.

Because container tags can move, pin an image digest for a long-lived reproducible deployment after validating a known-good build.

## GPU device exposure

The two Arc Pro B70s are passed into the container through DRM render nodes:

```bash
--device /dev/dri/renderD128:/dev/dri/renderD128
--device /dev/dri/renderD129:/dev/dri/renderD129
```

The container also needs the host group that owns the render nodes. The validated system used a numeric group id; do not hard-code that value blindly on another machine.

Find the correct host group with:

```bash
stat -c '%g %n' /dev/dri/renderD128 /dev/dri/renderD129
getent group render
```

Then pass the appropriate group with `--group-add`.

## SYCL setting

The validated container sets:

```bash
GGML_SYCL_FA_ONEDNN=0
```

This was part of the known-good Intel/SYCL configuration and is preserved in the launcher.

## GPU enumeration

Inside the Intel llama.cpp container, the cards are addressed as:

```text
SYCL0
SYCL1
```

The server is launched with:

```text
--device SYCL0,SYCL1
```

Use the container logs to confirm both devices are detected before trusting benchmark results.

## Useful verification commands

Host-side:

```bash
xpu-smi discovery
xpu-smi stats -d 0
xpu-smi stats -d 1
```

Docker:

```bash
docker ps
docker logs --tail 100 flashnext-m64-ngl47
```

API:

```bash
curl -s http://127.0.0.1:18126/health
```

A healthy server should report an OK status after model initialization finishes.

## Networking

The example launcher publishes the container only to loopback:

```text
127.0.0.1:18126 -> container port 8000
```

That is deliberate. If the service must be remotely reachable, place an authenticated reverse proxy or API gateway in front of it rather than binding the unauthenticated llama.cpp server directly to a LAN or WAN address.