# zephyr-dom0-xt for S4 spider/V4H whitehawk envrionment

Original Readme: [README.rst](./README.rst)

## Status

- Dom0 + DomU Zephyr + Xen-4.19: OK
  - build.sh
- Dom0 + DomD Linux + Xen-4.19; Not work
  - build_domd.sh(WIP)
    - DomD U-Boot doesn't boot correctly(a lot of trap logs are shown in console).
- Dom0 + DomD Zephyr + Xen-4.19: Not started to development

## How to build environment(Dom0 + DomU Zephyr)

```
./build.sh <board_name>
# work/build/zephyr/zephyr.bin is generated.
# By default, build script copy the binary to /tftp
```

## How to boot

### Using tftp and eMMC

#### Build Xen-4.19 envrionment

<details>
<summary>For S4 Spider</summary>

```
#!/bin/bash -eu

mkdir -p build_xen419
cd build_xen419
wget -c https://github.com/xen-troops/meta-xt-prod-devel-rcar-gen4/raw/refs/heads/spider-1.3.2%2B4.19/prod-devel-rcar-s4.yaml
moulin prod-devel-rcar-s4.yaml --ENABLE_DOMU yes

ninja fetch-domd
# Change to use xen 4.19 instaed of 4.20-unstable
cat << EOS > yocto/meta-xt-prod-devel-rcar-gen4/meta-xt-domx-gen4/recipes-extended/xen/xen-source.inc
SRC_URI = "git://github.com/xen-troops/xen.git;protocol=https;branch=xen-4.19-xt0.2"
XEN_REL = "4.19"
XEN_REV = "8d17019373ad2d0928dfe9ce1ee4e3805209fc6c"
LIC_FILES_CHKSUM = "file://COPYING;md5=d1a1e216f80b6d8da95fec897d0dbec9"
EOS
sed -i yocto/meta-xt-prod-devel-rcar-gen4/meta-xt-domx-gen4/recipes-extended/xen/xen-tools_git.bbappend -e 's/^SYSTEMD_SERVICE:${PN}-pcid/#SYSTEMD_SERVICE:${PN}-pcid/'


# Remove xen boot delay 3sec
sed -i yocto/meta-xt-prod-devel-rcar-gen4/meta-xt-domx-gen4/recipes-extended/xen/xen_git.bbappend -e "/do_configure:append/,+6d"
cat << 'EOS' >> yocto/meta-xt-prod-devel-rcar-gen4/meta-xt-domx-gen4/recipes-extended/xen/xen_git.bbappend
do_configure:append () {
    cd ${S}
    # Remove 3sec delay
    sed -i xen/common/warning.c \
        -e '/for ( i = 0; i < 3; i++ )/,+9d' \
        -e 's/, j//'
}
EOS

find ../common_data/sstate | grep boot-script: | xargs rm -r || true
ninja
ninja image-full
gzip -f full.img
```

</details>

<details>
<summary>For V4H Whitehawk</summary>

