#!/bin/bash
set -euo pipefail
mkdir -p /root/evidence
: > /root/evidence/rasio-api.jsonl
for i in $(seq 1 40); do
 curl -fsS -H 'Host: jujutsu.k38.com' http://192.230.4.2/api >> /root/evidence/rasio-api.jsonl
done
for node in nanami todo kirara; do
 echo "$node: $(grep -c '"worker":"'"$node"'"' /root/evidence/rasio-api.jsonl || true)"
done
