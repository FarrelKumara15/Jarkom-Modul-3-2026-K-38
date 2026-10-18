#!/bin/bash

MAC_INO="02:42:eb:98:67:00"
MAC_KUSAKABE="02:42:ce:17:22:00"
MAC_MIWA="02:42:61:27:3d:00"

cat <<DHCPCONF >> /etc/dhcp/dhcpd.conf

class "short-lease-clients" {
    match if (substring(hardware, 1, 6) = ${MAC_INO}) or (substring(hardware, 1, 6) = ${MAC_KUSAKABE});
}

class "long-lease-clients" {
    match if (substring(hardware, 1, 6) = ${MAC_MIWA});
}

subnet 192.230.3.0 netmask 255.255.255.0 {
    option routers 192.230.3.1;
    option domain-name-servers 192.230.1.2, 192.230.1.3;
    option domain-search "K38.com";

    # Short Lease (30 menit / 1800 detik)
    pool {
        allow members of "short-lease-clients";
        range 192.230.3.10 192.230.3.89;
        default-lease-time 1800;
        max-lease-time 1800;
    }

    # Long Lease (12 jam / 43200 detik)
    pool {
        allow members of "long-lease-clients";
        range 192.230.3.100 192.230.3.199;
        default-lease-time 43200;
        max-lease-time 43200;
    }
}
DHCPCONF

dhcpd -t -cf /etc/dhcp/dhcpd.conf && service isc-dhcp-server restart