#!/bin/bash
set -euo pipefail
bash /root/setup-infrastruktur.sh utahime bind9 bind9-utils dnsutils
cat > /root/configs/named.conf.local <<'CONF'
zone "jujutsu.k38.com" {
    type master;
    file "/etc/bind/db.jujutsu";
    allow-transfer { 192.230.1.3; };
    also-notify { 192.230.1.3; };
    notify yes;
};
CONF
cat > /root/configs/db.jujutsu <<'ZONE'
$TTL 300
@ IN SOA utahime.jujutsu.k38.com. admin.jujutsu.k38.com. (
 2026101301 ; serial
 60 ; refresh
 30 ; retry
 604800 ; expire
 300 ) ; negative TTL
@ IN NS utahime.jujutsu.k38.com.
@ IN NS shoko.jujutsu.k38.com.
utahime IN A 192.230.1.2
shoko IN A 192.230.1.3
ZONE
cp /root/configs/named.conf.local /etc/bind/named.conf.local
cp /root/configs/db.jujutsu /etc/bind/db.jujutsu
named-checkconf -z
service named restart
dig @127.0.0.1 jujutsu.k38.com SOA +short
