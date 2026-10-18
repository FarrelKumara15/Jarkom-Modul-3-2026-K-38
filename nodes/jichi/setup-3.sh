#!/bin/bash

TENGEN_IP="192.230.4.10"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y isc-dhcp-relay

cat <<RELAY > /etc/default/isc-dhcp-relay
SERVERS="${TENGEN_IP}"
INTERFACES="eth2 eth3 eth4"
OPTIONS=""
RELAY

service isc-dhcp-relay restart