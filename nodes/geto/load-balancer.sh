#!/bin/bash
set -euo pipefail
bash /root/setup-infrastruktur.sh geto nginx curl
mkdir -p /root/evidence
cat > /etc/nginx/sites-available/shibuya <<'NGINX'
upstream api_cluster {
    server 192.230.4.5:80 weight=3;
    server 192.230.4.6:80 weight=1;
}
server {
    listen 80 default_server;
    server_name jujutsu.k38.com www.jujutsu.k38.com;
    location / {
        proxy_pass http://api_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_connect_timeout 1s;
        proxy_read_timeout 5s;
    }
}
NGINX
rm -f /etc/nginx/sites-enabled/default
ln -sfn /etc/nginx/sites-available/shibuya /etc/nginx/sites-enabled/shibuya
nginx -t
service nginx restart