```
#!/bin/bash -eu

YAML_FILE=https://raw.githubusercontent.com/xen-troops/meta-xt-prod-devel-rcar-gen4/refs/heads/v4h_demo/prod-devel-rcar4.yaml
SCRIPT_DIR=$(cd `dirname $0` && pwd)
mkdir -p ${SCRIPT_DIR}/build

# GFX package
GFX_DRV="https://github.com/renesas-rcar/rcar-gfx/raw/refs/heads/V4Hx/v1.3.1-2/gfxdrv/GSX_KM_V4H.tar.bz2"
GFX_LIB="https://github.com/renesas-rcar/rcar-gfx/raw/refs/heads/V4Hx/v1.3.1-2/opengl/r8a779g0_linux_gsx_binaries_gles.tar.bz2"
mkdir -p ${SCRIPT_DIR}/prop; cd ${SCRIPT_DIR}/prop
wget -c ${GFX_DRV}
wget -c ${GFX_LIB}
cp -f ./GSX_KM_V4H.tar.bz2 ${SCRIPT_DIR}/build/GSX_KM_V4H_DDK23.3_v2.tar.bz2
cp -f ./r8a779g0_linux_gsx_binaries_gles.tar.bz2 ${SCRIPT_DIR}/build/r8a779g0_linux_gsx_binaries_gles_vz_DDK23.3_v2.tar.bz2

cd ${SCRIPT_DIR}/build
curl -LO https://raw.github.com/xen-troops/meta-xt-prod-devel-rcar-gen4/v4h_demo/prod-devel-rcar4.yaml
sed -i -e "s/4.17.0+git%/4.19.0+git%/" prod-devel-rcar4.yaml

moulin prod-devel-rcar4.yaml \
    --MACHINE whitehawk \
    --ENABLE_DOMU yes \

ninja fetch-domd
git -C yocto/meta-xt-prod-devel-rcar-gen4 reset --hard
# Change to use xen 4.19
cat << EOS > yocto/meta-xt-prod-devel-rcar-gen4/meta-xt-domx-gen4/recipes-extended/xen/xen-source.inc
SRC_URI = "git://github.com/xen-troops/xen.git;protocol=https;branch=xen-4.19-xt0.2"
XEN_REL = "4.19"
XEN_REV = "8d17019373ad2d0928dfe9ce1ee4e3805209fc6c"
LIC_FILES_CHKSUM = "file://COPYING;md5=d1a1e216f80b6d8da95fec897d0dbec9"
EOS
sed -i yocto/meta-xt-prod-devel-rcar-gen4/meta-xt-domx-gen4/recipes-extended/xen/xen-tools_git.bbappend -e 's/^SYSTEMD_SERVICE:${PN}-pcid/#SYSTEMD_SERVICE:${PN}-pcid/'
sed -i -e "7,8d" yocto/meta-xt-prod-devel-rcar-gen4/meta-xt-driver-domain-gen4/recipes-extended/xen/xen_git.bbappend
echo "SYSTEMD_SERVICE:xen-tools-xencommons:remove = 'var-lib-xenstored.mount'" >> yocto/meta-xt-prod-devel-rcar-gen4/meta-xt-domx-gen4/recipes-extended/xen/xen-tools_git.bbappend
echo 'FILES:${PN} += "/var/lib /usr/lib/xen/bin/*"' >> yocto/meta-xt-prod-devel-rcar-gen4/meta-xt-domx-gen4/recipes-extended/xen/xen-tools_git.bbappend
sed -i -e "7,9d" yocto/meta-xt-prod-devel-rcar-gen4/meta-xt-prod-devel-rcar-control-gen4/recipes-extended/xen/xen-tools_git.bbappend

# Remove xen boot delay 3sec
sed -i yocto/meta-xt-prod-devel-rcar-gen4/meta-xt-domx-gen4/recipes-extended/xen/xen_git.bbappend -e "/do_configure:append/,+6d"
cat << 'EOS' >> yocto/meta-xt-prod-devel-rcar-gen4/meta-xt-domx-gen4/recipes-extended/xen/xen_git.bbappend
do_configure:append () {
    cd ${S}
    # Remove 3sec delay
    sed -i xen/common/warning.c \
        -e '/for ( i = 0; i < 3; i++ )/,+9d' \
        -e 's/, j//'
}
EOS

# Remove unused memory assign
cat << 'EOS' >> yocto/meta-xt-prod-devel-rcar-gen4/meta-xt-domd-gen4/recipes-kernel/linux/linux-renesas_%.bbappend
do_compile:prepend() {
    sed -i ${S}/arch/arm64/boot/dts/renesas/r8a779g0-whitehawk.dts \
        -e "/linux,cr_region@60000000/,+3d"
    sed -i ${S}/arch/arm64/boot/dts/renesas/r8a779g0-domd.dts \
        -e "/cr_region/d"
}
EOS

ninja
ninja full.img.gz
ninja boot_artifacts
```

</details>

#### U-Boot env setup

<details>
<summary>For S4 Spider</summary>

