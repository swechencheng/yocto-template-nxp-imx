# yocto-template-nxp-imx
A sample template of using the minimal BSP layers needed to build Yocto on NXP i.MX targets

## Layer Dependencies

| Submodule | Branch | Version |
| --- | --- | --- |
| openembedded-core | scarthgap | yocto-5.0.6 |
| bitbake | 2.8 | yocto-5.0.6 (2.8.6) |
| meta-openembedded | scarthgap | 2e3126c9c16bb3df0560f6b3896d01539a3bfad7 |
| meta-yocto | scarthgap | bd166d1fb8dc1bed7e71bd06b970a3da9149203e |
| meta-arm | scarthgap | 8aa8a1f17f5b64bc691544f989f04fc83df98adb |
| meta-freescale | scarthgap | 41b923e59e048b9b2942ff737a4ddac386954c62 |
| meta-freescale-3rdparty | scarthgap |  8b61684f0b1ba8bacdf3a69d993445e9791d4932 |
| meta-freescale-distro | scarthgap | 158cc55b6ee30d09957b380859dba52c0f6af68d |
| meta-imx | scarthgap-6.6.23-2.0.0 | rel_imx_6.6.23_2.0.0 |

**i.MX layer source:**
https://github.com/nxp-imx/imx-manifest/blob/imx-linux-scarthgap/imx-6.6.23-2.0.0.xml

These submodules use the version from `imx-6.6.23-2.0.0.xml`:
- meta-arm
- meta-freescale
- meta-freescale-3rdparty
- meta-freescale-distro
- meta-imx
