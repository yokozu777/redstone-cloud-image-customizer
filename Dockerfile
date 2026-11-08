FROM ubuntu:24.04

# CLOUD_IMAGE_URL — cloud disk to download (qcow2 or raw).
# PACKAGES — comma-separated package names for virt-customize --install.
# INSTALL_LOCAL_CERT=true installs certificates from ./certs into the disk trust store.
# REMOTE_CA_URL, when set, downloads a CA from that URL and installs it the same way.
ARG CLOUD_IMAGE_URL=https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img
ARG PACKAGES=qemu-guest-agent
ARG INSTALL_LOCAL_CERT=false
ARG REMOTE_CA_URL=

ENV CLOUD_IMAGE_URL=${CLOUD_IMAGE_URL} \
    PACKAGES=${PACKAGES} \
    INSTALL_LOCAL_CERT=${INSTALL_LOCAL_CERT} \
    REMOTE_CA_URL=${REMOTE_CA_URL} \
    LIBGUESTFS_BACKEND=direct \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      libguestfs-tools \
      qemu-system-x86 \
      linux-image-generic \
      isc-dhcp-client \
      wget \
      curl \
      ca-certificates \
    && chmod 644 /boot/vmlinuz-* \
    && rm -rf /var/lib/apt/lists/*

COPY certs/ /opt/certs/
COPY customize.sh /usr/local/bin/customize.sh
RUN chmod +x /usr/local/bin/customize.sh

VOLUME ["/output"]
ENTRYPOINT ["/usr/local/bin/customize.sh"]