```
setenv flash_emmc_xen 'tftp 0x480000000 full.img.gz; gzwrite mmc 0 0x480000000 ${filesize} 400000 0'
setenv ipaddr 192.168.10.15
setenv serverip 192.168.10.1
setenv set_pcie 'i2c dev 0; i2c mw 0x6c 0x26 5; i2c mw 0x6c 0x254.2 0x1e; i2c mw 0x6c 0x258.2 0x1e; i2c mw 0x20 0x3.1 0xfe;'
setenv set_ufs 'i2c dev 0; i2c mw 0x6c 0x26 0x05; i2c olen 0x6c 2; i2c mw 0x6c 0x13a 0x86; i2c mw 0x6c 0x26a 0x3c; i2c mw 0x6c 0x26b 0x00; i2c mw 0x6c 0x268 0x06; i2c mw 0x6c 0x269 0x00; i2c mw 0x6c 0x26c 0x06; i2c mw 0x6c 0x26d 0x00; i2c mw 0x6c 0x26e 0x3f; i2c mw 0x6c 0x26f 0x00'
setenv xen_emmc 'env delete bootargs && ext4load mmc 0:1 0x83000000 boot-emmc.uImage && source 0x83000000'
setenv xen_emmc_manual 'env delete bootargs; run set_pcie; run set_ufs; run xen_emmc_manual1; run xen_emmc_manual2; run xen_emmc_manual3;'
setenv xen_emmc_manual0 "setenv bootargs 'dom0_mem=256M console=dtuart dtuart=/soc/serial@e6540000 dom0_max_vcpus=1 loglvl=info xsm=dummy flask=permissive bootscrub=0 pci-passthrough=on'"
setenv xen_emmc_manual1z 'tftp 0x7a000000 zephyr.bin'
setenv xen_emmc_manual2 'load mmc 0:1 0x48000000 xen.dtb; load mmc 0:1 0x48080000 xen; load mmc 0:1 0x7c000000 xenpolicy; fdt addr 0x48000000; fdt resize;'
setenv xen_emmc_manual3z 'fdt mknode / boot_dev; fdt set /boot_dev device mmcblk0; bootm 0x48080000 - 0x48000000;'
setenv xen_emmc_manual_testz 'env delete bootargs; run set_pcie; run set_ufs; run xen_emmc_manual0; run xen_emmc_manual1z; run xen_emmc_manual2; run xen_emmc_manual3z;'
setenv bootcmd 'run xen_emmc_manual_testz'
```

</details>

<details>
<summary>For V4H Whitehawk</summary>

```
setenv flash_emmc_xen 'tftp 0x480000000 full.img.gz; gzwrite mmc 0 0x480000000 ${filesize} 400000 0'
setenv ipaddr 192.168.10.15
setenv serverip 192.168.10.1
setenv xen_emmc 'env delete bootargs && ext4load mmc 0:1 0x83000000 boot-emmc.uImage && source 0x83000000'
setenv xen_emmc_manual 'env delete bootargs; run xen_emmc_manual1; run xen_emmc_manual2; run xen_emmc_manual3;'
setenv xen_emmc_manual0 "setenv bootargs 'dom0_mem=256M console=dtuart dtuart=/soc/serial@e6540000 dom0_max_vcpus=1 loglvl=info xsm=dummy flask=permissive bootscrub=0 pci-passthrough=on'"
setenv xen_emmc_manual1z 'tftp 0x48200000 zephyr.bin'
setenv xen_emmc_manual2 'load mmc 0:1 0x48000000 xen.dtb; load mmc 0:1 0x48080000 xen; load mmc 0:1 0x48070000 xenpolicy; fdt addr 0x48000000; fdt resize;'
setenv xen_emmc_manual3z 'fdt mknode / boot_dev; fdt set /boot_dev device mmcblk0; bootm 0x48080000 - 0x48000000;'
setenv xen_emmc_manual_testz 'env delete bootargs; run xen_emmc_manual0; run xen_emmc_manual1z; run xen_emmc_manual2; run xen_emmc_manual3z;'
setenv bootcmd 'run xen_emmc_manual_testz'
```

</details>

#### Flash xen imange to eMMC

```
run flash_emmc_xen
```

#### Boot

Just power on

##### Bootlog example

```
(snip)
(XEN) *** Serial input to DOM0 (type 'CTRL-a' three times to switch input)
(XEN) Freed 356kB init memory.
*** Booting Zephyr OS build 4d91cdd6fd3f ***
I: dom0.c: main function: start
W: Domain device tree generation is not supported
I: rambase = 40000000, ramsize = 67108864
I: kernbase = 40000000 kernsize = 319492, dtbsize = 1289
I: kernsize_aligned = 2097152
I: DTB will be placed on addr = 0x43e00000
I: dom0.c: main function: end


uart:~$
```

### Using eMMC only

#### How to build

T.B.D.


