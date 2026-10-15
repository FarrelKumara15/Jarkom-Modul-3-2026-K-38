#!/bin/bash
set -euo pipefail
bash /root/setup-infrastruktur.sh shoko bind9 bind9-utils dnsutils
cat > /root/configs/named.conf.local <<'CONF'
zone "jujutsu.k38.com" {
    type slave;
    masters { 192.230.1.2; };
    file "/var/cache/bind/db.jujutsu";
    allow-notify { 192.230.1.2; };
};
CONF
cp /root/configs/named.conf.local /etc/bind/named.conf.local
install -d -o bind -g bind /var/cache/bind
named-checkconf
service named restart
dig @127.0.0.1 jujutsu.k38.com SOA +short
