# KOOMPI OS Automated Installation

To set up KOOMPI OS with Calamares system installation tool on hundreds of computers is a pain in life for production line team. This tool aims to make their lives easier through making everything is automated.

**NOTE**

    This is only suitable for mass installation where all computers have the same specifications.

## Deploy

This tool is designed to work with any Linux ISO implementing Arch Linux style. Supportedly, you already have and archiso airootfs. The command below is to be placed in the airootfs directory

```bash
cp auto_setup.sh /usr/bin/
cp oem_setup.sh /root/
```
