# Security

This tool downloads a disk image from `CLOUD_IMAGE_URL` and installs the packages named in `PACKAGES` into that disk. Both values are chosen by whoever builds or runs the container.

Only point `CLOUD_IMAGE_URL` at an image you trust. The download is whatever that URL returns, and it is written to `output/cloud.img`. `virt-customize` then runs that image's package manager, so package names are installed from the image's own repositories with network access.

Do not commit disk images. `*.img`, `*.qcow2`, and the `output/` directory are local build products and may contain anything that was on the cloud image plus the packages you added.

The container needs `--privileged` so libguestfs can start its helper VM. Do not run an untrusted image URL or an untrusted package list with that flag.

`certs/*.crt` are public CA certificates and are copied into the disk only when `INSTALL_LOCAL_CERT=true`. Do not commit the matching private key. `REMOTE_CA_URL` is fetched with TLS verification disabled (`curl -k`); prefer a file in `certs/` when you already have the CA.
