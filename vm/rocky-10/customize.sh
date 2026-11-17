#!/bin/sh
# BrokeLabs base (D32): the distribution's cloud image plus the guest agent,
# NoCloud as the only cloud-init datasource, and no automatic updates.
set -eu

dnf install -y qemu-guest-agent
systemctl enable qemu-guest-agent
dnf remove -y dnf-automatic || true
systemctl disable dnf-makecache.timer || true

# Instances get their data from a NoCloud disk: no probing for other sources.
cat > /etc/cloud/cloud.cfg.d/90-brokelabs.cfg <<'CFG'
datasource_list: [NoCloud, None]
CFG

dnf clean all
cloud-init clean --logs
