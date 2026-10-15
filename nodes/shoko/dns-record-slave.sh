#!/bin/bash
set -euo pipefail
test -f /root/configs/named.conf.local || { echo 'Jalankan dns-slave.sh dahulu'; exit 1; }
if ! grep -q 'zone "1.230.192.in-addr.arpa"' /root/configs/named.conf.local; then
cat >> /root/configs/named.conf.local <<'CONF'
zone "1.230.192.in-addr.arpa" {
    type slave;
    masters { 192.230.1.2; };
    file "/var/cache/bind/db.reverse";
    allow-notify { 192.230.1.2; };
};
CONF
fi
cat > /etc/bind/named.conf.options <<'CONF'
options {
    directory "/var/cache/bind";
    listen-on { any; }; listen-on-v6 { none; };
    allow-query { 127.0.0.0/8; 192.230.0.0/16; };
    recursion yes;
    allow-recursion { 127.0.0.0/8; 192.230.0.0/16; };
    forwarders { 192.168.122.1; };
    forward only;
    dnssec-validation auto;
};
CONF
cp /etc/bind/named.conf.options /root/configs/named.conf.options
cp /root/configs/named.conf.local /etc/bind/named.conf.local
named-checkconf -z
service named restart
dig @127.0.0.1 -x 192.230.1.4 +short
