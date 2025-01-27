# yocto-template-nxp-imx
A sample template of using the minimal BSP layers needed to build Yocto on NXP i.MX targets

## Layer Dependencies

| Submodule | Branch | Version |
| --- | --- | --- |
| openembedded-core | scarthgap | yocto-5.0.6 |
| bitbake | 2.8 | yocto-5.0.6 (2.8.6) |
| meta-openembedded | scarthgap | 2e3126c9c16bb3df0560f6b3896d01539a3bfad7 |
| meta-yocto | scarthgap | bd166d1fb8dc1bed7e71bd06b970a3da9149203e |
| meta-arm | scarthgap | 1b85bbb4cab9658da3cd926c62038b8559c5c64e |
| meta-freescale | scarthgap | 0f8091c63dd8805610c09b08409bc58492a3b16f |
| meta-freescale-3rdparty | scarthgap |  6c063450d464eb2f380443c7d9af1b94ce9b9d75 |
| meta-freescale-distro | scarthgap | b9d6a5d9931922558046d230c1f5f4ef6ee72345 |
| meta-imx | scarthgap-6.6.36-2.1.0 | rel_imx_6.6.36_2.1.0 |

**i.MX layer source:**
https://github.com/nxp-imx/imx-manifest/blob/imx-linux-scarthgap/imx-6.6.36-2.1.0.xml

These submodules use the version from `imx-6.6.36-2.1.0.xml`:
- meta-arm
- meta-freescale
- meta-freescale-3rdparty
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

## Known issue

### meta-imx cryptodev-linux conflicts with openembedded-core

You will encounter this error if you don't provide `-B` option when you run `build.sh`.
```
ERROR: No recipes in default available for:
  yocto-template-nxp-imx/sources/meta-imx/meta-imx-bsp/recipes-kernel/cryptodev/cryptodev-linux_1.13.bbappend
```

Using `-B` option will blacklist `cryptodev-linux_1.13.bbappend` from `meta-imx`.

### meta-imx firmware-imx recipe conflicts with meta-freescale

You will encounter this error if you run `./build.sh -B firmware-imx`:

```
ERROR: firmware-imx-1_8.25-r0 do_populate_lic: QA Issue: firmware-imx: The LIC_FILES_CHKSUM does not match for file://yocto-template-nxp-imx/sources/meta-freescale/EULA;md5=ca53281cc0caa7e320d4945a896fb837
firmware-imx: The new md5 checksum is 10c0fda810c63b052409b15a5445671a
firmware-imx: Here is the selected license text:
vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
LA_OPT_NXP_Software_License v56 April 2024
IMPORTANT.  Read the following NXP Software License Agreement ("Agreement")
completely. By selecting the "I Accept" button at the end of this page, or by
downloading, installing, or using the Licensed Software, you indicate that you
accept the terms of the Agreement, and you acknowledge that you have the
authority, for yourself or on behalf of your company, to bind your company to
these terms. You may then download or install the file. In the event of a
conflict between the terms of this Agreement and any license terms and
conditions for NXP’s proprietary software embedded anywhere in the Licensed
Software file, the terms of this Agreement shall control.  If a separate
...

TES Electronic Solutions Germany (TES):  TES 3D Surround View software and
associated data and documentation may only be used for evaluation purposes and
for demonstration to third parties in integrated form on a board package
containing an NXP S32V234 device. Licensee may not distribute or sublicense the
TES software. Your license to the TES software may be terminated at any time
upon notice.

Vivante: Distribution of Vivante software must be a part of, or embedded
within, Authorized Systems that include a Vivante Graphics Processing Unit.
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
firmware-imx: Check if the license information has changed in yocto-template-nxp-imx/sources/meta-freescale/EULA to verify that the LICENSE value "Proprietary" remains valid [license-checksum]
ERROR: firmware-imx-1_8.25-r0 do_populate_lic: Fatal QA errors were found, failing task.
ERROR: Logfile of failure stored in: yocto-template-nxp-imx/build/tmp/work/all-fsl-linux/firmware-imx/8.25/temp/log.do_populate_lic.18239
ERROR: Task (yocto-template-nxp-imx/sources/meta-imx/meta-imx-bsp/recipes-bsp/firmware-imx/firmware-imx_8.25.bb:do_populate_lic) failed with exit code '1'
```

This is due to the meta layer version mismatching in between `meta-imx` and `meta-freescale` when using version defined in [`imx-6.6.36-2.1.0.xml`](https://github.com/nxp-imx/imx-manifest/blob/imx-linux-scarthgap/imx-6.6.36-2.1.0.xml):

```
sources/meta-imx/meta-imx-bsp/recipes-bsp/firmware-imx/firmware-imx-8.25.inc
sources/meta-freescale/recipes-bsp/firmware-imx/firmware-imx-8.24.inc
```
