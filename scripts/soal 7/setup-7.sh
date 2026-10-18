#!/bin/bash

echo "--- Cek Status DHCP Server ---"
service isc-dhcp-server status

echo "--- Cek IP & Mask ---"
ip -br a show eth0

echo "--- Cek Gateway ---"
ip route

echo "--- Cek DNS & Domain ---"
cat /etc/resolv.conf

echo "--- Cek Database Leases Terbaru ---"
tail -n 15 /var/lib/dhcp/dhcpd.leases