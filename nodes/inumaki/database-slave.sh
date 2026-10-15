#!/bin/bash
set -euo pipefail
bash /root/setup-infrastruktur.sh inumaki mariadb-server mariadb-client
service mariadb stop || true
cat > /etc/mysql/mariadb.conf.d/99-shibuya.cnf <<'CNF'
[mysqld]
server-id=2
bind-address=0.0.0.0
datadir=/root/mysql
relay-log=/root/mysql/relay-bin
read-only=1
CNF
chmod 755 /root
install -d -o mysql -g mysql /root/mysql /run/mysqld
if [ ! -d /root/mysql/mysql ]; then mariadb-install-db --user=mysql --datadir=/root/mysql; fi
chown -R mysql:mysql /root/mysql
service mariadb start
mariadb-admin ping
if [ -e /root/replica-seeded ]; then
 echo 'Replika pernah diinisialisasi. Periksa SHOW SLAVE STATUS; tidak menimpa data.'
 mariadb -e 'SHOW SLAVE STATUS\G'
 exit 0
fi
cat > /root/seed-client.cnf <<'CNF'
[client]
host=192.230.4.8
user=seed
password=K38_Seed_Lab_2026
CNF
chmod 600 /root/seed-client.cnf
trap 'rm -f /root/seed-client.cnf' EXIT
mariadb-dump --defaults-extra-file=/root/seed-client.cnf --single-transaction --master-data=2 --databases db_shibuya_K38 > /root/seed.sql
COORD=$(sed -n 's/^-- CHANGE MASTER TO \(.*\);$/\1/p' /root/seed.sql | head -n 1)
[ -n "$COORD" ] || { echo 'Koordinat binary log tidak ditemukan pada dump'; exit 1; }
mariadb -e 'STOP SLAVE;' || true
mariadb < /root/seed.sql
mariadb <<SQL
CHANGE MASTER TO MASTER_HOST='192.230.4.8', MASTER_USER='repl', MASTER_PASSWORD='K38_Repl_Lab_2026', MASTER_USE_GTID=no, $COORD;
START SLAVE;
SHOW SLAVE STATUS\G
SQL
mariadb <<'SQL'
CREATE USER IF NOT EXISTS 'app'@'192.230.4.%' IDENTIFIED BY 'K38_App_Lab_2026';
GRANT SELECT ON db_shibuya_K38.* TO 'app'@'192.230.4.%';
FLUSH PRIVILEGES;
SQL
touch /root/replica-seeded
