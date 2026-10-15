#!/bin/bash
set -euo pipefail
bash /root/setup-infrastruktur.sh yaga mariadb-server mariadb-client
service mariadb stop || true
cat > /etc/mysql/mariadb.conf.d/99-shibuya.cnf <<'CNF'
[mysqld]
server-id=1
bind-address=0.0.0.0
datadir=/root/mysql
log-bin=/root/mysql/mysql-bin
binlog-format=ROW
CNF
chmod 755 /root
install -d -o mysql -g mysql /root/mysql /run/mysqld
if [ ! -d /root/mysql/mysql ]; then mariadb-install-db --user=mysql --datadir=/root/mysql; fi
chown -R mysql:mysql /root/mysql
service mariadb start
mariadb-admin ping
mariadb <<'SQL'
CREATE DATABASE IF NOT EXISTS db_shibuya_K38;
USE db_shibuya_K38;
CREATE TABLE IF NOT EXISTS request_logs (
 id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 worker VARCHAR(64) NOT NULL,
 client_ip VARCHAR(45) NOT NULL,
 method VARCHAR(16) NOT NULL,
 path VARCHAR(2048) NOT NULL
) ENGINE=InnoDB;
CREATE USER IF NOT EXISTS 'app'@'192.230.4.%' IDENTIFIED BY 'K38_App_Lab_2026';
GRANT SELECT, INSERT ON db_shibuya_K38.* TO 'app'@'192.230.4.%';
CREATE USER IF NOT EXISTS 'repl'@'192.230.4.9' IDENTIFIED BY 'K38_Repl_Lab_2026';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'192.230.4.9';
CREATE USER IF NOT EXISTS 'seed'@'192.230.4.9' IDENTIFIED BY 'K38_Seed_Lab_2026';
GRANT SELECT, RELOAD, SHOW VIEW, TRIGGER, EVENT, REPLICATION CLIENT ON *.* TO 'seed'@'192.230.4.9';
FLUSH PRIVILEGES;
SHOW MASTER STATUS;
SQL
