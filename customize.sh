#!/bin/bash
set -euo pipefail

: "${CLOUD_IMAGE_URL:?Set CLOUD_IMAGE_URL to a cloud image URL}"
: "${PACKAGES:?Set PACKAGES to a comma-separated package list}"

# libguestfs copies this file into its helper VM. Docker's resolver is
# not reachable from that VM.
umount /etc/resolv.conf 2>/dev/null || true
printf 'nameserver 8.8.8.8\nnameserver 1.1.1.1\n' > /etc/resolv.conf

mkdir -p /output /tmp/guest-certs
wget -O /output/cloud.img "$CLOUD_IMAGE_URL"

shopt -s nullglob
if [ "$INSTALL_LOCAL_CERT" = "true" ]; then
  local_certs=(/opt/certs/*.crt)
  if [ "${#local_certs[@]}" -eq 0 ]; then
    echo "INSTALL_LOCAL_CERT=true but /opt/certs has no .crt files" >&2
    exit 1
  fi
  cp "${local_certs[@]}" /tmp/guest-certs/
fi
if [ -n "$REMOTE_CA_URL" ]; then
  curl -fsSLk -o /tmp/guest-certs/remote-ca.crt "$REMOTE_CA_URL"
fi
chmod 644 /tmp/guest-certs/*.crt 2>/dev/null || true

# Ubuntu cloud images symlink resolv.conf at a path that does not exist
# until systemd-resolved starts. Replace it while apt runs, then restore it.
customize_args=(
  -a /output/cloud.img
  --network
  --run-command 'rm -f /etc/resolv.conf; printf "nameserver 8.8.8.8\nnameserver 1.1.1.1\n" > /etc/resolv.conf'
)
guest_certs=(/tmp/guest-certs/*.crt)
if [ "${#guest_certs[@]}" -gt 0 ]; then
  customize_args+=(--mkdir /usr/local/share/ca-certificates)
  for cert in "${guest_certs[@]}"; do
    customize_args+=(--upload "$cert:/usr/local/share/ca-certificates/$(basename "$cert")")
  done
  customize_args+=(--run-command 'chmod 644 /usr/local/share/ca-certificates/*.crt && update-ca-certificates')
fi
customize_args+=(
  --install "$PACKAGES"
  --run-command 'rm -f /etc/resolv.conf; ln -s ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf'
)
virt-customize "${customize_args[@]}"

echo "Wrote /output/cloud.img with packages: $PACKAGES"
