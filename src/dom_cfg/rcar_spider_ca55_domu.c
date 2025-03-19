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

static char* domu_dtdevs[] = {
};
static char* dt_passthrough_nodes[] = {
};

static struct xen_domain_iomem domu_iomems[] = {
};

static uint32_t domu_irqs[] = {
};

extern char __img_domu_start[];
extern char __img_domu_end[];
extern char __dtb_domu_start[];
extern char __dtb_domu_end[];

static int load_domu_image(uint8_t* buf, size_t bufsize, uint64_t image_load_offset, void* image_info)
{
    ARG_UNUSED(image_info);
    memcpy(buf, __img_domu_start + image_load_offset, bufsize);
    return 0;
}

static ssize_t get_domu_image_size(void* image_info, uint64_t* size)
{
    ARG_UNUSED(image_info);
    *size = __img_domu_end - __img_domu_start;
    return 0;
}

struct xen_domain_cfg domu_cfg = {
    .name                 = "DomU",
    //.machine_dt_compat    = (const char*[]) {"renesas,r8a779f0"},
    //.nr_machine_dt_compat = 1,
    //.machine_dt_compat    = "renesas,r8a779f0",
    .mem_kb               = 0x10000, /* 10 Mb */
    //.mem_kb               = 16384, /* ???? */

    .flags               = (XEN_DOMCTL_CDF_hvm | XEN_DOMCTL_CDF_hap),
    .max_evtchns         = 10,
    .max_vcpus           = 1,
    .gnt_frames          = 32,
    .max_maptrack_frames = 1,

    .iomems    = domu_iomems,
    .nr_iomems = ARRAY_SIZE(domu_iomems),

    .irqs    = domu_irqs,
    .nr_irqs = ARRAY_SIZE(domu_irqs),

    .gic_version = XEN_DOMCTL_CONFIG_GIC_V3,
    //.tee_type    = XEN_DOMCTL_CONFIG_TEE_OPTEE,
    .tee_type    = XEN_DOMCTL_CONFIG_TEE_NONE,

    .dtdevs    = domu_dtdevs,
    .nr_dtdevs = ARRAY_SIZE(domu_dtdevs),

    .dt_passthrough    = dt_passthrough_nodes,
    .nr_dt_passthrough = ARRAY_SIZE(dt_passthrough_nodes),
    .load_image_bytes  = load_domu_image,
    .get_image_size    = get_domu_image_size,
    .image_info        = NULL,
    .cmdline = "",
    .dtb_start = __dtb_domu_start,
    .dtb_end   = __dtb_domu_end,
    .ssidref = 12,
};

struct dom0_domain_cfg domain_cfgs[] = {
    {
        .domain_cfg = &domu_cfg,
    },
    { 0 },
};

