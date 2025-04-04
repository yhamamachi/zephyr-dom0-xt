/*
 * Copyright (c) 2023 EPAM Systems
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <domain.h>
#include <string.h>
#include <xen_dom_mgmt.h>
#include <zephyr/xen/public/domctl.h>
#include "../dom0.h"

static char* domd_dtdevs[] = {
    "/soc/ethernet@e6460000",
    "/soc/ethernet@e6800000",
    "/soc/ethernet@e6810000",
    "/soc/ethernet@e6820000",
    "/soc/pcie@e65d0000",
    "/soc/pcie@e65d8000",
    "/soc/dma-controller@e7350000",
    "/soc/dma-controller@e7351000",
    "/soc/mmc@ee140000",
    "/soc/vsp@fea20000",
    "/soc/vsp@fea28000",
    "/soc/video@e6ef0000",
    "/soc/video@e6ef1000",
    "/soc/video@e6ef2000",
    "/soc/video@e6ef3000",
    "/soc/video@e6ef8000",
    "/soc/video@e6ef9000",
    "/soc/video@e6efa000",
    "/soc/video@e6efb000",
    "/soc/gsx@fd000000",
    "/soc/cisp@fec00000",
    "/soc/cisp@fee00000",
};
static char* dt_passthrough_nodes[] = {
    "/extal",
    "/extalr",
    "/scif",
    "/soc",
    "/refclk",
    "/regulator-1p8v",
    "/regulator-3p3v",
    "/pcie_bus",
    "/reserved-memory",
};

static struct xen_domain_iomem domd_iomems[] = {
    {.first_mfn = 0xe6050, .nr_mfns = 0x1},
    {.first_mfn = 0xe6058, .nr_mfns = 0x1},
    {.first_mfn = 0xe6060, .nr_mfns = 0x1},
    {.first_mfn = 0xe6061, .nr_mfns = 0x1},
    {.first_mfn = 0xe6068, .nr_mfns = 0x1},
    {.first_mfn = 0xe6020, .nr_mfns = 0x1},
    {.first_mfn = 0xe6150, .nr_mfns = 0x4},
    {.first_mfn = 0xe6160, .nr_mfns = 0x4},
    {.first_mfn = 0xe6180, .nr_mfns = 0x4},
    {.first_mfn = 0xe6c50, .nr_mfns = 0x1},
    {.first_mfn = 0xe7350, .nr_mfns = 0x1},
    {.first_mfn = 0xe7300, .nr_mfns = 0x10},
    {.first_mfn = 0xe7351, .nr_mfns = 0x1},
    {.first_mfn = 0xe7310, .nr_mfns = 0x10},
    {.first_mfn = 0xee140, .nr_mfns = 0x2},
    {.first_mfn = 0xfff00, .nr_mfns = 0x1},
    {.first_mfn = 0xe60a0, .nr_mfns = 0x1},
    {.first_mfn = 0xe6800, .nr_mfns = 0x1},
    {.first_mfn = 0xe6810, .nr_mfns = 0x1},
    {.first_mfn = 0xe6820, .nr_mfns = 0x1},
    {.first_mfn = 0xe6460, .nr_mfns = 0x7},
    {.first_mfn = 0xe6449, .nr_mfns = 0x1},
    {.first_mfn = 0xe6061, .nr_mfns = 0x1},
    {.first_mfn = 0xe65d0, .nr_mfns = 0x3},
    {.first_mfn = 0xe65d3, .nr_mfns = 0x2},
    {.first_mfn = 0xe65d5, .nr_mfns = 0x2},
    {.first_mfn = 0xe65d6, .nr_mfns = 0x1},
    {.first_mfn = 0xe65d7, .nr_mfns = 0x1},
    {.first_mfn = 0xfe000, .nr_mfns = 0x400},
    {.first_mfn = 0x30000, .nr_mfns = 0x8000},
    {.first_mfn = 0xe65d8, .nr_mfns = 0x3},
    {.first_mfn = 0xe65db, .nr_mfns = 0x2},
    {.first_mfn = 0xe65dd, .nr_mfns = 0x2},
    {.first_mfn = 0xe65de, .nr_mfns = 0x1},
    {.first_mfn = 0xe65df, .nr_mfns = 0x1},
    {.first_mfn = 0xee900, .nr_mfns = 0x400},
    {.first_mfn = 0xe6500, .nr_mfns = 0x1},
    {.first_mfn = 0xe6508, .nr_mfns = 0x1},
    {.first_mfn = 0xe6510, .nr_mfns = 0x1},
    {.first_mfn = 0xe66d0, .nr_mfns = 0x1},
    {.first_mfn = 0xe66d8, .nr_mfns = 0x1},
    {.first_mfn = 0xe66e0, .nr_mfns = 0x1},
    {.first_mfn = 0xfea20, .nr_mfns = 0x8},
    {.first_mfn = 0xfea28, .nr_mfns = 0x8},
    {.first_mfn = 0xfeb00, .nr_mfns = 0x40},
    {.first_mfn = 0xfed80, .nr_mfns = 0x10},
    {.first_mfn = 0xfed90, .nr_mfns = 0x10},
    {.first_mfn = 0xfeb8d, .nr_mfns = 0x1},
    {.first_mfn = 0xe6ef0, .nr_mfns = 0x1},
    {.first_mfn = 0xe6ef1, .nr_mfns = 0x1},
    {.first_mfn = 0xe6ef2, .nr_mfns = 0x1},
    {.first_mfn = 0xe6ef3, .nr_mfns = 0x1},
    {.first_mfn = 0xe6ef8, .nr_mfns = 0x1},
    {.first_mfn = 0xe6ef9, .nr_mfns = 0x1},
    {.first_mfn = 0xe6efa, .nr_mfns = 0x1},
    {.first_mfn = 0xe6efb, .nr_mfns = 0x1},
    {.first_mfn = 0xfe500, .nr_mfns = 0x40},
    {.first_mfn = 0xfe540, .nr_mfns = 0x40},
    {.first_mfn = 0xfed00, .nr_mfns = 0x10},
    {.first_mfn = 0xfed20, .nr_mfns = 0x10},
    {.first_mfn = 0xfd000, .nr_mfns = 0x800},
    {.first_mfn = 0xfec00, .nr_mfns = 0x100},
    {.first_mfn = 0xfee00, .nr_mfns = 0x100},
};

static uint32_t domd_irqs[] = {
// gpio@e6050180
    651,
// gpio@e6050980
    655,
// gpio@e6058180
    659,
// gpio@e6058980
    663,
// gpio@e6060180
    667,
// gpio@e6060980
    671,
// gpio@e6061180
    675,
// gpio@e6061980
    679,
// gpio@e6068180
    683,
// dma-controller@e7350000
    128, 129, 112, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127,
// dma-controller@e7351000
    130, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147,
// ethernet@e6800000
    384, 385, 386, 387, 388, 389, 390, 391, 367, 368, 369, 370, 371, 372, 373, 374, 375, 376, 377, 378, 379, 380, 381, 382, 383,
// ethernet@e6460000
    461, 462,
// mmc@ee140000
    472,
// pcie@e65d0000
    481, 482, 483, 484, 485, 486, 487,
// pcie@e65d8000
    488, 489, 490, 491, 492, 493, 494,
// i2c@e6500000
    642,
// i2c@e6508000
    643,
// i2c@e6510000
    644,
// i2c@e66d0000
    645,
// i2c@e66d8000
    646,
// i2c@e66e0000
    647,
// vsp@fea20000
    578,
// vsp@fea28000
    583,
// du0
    555,
// video@e6ef0000
    561,
// video@e6ef1000
    562,
// video@e6ef2000
    563,
// video@e6ef3000
    564,
// video@e6ef8000
    569,
// video@e6ef9000
    570,
// video@e6efa000
    571,
// video@e6efb000
    572,
// csi2@fe500000
    531,
// csi2@fe540000
    532,
//isp@fed00000
    505,
//isp@fed20000
    506,
// gsx@fd000000
    496,
//cisp0@fec00000
    507,
//cisp1@fee00000
    508,
};

extern char __img_ipl_start[];
extern char __img_ipl_end[];
extern char __dtb_ipl_start[];
extern char __dtb_ipl_end[];

static int load_ipl_image(uint8_t* buf, size_t bufsize, uint64_t image_load_offset, void* image_info)
{
    ARG_UNUSED(image_info);
    memcpy(buf, __img_ipl_start + image_load_offset, bufsize);
    return 0;
}

static ssize_t get_ipl_image_size(void* image_info, uint64_t* size)
{
    ARG_UNUSED(image_info);
    *size = __img_ipl_end - __img_ipl_start;
    return 0;
}

struct xen_domain_cfg domd_cfg = {
    .name                 = "DomD",
    //.machine_dt_compat    = (const char*[]) {"renesas,r8a779g0", "renesas,whitehawk-cpu"},
    .machine_dt_compat    = (const char*[]) {"renesas,r8a779g0"},
    .nr_machine_dt_compat = 1,
    .mem_kb               = 0x100000, /* 1Gb */

    .flags               = (XEN_DOMCTL_CDF_hvm | XEN_DOMCTL_CDF_hap | XEN_DOMCTL_CDF_iommu),
    .max_evtchns         = 10,
    .max_vcpus           = 4,
    .gnt_frames          = 32,
    .max_maptrack_frames = 1,

    .iomems    = domd_iomems,
    .nr_iomems = ARRAY_SIZE(domd_iomems),

    .irqs    = domd_irqs,
    .nr_irqs = ARRAY_SIZE(domd_irqs),

    .gic_version = XEN_DOMCTL_CONFIG_GIC_V3,
    .tee_type    = XEN_DOMCTL_CONFIG_TEE_NONE,

    .dtdevs    = domd_dtdevs,
    .nr_dtdevs = ARRAY_SIZE(domd_dtdevs),

    .dt_passthrough    = dt_passthrough_nodes,
    .nr_dt_passthrough = ARRAY_SIZE(dt_passthrough_nodes),
    .load_image_bytes  = load_ipl_image,
    .get_image_size    = get_ipl_image_size,
    .image_info        = NULL,
    //.cmdline           = "root=/dev/mmcblk0p2 rw rootwait",
    .dtb_start = __dtb_ipl_start,
    .dtb_end   = __dtb_ipl_end,
};

struct dom0_domain_cfg domain_cfgs[] = {
    {
        .domain_cfg = &domd_cfg,
    },
    { 0 },
};

