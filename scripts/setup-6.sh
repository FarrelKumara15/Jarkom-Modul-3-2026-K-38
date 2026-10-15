#!/bin/bash

MAC_KUGISAKI="02:42:06:35:1a:00"

cat <<DHCPCONF >> /etc/dhcp/dhcpd.conf

# Static lease untuk kugisaki di luar pool dinamis Network 3
host kugisaki {
    hardware ethernet ${MAC_KUGISAKI};
    fixed-address 192.230.3.99;
}
DHCPCONF

dhcpd -t -cf /etc/dhcp/dhcpd.conf && service isc-dhcp-server restart