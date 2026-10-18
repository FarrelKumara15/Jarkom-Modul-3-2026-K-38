#!/bin/bash

cat <<INTERFACES > /etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 192.230.4.10
    netmask 255.255.255.0
    gateway 192.230.4.1
INTERFACES

ip link set eth0 up
ip addr flush dev eth0
ip addr add 192.230.4.10/24 dev eth0
ip route replace default via 192.230.4.1
echo "nameserver 192.168.122.1" > /etc/resolv.conf

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y isc-dhcp-server

# Atur interface DHCP server mengarah ke Network 4 (eth0)
sed -i 's/^INTERFACESv4=.*/INTERFACESv4="eth0"/' /etc/default/isc-dhcp-server

cat <<DHCPCONF > /etc/dhcp/dhcpd.conf
authoritative;
default-lease-time 600;
max-lease-time 7200;

option domain-name "K38.com";
option domain-search "K38.com";
option domain-name-servers 192.230.1.2, 192.230.1.3;

# Network 4 sebagai subnet lokal tanpa pool dinamis
subnet 192.230.4.0 netmask 255.255.255.0 {
}

# Scope dasar Network 2
subnet 192.230.2.0 netmask 255.255.255.0 {
    option routers 192.230.2.1;
}

# Scope dasar Network 3
subnet 192.230.3.0 netmask 255.255.255.0 {
    option routers 192.230.3.1;
}
DHCPCONF

service isc-dhcp-server restart