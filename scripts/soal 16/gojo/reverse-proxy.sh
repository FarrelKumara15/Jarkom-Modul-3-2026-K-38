#!/bin/bash
set -euo pipefail
bash /root/setup-infrastruktur.sh gojo nginx curl
mkdir -p /root/evidence
cat > /etc/nginx/sites-available/shibuya <<'NGINX'
upstream frontend_cluster {
    server 192.230.4.3:80;
    server 192.230.4.4:80;
}
server {
    listen 80 default_server;
    server_name jujutsu.k38.com www.jujutsu.k38.com;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $remote_addr;
    location = /api { proxy_pass http://192.230.4.2; }
    location ^~ /api/ { proxy_pass http://192.230.4.2; }
    location / { proxy_pass http://frontend_cluster; }
}
NGINX
rm -f /etc/nginx/sites-enabled/default
ln -sfn /etc/nginx/sites-available/shibuya /etc/nginx/sites-enabled/shibuya
nginx -t
service nginx restart
