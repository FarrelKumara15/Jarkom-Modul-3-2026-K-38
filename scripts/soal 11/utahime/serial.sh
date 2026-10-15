#!/bin/bash
set -euo pipefail
ZONE=/root/configs/db.jujutsu
test -f "$ZONE"
SERIAL=$(awk '/; serial/{print $1;exit}' "$ZONE")
[[ $SERIAL =~ ^[0-9]+$ ]]
NEXT=$((10#$SERIAL + 1))
sed -i "s/^ $SERIAL ; serial$/ $NEXT ; serial/" "$ZONE"
cp "$ZONE" /etc/bind/db.jujutsu
named-checkzone jujutsu.k38.com /etc/bind/db.jujutsu
rndc reload jujutsu.k38.com
rndc notify jujutsu.k38.com
echo "Serial baru: $NEXT"
