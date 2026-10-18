#!/bin/bash

cat <<INTERFACES > /etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet static
    address 192.230.1.1
    netmask 255.255.255.0

auto eth2
iface eth2 inet static
    address 192.230.2.1
    netmask 255.255.255.0

auto eth3
iface eth3 inet static
    address 192.230.3.1
    netmask 255.255.255.0

auto eth4
iface eth4 inet static
    address 192.230.4.1
    netmask 255.255.255.0
INTERFACES

ip link set eth0 up
dhclient eth0 2>/dev/null || udhcpc -i eth0 -n -q 2>/dev/null || true

for i in 1 2 3 4; do
  ip link set eth$i up
  ip addr replace 192.230.$i.1/24 dev eth$i
done

sysctl -w net.ipv4.ip_forward=1
grep -q '^net.ipv4.ip_forward=1' /etc/sysctl.conf || echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get install -y iptables iptables-persistent

iptables -t nat -C POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
netfilter-persistent save 2>/dev/null || true