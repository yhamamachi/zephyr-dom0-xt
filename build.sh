#!/bin/bash

SCRIPT_DIR=$(cd `dirname $0` && pwd)
ZEPHYR_VERSION=0.16.0
ZEPHYR_SDK_PATH=${SCRIPT_DIR}/zephyr-sdk-${ZEPHYR_VERSION}
WORK_DIR=$SCRIPT_DIR/work

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
#BOARD=rpi_5
#BOARD=rcar_spider_s4/r8a779f0/a55
BOARD=rcar_spider_ca55
#west init -o--depth=1 -m https://github.com/yhamamachi/zephyr-dom0-xt.git --mr rcars4_dev
west init -l ../
west update -n
#west build -b ${BOARD} -p always  -S xen_dom0 zephyr/samples/hello_world/
#west build -b ${BOARD} -p always  -S xen_dom0 zephyr-dom0-xt

CONFIG_DOMD_UBOOT_PATH="/work/github/meta-aos-rcar-gen4/work/yocto/build-domd/tmp/deploy/images/spider/u-boot-domd.bin"
CONFIG_DOMD_DTB_PATH="/work/github/meta-aos-rcar-gen4/work/yocto/build-domd/tmp/deploy/images/spider/r8a779f0-spider-domd.dtb"
west build -b ${BOARD} -p always  -S xen_dom0 ../ -- \
    -DCONFIG_DOMD_ENABLE=y \
    -DCONFIG_DOMD_UBOOT_PATH=\"$CONFIG_DOMD_UBOOT_PATH\" \
    -DCONFIG_DOMD_DTB_PATH=\"$CONFIG_DOMD_DTB_PATH\" \

cp -f build/zephyr/zephyr.bin /tftp

