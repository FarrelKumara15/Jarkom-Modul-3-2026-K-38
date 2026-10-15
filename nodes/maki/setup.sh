#!/bin/bash
set -euo pipefail
NODE=${1:?Penggunaan: bash /root/setup-infrastruktur.sh NAMA_NODE [paket...]}
shift
case "$NODE" in
 utahime) IP=192.230.1.2;; shoko) IP=192.230.1.3;; gojo) IP=192.230.1.4;;
 geto) IP=192.230.4.2;; maki) IP=192.230.4.3;; panda) IP=192.230.4.4;;
 nanami) IP=192.230.4.5;; todo) IP=192.230.4.6;; kirara) IP=192.230.4.7;;
 yaga) IP=192.230.4.8;; inumaki) IP=192.230.4.9;;
 *) echo "Node tidak dikenal: $NODE" >&2; exit 1;;
esac
GATEWAY=${IP%.*}.1
hostname "$NODE"
mkdir -p /root/configs /root/evidence
chmod 755 /root /root/configs
cat > /etc/network/interfaces <<NET
auto lo
iface lo inet loopback
auto eth0
iface eth0 inet static
    address $IP
    netmask 255.255.255.0
    gateway $GATEWAY
NET
ip link set eth0 up
ip -4 addr flush dev eth0 scope global
ip addr add "$IP/24" dev eth0
ip route replace default via "$GATEWAY"
printf 'nameserver 192.168.122.1\n' > /etc/resolv.conf
if ((${#@})); then
 export DEBIAN_FRONTEND=noninteractive
 apt-get update -o APT::Update::Error-Mode=any
 apt-get install -y "$@"
fi
ip -br address show eth0
ip route
