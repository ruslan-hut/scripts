# China IP Block List Updater

Bash script for Ubuntu servers that downloads the China IP block list from [ipdeny.com](https://www.ipdeny.com/ipblocks/data/countries/cn.zone) and loads it into an `ipset` used by `iptables`.

## Prerequisites

```bash
apt install ipset curl
```

## Usage

Run as root:

```bash
sudo ./update-china-blocklist.sh
```

## How it works

1. Downloads `cn.zone` (CIDR list) from ipdeny.com
2. Compares SHA-256 hash against the previous run — skips if unchanged
3. Creates a temporary ipset, loads all CIDRs, then atomically swaps it with the `blocked` set (no gap in protection)
4. Adds the iptables rule if missing: `iptables -I INPUT 1 -m set --match-set blocked src -j DROP`
5. Persists the ipset to `/etc/ipset.rules`

## Resulting iptables rule

```
Chain INPUT (policy DROP)
target     prot opt source               destination
DROP       all  --  anywhere             anywhere             match-set blocked src
```

## Cron setup

To update daily at 3 AM:

```bash
sudo crontab -e
```

```
0 3 * * * /path/to/update-china-blocklist.sh >> /var/log/china-blocklist.log 2>&1
```

## Restore on reboot

Add to `/etc/rc.local` or a systemd unit:

```bash
ipset restore < /etc/ipset.rules
```

## Files

| Path | Purpose |
|---|---|
| `/var/lib/ipset/cn.zone.sha256` | Hash of the last downloaded list (change detection) |
| `/etc/ipset.rules` | Persisted ipset data for restore after reboot |
