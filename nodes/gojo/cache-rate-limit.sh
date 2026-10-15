#!/bin/bash
set -euo pipefail
test -f /etc/nginx/sites-available/shibuya || { echo 'Jalankan reverse-proxy.sh dahulu'; exit 1; }
mkdir -p /root/configs /root/evidence /var/cache/nginx/frontend
chown www-data:www-data /var/cache/nginx/frontend
echo 'limit_req_dry_run off;' > /root/configs/rate-mode.conf
cat > /etc/nginx/conf.d/00-shibuya-globals.conf <<'NGINX'
proxy_cache_path /var/cache/nginx/frontend levels=1:2 keys_zone=frontend_cache:10m max_size=100m inactive=20m;
limit_req_zone $binary_remote_addr zone=api_per_ip:10m rate=10r/s;
log_format shibuya '$time_iso8601 client=$remote_addr request="$request" status=$status upstream=$upstream_addr upstream_status=$upstream_status cache=$upstream_cache_status limit=$limit_req_status rt=$request_time';
access_log /root/evidence/access.log shibuya;
error_log /root/evidence/error.log warn;
NGINX
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
    location = /api {
        limit_req zone=api_per_ip;
        limit_req_status 429;
        include /root/configs/rate-mode.conf;
        proxy_pass http://192.230.4.2;
    }
    location ^~ /api/ {
        limit_req zone=api_per_ip;
        limit_req_status 429;
        include /root/configs/rate-mode.conf;
        proxy_pass http://192.230.4.2;
    }
    location / {
        proxy_pass http://frontend_cluster;
        proxy_cache frontend_cache;
        proxy_cache_valid 200 10m;
        proxy_cache_key "$scheme$request_method$host$request_uri";
        proxy_cache_bypass $http_authorization $http_cookie;
        proxy_no_cache $http_authorization $http_cookie;
        add_header X-Cache-Status $upstream_cache_status always;
    }
}
NGINX
nginx -t
service nginx reload
