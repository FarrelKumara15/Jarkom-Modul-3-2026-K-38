#!/bin/bash

MAC_ITADORI="02:42:de:08:46:00"
MAC_FUSHIGURO="02:42:83:bb:88:00"
MAC_ZENIN="02:42:f2:c3:5f:00"
MAC_OKKOTSU="02:42:c7:86:f0:00"

cat <<'EOF' > /etc/dhcp/dhcpd.conf
authoritative;
default-lease-time 600;
max-lease-time 7200;
option domain-name "K38.com";
option domain-search "K38.com";
option domain-name-servers 192.230.1.2, 192.230.1.3;

# Kelas untuk Pool 1 (Itadori & Fushiguro)
class "pool-1-clients" {
    match if (substring(hardware, 1, 6) = 02:42:de:08:46:00) or (substring(hardware, 1, 6) = 02:42:83:bb:88:00);
}

# Subnet Network 4 (Lokal Tengen)
subnet 192.230.4.0 netmask 255.255.255.0 {
}

# Subnet Network 2 dengan Dual Pool
subnet 192.230.2.0 netmask 255.255.255.0 {
    option routers 192.230.2.1;
    option broadcast-address 192.230.2.255;

    # Pool 1 untuk Itadori & Fushiguro
    pool {
        allow members of "pool-1-clients";
        range 192.230.2.10 192.230.2.35;
    }

    # Pool 2 untuk Zenin & Okkotsu (selain Pool 1)
    pool {
        deny members of "pool-1-clients";
        range 192.230.2.70 192.230.2.95;
    }
}

# Subnet Network 3 (Dasar)
subnet 192.230.3.0 netmask 255.255.255.0 {
    option routers 192.230.3.1;
}
EOF

# Validasi dan Restart DHCP Server
dhcpd -t -cf /etc/dhcp/dhcpd.conf && service isc-dhcp-server restart