#!/bin/bash
set -euo pipefail
NODE=${1:?Penggunaan: bash /root/setup-worker.sh maki|panda|nanami|todo|kirara}
case "$NODE" in
 maki|panda) ROLE=web; ALLOW=192.230.1.4;;
 nanami|todo|kirara) ROLE=api; ALLOW=192.230.4.2;;
 *) echo "Worker tidak dikenal: $NODE" >&2; exit 1;;
esac
bash /root/setup-infrastruktur.sh "$NODE" nginx php-fpm php-mysql curl
PHPVER=$(find /etc/php -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -V | tail -n 1)
[ -f "/etc/php/$PHPVER/fpm/pool.d/www.conf" ] || { echo 'Konfigurasi PHP-FPM tidak ditemukan'; exit 1; }
sed -i 's@^listen = .*@listen = 127.0.0.1:9000@' "/etc/php/$PHPVER/fpm/pool.d/www.conf"
mkdir -p /root/www /run/php
chmod 755 /root /root/www
cat > /etc/nginx/sites-available/shibuya <<NGINX
server {
 listen 80 default_server;
 server_name jujutsu.k38.com www.jujutsu.k38.com;
 root /root/www;
 index index.php;
 allow $ALLOW;
 deny all;
 location / {
  include /etc/nginx/fastcgi_params;
  fastcgi_param SCRIPT_FILENAME /root/www/index.php;
  fastcgi_pass 127.0.0.1:9000;
 }
}
NGINX
rm -f /etc/nginx/sites-enabled/default
ln -sfn /etc/nginx/sites-available/shibuya /etc/nginx/sites-enabled/shibuya
if [ "$ROLE" = web ]; then
cat > /root/www/index.php <<'PHP'
<?php
header('Content-Type: text/html; charset=utf-8');
$name = htmlspecialchars(gethostname(), ENT_QUOTES, 'UTF-8');
echo '<!doctype html><html><head><title>Jujutsu K38</title></head><body><h1>Frontend '.$name.'</h1></body></html>';
PHP
else
cat > /root/www/index.php <<'PHP'
<?php
header('Content-Type: application/json; charset=utf-8');
if (($_SERVER['REMOTE_ADDR'] ?? '') !== '192.230.4.2') {
    http_response_code(403);
    echo json_encode(['error' => 'untrusted proxy']);
    exit;
}
$ip = $_SERVER['HTTP_X_REAL_IP'] ?? '';
if (!filter_var($ip, FILTER_VALIDATE_IP)) {
    http_response_code(400);
    echo json_encode(['error' => 'invalid client IP']);
    exit;
}
try {
    $pdo = new PDO('mysql:host=192.230.4.8;dbname=db_shibuya_K38;charset=utf8mb4',
        'app', 'K38_App_Lab_2026', [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
    $q = $pdo->prepare('INSERT INTO request_logs(worker,client_ip,method,path) VALUES (?,?,?,?)');
    $q->execute([gethostname(), $ip, $_SERVER['REQUEST_METHOD'], $_SERVER['REQUEST_URI']]);
    echo json_encode(['worker' => gethostname(), 'client_ip' => $ip, 'log_id' => $pdo->lastInsertId()])."\n";
} catch (Throwable $e) {
    error_log($e->getMessage());
    http_response_code(503);
    echo json_encode(['error' => 'database unavailable']);
}
PHP
fi
chmod 644 /root/www/index.php
php -l /root/www/index.php
service "php$PHPVER-fpm" restart
nginx -t
service nginx restart
echo "Worker $NODE ($ROLE) siap"
