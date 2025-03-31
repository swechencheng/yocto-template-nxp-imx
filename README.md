# yocto-template-nxp-imx
A sample template of using the minimal BSP layers needed to build Yocto on NXP i.MX targets

## Layer Dependencies

| Submodule | Branch | Version |
| --- | --- | --- |
| openembedded-core | scarthgap | yocto-5.0.8 |
| bitbake | 2.8 | yocto-5.0.8 (2.8.8) |
| meta-openembedded | scarthgap | edd1a1e284fdcb80cd48d411f235d47f23bc27ae |
| meta-yocto | scarthgap | afa9ec665d1197d9289a86d30389be0cc037d739 |
| meta-arm | scarthgap | 3cadb81ffaa9f03b92e302843cb22a9cd41df34b |
| meta-freescale | scarthgap | 6ac20415b9663fbb82a3e89a3b574efdc6ea920c |
| meta-freescale-3rdparty | scarthgap | 1dfc65dd2006b51d156be5bcda0e3c72c936ad0a |
| meta-freescale-distro | scarthgap | b9d6a5d9931922558046d230c1f5f4ef6ee72345 |
| meta-imx | scarthgap-6.6.52-2.2.0 | rel_imx_6.6.52_2.2.0 |

**i.MX layer source:**
https://github.com/nxp-imx/imx-manifest/blob/imx-linux-scarthgap/imx-6.6.52-2.2.0.xml

These submodules use the version from `imx-6.6.52-2.2.0.xml`:
- meta-freescale-distro
- meta-imx

## Quick Start

### Setup up your build environment (once)

To ensure a well controlled build environment which is reproductive, we use a docker image built by [this](./Dockerfile).

Build your docker image by running:
```bash
docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t yocto-5.0 .
```
This will build a Docker image named `yocto-5.0`.

### Spin up your build environment everytime when you need to run Yocto build

With your docker image `yocto-5.0` ready, run:
```bash
docker run --rm -it -u $(id -u):$(id -g) -v $(pwd):$(pwd) yocto-5.0
```

A Docker container will give you a clean environment for performing Yocto build.
The repo root dir will be bind mounted into the container with `-v $(pwd):$(pwd)` option.

### Kick-off the build

In your Docker container, go to repo root dir, and run:
```bash
./build.sh
```

## Things behind the `build.sh`

This is created as a wrapper for people to easily kick off bitbake with an opinionized trim of dependencies.

The following meta policies are picked as a sample in [`build.sh`](./build.sh):

```
DISTRO=fsl-wayland
TEMPLATE_LAYER=openembedded-core/meta
TEMPLATE=default
MACHINE=imx6ulevk
IMAGE=core-image-minimal
INITRAMFS_IMAGE=fsl-image-mfgtool-initramfs
```

You can adjust them to adapt to your own favour.

## Further work

### Use custom minimal distro

If you want to further minimize the meta layer dependencies, you can create your own distro instead of using distros from FSL/FSLC which are based on poky distro.

Then you can get rid of the following layers:
- meta-yocto
- meta-freescale-distro

However, this will require you to create your own custom meta layer, which most vendors do.
