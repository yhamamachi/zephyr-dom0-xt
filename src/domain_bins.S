/*
 * Copyright (c) 2023 EPAM Systems
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <zephyr/toolchain.h>

#if defined(CONFIG_DOM_CFG_BUILTIN_IMAGES)

/* DomU0 binary from include/ dir */
.section .data.domu0_img,"a"

GDATA(__img_domu0_start)
GDATA(__img_domu0_end)

__img_domu0_start:
.incbin		CONFIG_DOM_CFG_DOMU0_IMAGE_BIN_FILE
__img_domu0_end:

/* DomU0 dtb from include/ dir */
.section .data.dtb_domu0,"a"
.align 8

GDATA(__dtb_domu0_start)
GDATA(__dtb_domu0_end)

__dtb_domu0_start:
.incbin		CONFIG_DOM_CFG_DOMU0_DTB_BIN_FILE
__dtb_domu0_end:

#if defined(CONFIG_DOM_CFG_DOMU1_IMAGE_BIN_FILE)
/* DomU1 binary from include/ dir */
.section .data.domu1_img,"a"

GDATA(__img_domu1_start)
GDATA(__img_domu1_end)

__img_domu1_start:
.incbin		CONFIG_DOM_CFG_DOMU1_IMAGE_BIN_FILE
__img_domu1_end:
#endif /* CONFIG_DOM_CFG_DOMU1_IMAGE_BIN_FILE */

#if defined(CONFIG_DOM_CFG_DOMU1_DTB_BIN_FILE)
/* DomU1 dtb from include/ dir */
.section .data.dtb_domu1,"a"
.align 8

GDATA(__dtb_domu1_start)
GDATA(__dtb_domu1_end)

__dtb_domu1_start:
.incbin		CONFIG_DOM_CFG_DOMU1_DTB_BIN_FILE
__dtb_domu1_end:
#endif /* CONFIG_DOM_CFG_DOMU1_DTB_BIN_FILE */

#endif /* CONFIG_DOM_CFG_BUILTIN_IMAGES */        

#ifdef CONFIG_DOMD_ENABLE
.section .data.img_ipl,"a"
GDATA(__img_ipl_start)
GDATA(__img_ipl_end)
__img_ipl_start:
.incbin CONFIG_DOMD_UBOOT_PATH
__img_ipl_end:

.section .data.dtb_ipl,"a"
GDATA(__dtb_ipl_start)
GDATA(__dtb_ipl_end)
__dtb_ipl_start:
.align 8
.incbin CONFIG_DOMD_DTB_PATH
__dtb_ipl_end:
#endif /* CONFIG_DOMD_ENABLE */



