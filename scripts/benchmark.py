#!/usr/bin/env python3
import argparse
import json
import time
import urllib.request

parser = argparse.ArgumentParser(description="Single-stream benchmark for the local Flash-Next llama.cpp server")
parser.add_argument("--url", default="http://127.0.0.1:18126/v1/chat/completions")
parser.add_argument("--model", default="local-flash-next")
parser.add_argument("--tokens", default="128,256,512,1024,2048,4096")
args = parser.parse_args()

lengths = [int(x) for x in args.tokens.split(",") if x.strip()]

for max_tokens in lengths:
    payload = {
        "model": args.model,
        "messages": [
            {"role": "user", "content": "Explain why deterministic network troubleshooting benefits from clear hypotheses and measured validation."}
        ],
        "max_tokens": max_tokens,
        "temperature": 0.2,
        "stream": False,
    }
    data = json.dumps(payload).encode()
    req = urllib.request.Request(args.url, data=data, headers={"Content-Type": "application/json"})
    start = time.perf_counter()
    with urllib.request.urlopen(req) as response:
        body = json.loads(response.read())
    elapsed = time.perf_counter() - start
    usage = body.get("usage", {})
    completion = usage.get("completion_tokens", max_tokens)
    print(json.dumps({
        "requested_tokens": max_tokens,
        "completion_tokens": completion,
        "elapsed_seconds": round(elapsed, 2),
        "client_observed_tokens_per_second": round(completion / elapsed, 2) if elapsed else None,
        "finish_reason": body.get("choices", [{}])[0].get("finish_reason"),
    }))
