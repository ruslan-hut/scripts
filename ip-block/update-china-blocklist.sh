#!/bin/bash
# Update ipset "blocked" with China IP block list from ipdeny.com

set -euo pipefail

IPSET_NAME="blocked"
ZONE_URL="https://www.ipdeny.com/ipblocks/data/countries/cn.zone"
ZONE_FILE="/tmp/cn.zone"
ZONE_HASH="/var/lib/ipset/cn.zone.sha256"

mkdir -p /var/lib/ipset

# Download the zone file
if ! curl -sf -o "$ZONE_FILE" "$ZONE_URL"; then
    echo "Failed to download zone file" >&2
    exit 1
fi

# Check if the list has changed
if [ -f "$ZONE_HASH" ] && sha256sum -c "$ZONE_HASH" --status 2>/dev/null <<< "$(cat "$ZONE_HASH" | sed "s|[^ ]*$|$ZONE_FILE|")"; then
    echo "Block list unchanged, nothing to do"
    rm -f "$ZONE_FILE"
    exit 0
fi

echo "Block list changed, updating ipset..."

# Create ipset if it doesn't exist
if ! ipset list "$IPSET_NAME" &>/dev/null; then
    ipset create "$IPSET_NAME" hash:net maxelem 131072
fi

# Build a new temporary set, then swap
TMP_SET="${IPSET_NAME}_tmp"
ipset create "$TMP_SET" hash:net maxelem 131072 2>/dev/null || ipset flush "$TMP_SET"

count=0
while IFS= read -r cidr; do
    cidr="$(echo "$cidr" | tr -d '[:space:]')"
    [ -z "$cidr" ] && continue
    ipset add "$TMP_SET" "$cidr" 2>/dev/null || true
    count=$((count + 1))
done < "$ZONE_FILE"

# Atomic swap
ipset swap "$TMP_SET" "$IPSET_NAME"
ipset destroy "$TMP_SET"

echo "Loaded $count entries into ipset '$IPSET_NAME'"

# Ensure iptables rule exists
if ! iptables -C INPUT -m set --match-set "$IPSET_NAME" src -j DROP 2>/dev/null; then
    iptables -I INPUT 1 -m set --match-set "$IPSET_NAME" src -j DROP
    echo "Added iptables rule for ipset '$IPSET_NAME'"
fi

# Save hash for next run
sha256sum "$ZONE_FILE" > "$ZONE_HASH"

# Persist ipset across reboots
ipset save > /etc/ipset.rules 2>/dev/null || true

rm -f "$ZONE_FILE"
echo "Done"
