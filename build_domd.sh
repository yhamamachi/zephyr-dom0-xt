#!/bin/bash -eu

BOARD_LIST=("spider" "whitehawk")
BOARD="dummy"
SCRIPT_DIR=$(cd `dirname $0` && pwd)
ZEPHYR_VERSION=0.16.0
ZEPHYR_SDK_PATH=${SCRIPT_DIR}/zephyr-sdk-${ZEPHYR_VERSION}
WORK_DIR=$SCRIPT_DIR/work

Usage () {
    echo "$0 <board_name>"
    echo "board_name:"
    for i in ${BOARD_LIST[@]}; do echo "  - $i"; done
}

# Check arguments
for arg in $@; do
    if [[ "${arg}" == "spider" ]]; then
        BOARD="rcar_spider_ca55"
        CONFIG_DOMD_DTB_PATH="/work/xen_build/spider-1.3.2-4.19/build_xen419/yocto/build-domd/tmp/deploy/images/spider/r8a779f0-spider-domd.dtb"
    elif [[ "${arg}" == "whitehawk" ]]; then
        BOARD="rcar_whitehawk_ca76"
        CONFIG_DOMD_DTB_PATH="/work/v4h_xen/build/yocto/build-domd/tmp/deploy/images/whitehawk/r8a779g0-whitehawk-domd.dtb"
    fi
done
if [[ "$BOARD" == "dummy" ]]; then
    Usage; exit -1
fi

# Setup SDK
cd ${SCRIPT_DIR}
if [ ! -e "${ZEPHYR_SDK_PATH}" ]; then
    # Minimal SDK
    wget -c https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZEPHYR_VERSION}/zephyr-sdk-${ZEPHYR_VERSION}_linux-x86_64_minimal.tar.xz
    tar xf zephyr-sdk-${ZEPHYR_VERSION}_linux-x86_64_minimal.tar.xz
    # toolchain(arm)
    # wget -c https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZEPHYR_VERSION}/toolchain_linux-x86_64_arm-zephyr-eabi.tar.xz
    # tar xf toolchain_linux-x86_64_arm-zephyr-eabi.tar.xz -C zephyr-sdk-${ZEPHYR_VERSION}
    # toolchain(aarch64)
    wget -c https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZEPHYR_VERSION}/toolchain_linux-x86_64_aarch64-zephyr-elf.tar.xz
    tar xf toolchain_linux-x86_64_aarch64-zephyr-elf.tar.xz -C zephyr-sdk-${ZEPHYR_VERSION}
fi
cd ${ZEPHYR_SDK_PATH}
./setup.sh -c

mkdir -p $WORK_DIR
cd $WORK_DIR

# DomD U-boot
git clone https://github.com/xen-troops/u-boot -b zephyr_rcar_ipl_v2023.10 $WORK_DIR/u-boot || true
DEFCONFIG=rcar4_xen_defconfig

cd $WORK_DIR/u-boot
git reset --hard origin/zephyr_rcar_ipl_v2023.10; git clean -dffx
git -C $WORK_DIR/u-boot am $SCRIPT_DIR/0001-WIP-xen-rcar-gen4-Add-support-whitehawk.patch

BOOTCOMMAND="load mmc 0:2 0x44001000 /boot/Image; booti 0x44001000 - 0x48000000"
sed -i -e "s|CONFIG_BOOTCOMMAND=.*|CONFIG_BOOTCOMMAND=\"${BOOTCOMMAND}\"|" configs/${DEFCONFIG}
#sed -i -e "s/HS400_SUPPORT/HS200_SUPPORT/" configs/${DEFCONFIG}
cat << EOS >> configs/${DEFCONFIG}
CONFIG_BOOTDELAY=0
EOS

ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- make ${DEFCONFIG} all -j$(nproc)
CONFIG_DOMD_UBOOT_PATH="${WORK_DIR}/u-boot/u-boot.bin"

ls $CONFIG_DOMD_UBOOT_PATH
ls $CONFIG_DOMD_DTB_PATH

# Dom0 Zephyr
cd $WORK_DIR
west init -o--depth=1 -m https://github.com/yhamamachi/zephyr-dom0-xt.git --mr rcars4_dev || true
west update -n

# Applt whitehawk support patch
git -C $WORK_DIR/zephyr am $SCRIPT_DIR/0001-WIP-Add-initial-support-Whitehawk-CA76.patch
# Fix build error using xenvm_gicv3
sed -i zephyr/drivers/xen/regions.c -e "s/> EXTENDED_REGIONS_IDX/>= EXTENDED_REGIONS_IDX/"
# Apply k_malloc patch for devicetree memory
git -C $WORK_DIR/zephyr-xenlib am $SCRIPT_DIR/0001-WIP-Change-to-use-k_malloc-for-pfdt_read_buf.patch

# Xen-4.20 has XEN_DOMCTL_INTERFACE_VERSION=0x00000018, but Kconfig range is 0x15 to 0x17
sed -i ${WORK_DIR}/zephyr/arch/arm64/core/xen/Kconfig -e 's/0x17/0x18/'

# Support Xen old version
#sed -i ${WORK_DIR}/zephyr/drivers/xen/dom0/domctl.c \
#    -e "s/CONFIG_XEN_DOMCTL_INTERFACE_VERSION >= 0x00000016/CONFIG_XEN_DOMCTL_INTERFACE_VERSION >= 0x00000015/"
#sed -i ${WORK_DIR}/zephyr/include/zephyr/xen/public/domctl.h \
#    -e "s/CONFIG_XEN_DOMCTL_INTERFACE_VERSION >= 0x00000016/CONFIG_XEN_DOMCTL_INTERFACE_VERSION >= 0x00000015/"

west build -b ${BOARD} -p always  -S xen_dom0 ../ -- \
    -DCONFIG_DOM_CFG_BOARD_EXT=\"domd\" \
    -DCONFIG_DOMD_ENABLE=y \
    -DCONFIG_DOMD_UBOOT_PATH=\"$CONFIG_DOMD_UBOOT_PATH\" \
    -DCONFIG_DOMD_DTB_PATH=\"$CONFIG_DOMD_DTB_PATH\" \

cp -f build/zephyr/zephyr.bin /tftp/zephyr.bin

