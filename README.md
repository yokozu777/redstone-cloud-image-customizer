# Cloud image customizer

Download a cloud disk image and install packages into it. Two variables at the top of the `Dockerfile` choose the image URL and the package list. The container writes the finished disk to `output/cloud.img`.

The default image is Ubuntu 24.04 and the default package is `qemu-guest-agent`.

## Variables

Set them in the `Dockerfile`, or override them at build time with `--build-arg` and at run time with `-e`.

| Variable | Default | Meaning |
| --- | --- | --- |
| `CLOUD_IMAGE_URL` | Ubuntu 24.04 cloud image | `qcow2` or raw disk to download |
| `PACKAGES` | `qemu-guest-agent` | Comma-separated package names, for example `qemu-guest-agent,curl` |
| `INSTALL_LOCAL_CERT` | `false` | `true` copies `certs/*.crt` into the disk trust store |
| `REMOTE_CA_URL` | empty | Download a CA and install it the same way. Example: `https://ca.example:8443/roots.pem` |

## Build and run

```bash
docker build -t cloud-image-customizer .

docker run --rm --privileged --device /dev/kvm \
  -v "$PWD/output:/output" \
  cloud-image-customizer
```

Without `/dev/kvm` the helper VM used by `virt-customize` falls back to emulation and the run takes much longer. Drop `--device /dev/kvm` only when the device is not there.

Override the defaults without editing the file:

```bash
docker run --rm --privileged --device /dev/kvm \
  -e CLOUD_IMAGE_URL=https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img \
  -e PACKAGES=qemu-guest-agent,curl \
  -v "$PWD/output:/output" \
  cloud-image-customizer
```

The result is `output/cloud.img`. That file is a local disk image and is not part of this repository. The Ubuntu cloud image stays under Ubuntu's license.

## Certificates

Put public CA files named `*.crt` in `certs/` and set `INSTALL_LOCAL_CERT=true`. The container copies them to `/usr/local/share/ca-certificates` on the disk and runs `update-ca-certificates`. `false` does not install anything from that directory.

`REMOTE_CA_URL` is independent. A non-empty URL is downloaded with TLS verification skipped, because that server may be presenting the certificate being installed, and saved on the disk as `remote-ca.crt`.

```bash
docker build --build-arg INSTALL_LOCAL_CERT=true -t cloud-image-customizer .

docker run --rm --privileged --device /dev/kvm \
  -e REMOTE_CA_URL=https://ca.example:8443/roots.pem \
  -v "$PWD/output:/output" \
  cloud-image-customizer
```

## Check a package

```bash
docker run --rm --privileged --device /dev/kvm --entrypoint virt-customize \
  -v "$PWD/output:/output" \
  cloud-image-customizer \
  -a /output/cloud.img --run-command 'dpkg -s qemu-guest-agent'
```
