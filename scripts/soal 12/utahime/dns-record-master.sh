#!/bin/bash
set -euo pipefail
test -f /root/configs/db.jujutsu || { echo 'Jalankan dns-master.sh dahulu'; exit 1; }
if ! grep -q '^@ IN A 192.230.1.4$' /root/configs/db.jujutsu; then
cat >> /root/configs/db.jujutsu <<'ZONE'
@ IN A 192.230.1.4
www IN CNAME jujutsu.k38.com.
gojo IN A 192.230.1.4
ZONE
fi
cat > /root/configs/db.reverse <<'ZONE'
$TTL 300
@ IN SOA utahime.jujutsu.k38.com. admin.jujutsu.k38.com. (
 2026101301 ; serial
 60 ; refresh
 30 ; retry
 604800 ; expire
 300 )
@ IN NS utahime.jujutsu.k38.com.
@ IN NS shoko.jujutsu.k38.com.
4 IN PTR jujutsu.k38.com.
ZONE
if ! grep -q 'zone "1.230.192.in-addr.arpa"' /root/configs/named.conf.local; then
cat >> /root/configs/named.conf.local <<'CONF'
zone "1.230.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.reverse";
    allow-transfer { 192.230.1.3; };
    also-notify { 192.230.1.3; };
    notify yes;
};
CONF
fi
SERIAL=$(awk '/; serial/{print $1;exit}' /root/configs/db.jujutsu)
NEXT=$((10#$SERIAL + 1))
sed -i "s/^ $SERIAL ; serial$/ $NEXT ; serial/" /root/configs/db.jujutsu
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
cp /root/configs/db.reverse /etc/bind/db.reverse
cp /root/configs/db.jujutsu /etc/bind/db.jujutsu
named-checkconf -z
service named restart
dig @127.0.0.1 jujutsu.k38.com A +short
