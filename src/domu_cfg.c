/*
 * Copyright (c) 2023 EPAM Systems
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <domain.h>
#include <zephyr/xen/public/domctl.h>
#include <zephyr/xen/public/arch-arm.h>

#include <string.h>

#include "dom0.h"

extern char __img_domu0_start[];
extern char __img_domu0_end[];
extern char __dtb_domu0_start[];
extern char __dtb_domu0_end[];

static int load_domu_image_bytes(uint8_t *buf, size_t bufsize,
		   uint64_t offset, void *image_info)
{
	ARG_UNUSED(image_info);

	memcpy(buf, __img_domu0_start + offset, bufsize);
	return 0;
}

static ssize_t get_domu_image_size(void *image_info, uint64_t *size)
{
	ARG_UNUSED(image_info);

	*size = __img_domu0_end - __img_domu0_start;
	return 0;
}

static struct xen_domain_cfg domu_cfg = {
	.name = "domu_default",
	.mem_kb = 16384,

	.flags = (XEN_DOMCTL_CDF_hvm | XEN_DOMCTL_CDF_hap),
	.max_evtchns = 10,
	.max_vcpus = 4,
	.gnt_frames = 32,
	.max_maptrack_frames = 1,

	.gic_version =
		IS_ENABLED(CONFIG_GIC_V3) ? XEN_DOMCTL_CONFIG_GIC_V3 : XEN_DOMCTL_CONFIG_GIC_V2,
	.tee_type = XEN_DOMCTL_CONFIG_TEE_NONE,

	.load_image_bytes = load_domu_image_bytes,
	.get_image_size = get_domu_image_size,

	.dtb_start = __dtb_domu0_start,
	.dtb_end = __dtb_domu0_end,
};

struct dom0_domain_cfg domain_cfgs[] = {
	{
		.domain_cfg = &domu_cfg,
	},
	{ 0 },
};
