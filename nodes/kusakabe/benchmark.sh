#!/bin/sh
set -eu
MODE=${1:-}
case "$MODE" in baseline|active) ;; *) echo 'Penggunaan: sh /root/benchmark.sh baseline|active'; exit 1;; esac
command -v ab >/dev/null || { echo 'Instal apache2-utils: apk add --no-cache apache2-utils'; exit 1; }
mkdir -p /root/evidence
ab -n 600 -c 30 http://jujutsu.k38.com/ > "/root/evidence/$MODE-web.txt" 2>&1
ab -n 600 -c 30 http://jujutsu.k38.com/api > "/root/evidence/$MODE-api.txt" 2>&1
cat "/root/evidence/$MODE-web.txt" "/root/evidence/$MODE-api.txt"
