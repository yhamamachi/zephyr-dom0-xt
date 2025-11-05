#!/bin/bash

BOARD="rcar_sparrow_hawk/r8a779g3/a76"
SCRIPT_DIR=$(cd `dirname $0` && pwd)
WORK_DIR=$SCRIPT_DIR/_work

mkdir -p $WORK_DIR
cd $WORK_DIR

python3 -m venv ./.venv
source ./.venv/bin/activate
pip install west
pip install -U pip
#
west init -o--depth=1 -m https://github.com/yhamamachi/zephyr-dom0-xt.git --mr sparrow-hawk-dev
west update -n
west zephyr-export
west packages pip --install
west sdk install --toolchain aarch64-zephyr-elf

git -C $WORK_DIR/zephyr-dom0-xt pull

# Apply Sparrow-Hawk dom0 support patch
git -C $WORK_DIR/zephyr am --abort
# Apply Xen Dom0 support patch
COMMIT_LIST=(
)
for commit in ${COMMIT_LIST[@]}; do
    wget -qc https://github.com/xen-troops/zephyr/commit/${commit}.patch
    git -C $WORK_DIR/zephyr am ${WORK_DIR}/${commit}.patch
done

# Fix build error on zephyr-xenlib
sed -i -e 's|<zephyr/xen/dom0/version.h>|<zephyr/xen//version.h>|' \
    ${WORK_DIR}/zephyr-xenlib/xstat/src/xstat.c

# Build DomU Zephyr(w/o hardware/device driver domain)
if [[ ! -e $WORK_DIR/zephyr_sync.dtb ]]; then
    west build -b xenvm//gicv3 -p always zephyr/samples/synchronization
    cp -f build/zephyr/zephyr.bin ./zephyr_sync.bin
    dtc -I dts -O dtb build/zephyr/zephyr.dts -o ./zephyr_sync.dtb
fi
CONFIG_DOMU_ZEPHYR_PATH="$WORK_DIR/zephyr_sync.bin"
CONFIG_DOMU_DTB_PATH="$WORK_DIR/zephyr_sync.dtb"

west build -b ${BOARD} -p always ../ -- \
    -DCONFIG_DOM_CFG_BOARD_EXT=\"domu\" \
    -DCONFIG_DOMU_ENABLE=y \
    -DCONFIG_DOMU_ZEPHYR_PATH=\"$CONFIG_DOMU_ZEPHYR_PATH\" \
    -DCONFIG_DOMU_DTB_PATH=\"$CONFIG_DOMU_DTB_PATH\" \

mkimage -f ${SCRIPT_DIR}/fit-image.its ${SCRIPT_DIR}/fitImage
cp -f ${SCRIPT_DIR}/fitImage /tftp

