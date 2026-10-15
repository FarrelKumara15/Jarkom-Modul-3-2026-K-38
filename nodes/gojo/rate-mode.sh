#!/bin/bash
set -euo pipefail
test -f /root/configs/rate-mode.conf || { echo 'Jalankan cache-rate-limit.sh dahulu'; exit 1; }
case "${1:-}" in
 baseline) echo 'limit_req_dry_run on;' > /root/configs/rate-mode.conf;;
 active) echo 'limit_req_dry_run off;' > /root/configs/rate-mode.conf;;
 *) echo 'Penggunaan: bash /root/rate-mode.sh baseline|active'; exit 1;;
esac
nginx -t
service nginx reload
