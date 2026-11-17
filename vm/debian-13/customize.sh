#!/bin/sh
# BrokeLabs base (D32): the distribution's cloud image plus the guest agent,
# NoCloud as the only cloud-init datasource, and no automatic updates.
set -eu
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends qemu-guest-agent
apt-get purge -y unattended-upgrades || true
systemctl disable apt-daily.timer apt-daily-upgrade.timer || true

# Instances get their data from a NoCloud disk: no probing for other sources.
cat > /etc/cloud/cloud.cfg.d/90-brokelabs.cfg <<'CFG'
datasource_list: [NoCloud, None]
CFG

apt-get clean
rm -rf /var/lib/apt/lists/*
cloud-init clean --logs
