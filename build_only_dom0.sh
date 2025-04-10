#!/bin/bash

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
    elif [[ "${arg}" == "whitehawk" ]]; then
        BOARD="rcar_whitehawk_ca76"
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
west init -o--depth=1 -m https://github.com/yhamamachi/zephyr-dom0-xt.git --mr rcars4_dev
west update -n

# Applt whitehawk support patch
git -C $WORK_DIR/zephyr am $SCRIPT_DIR/0001-WIP-Add-initial-support-Whitehawk-CA76.patch
# Fix build error using xenvm_gicv3
sed -i zephyr/drivers/xen/regions.c -e "s/> EXTENDED_REGIONS_IDX/>= EXTENDED_REGIONS_IDX/"

west build -b ${BOARD} -p always  -S xen_dom0 ../ --

cp -f build/zephyr/zephyr.bin /tftp

