/** @file
*
*  Mali G610 MC4 GPU / RK3588S VOP2 / RGA3 — ACPI device declaration
*
*  This file declares a single ACPI device (GPU0) covering the Mali GPU,
*  the VOP2 display controller, the CRU clock/reset unit, the PMU power
*  management unit, and the RGA3 2D accelerator. They are grouped into
*  one PnP device because the Windows KMDOD prototype driver treats
*  them as a single logical display adapter.
*
*  Memory map (from the public RK3588S TRM):
*    GPU  MMIO  0xFB000000  len 0x100000   Mali G610 register bank
*    VOP2 MMIO  0xFDD00000  len 0x100000   Video Output Processor v2
*    CRU  MMIO  0xFD7C0000  len 0x10000    Clock & Reset Unit
*    PMU  MMIO  0xFD880000  len 0x10000    Power Management Unit
*    RGA3 MMIO  0xFDB20000  len 0x1000     2D acceleration engine
*
*  IRQs (GIC SPI numbers — the resource template adds 32 for the
*  SPI-to-IRQ-number translation the GIC HAL layer expects):
*    SPI 85  GPU combined IRQ (GPU_INT + JOB_INT + MMU_INT)
*    SPI 35  VOP2 frame-start / frame-done IRQ
*    SPI 77  RGA3 batch-completion IRQ
*
*  The Windows test driver matches ACPI\ARMF5100 via the _HID below.
*  The Linux devicetree binding equivalent is "rockchip,rk3588-mali"
*  plus "arm,mali-valhall-csf" for the GPU, and "rockchip,rk3588-vop"
*  for VOP2.
*
*  Copyright (c) 2024, Open Source Mali-WOA Project
*  Copyright (c) 2024, Mario Bălănică (style adapted from edk2-rk3588)
*
*  SPDX-License-Identifier: BSD-2-Clause-Patent
*
**/
#include "AcpiTables.h"

Scope (\_SB_)
{
    Device (GPU0)
    {
        /* ARMF5100 — registered ACPI ID for the Mali G610 prototype
         * driver. Matches the INF's [MaliG610.ARM64.NTARM64] section. */
        Name (_HID, "ARMF5100")
        Name (_UID, 0x0)
        Name (_DDN, "Mali G610 MC4 / RK3588 Display Adapter")
        /* _STA = 0xF means: present + enabled + shown in UI + functional */
        Name (_STA, 0xF)
        /* _CCA = 1 means: cache-coherent (the Mali GPU is on the
         * ACE-Lite coherent interconnect on RK3588). Setting this
         * matters for DMA buffer allocation on Windows ARM64. */
        Name (_CCA, 1)

        Method (_CRS, 0x0, Serialized)
        {
            Name (RBUF, ResourceTemplate ()
            {
                /* ---- Mali GPU register bank ---------------------------- */
                Memory32Fixed (ReadWrite,
                    0xFB000000, 0x00100000, , Y_GPU)

                /* ---- VOP2 display controller --------------------------- */
                Memory32Fixed (ReadWrite,
                    0xFDD00000, 0x00100000, , Y_VOP)

                /* ---- CRU (clock + reset unit) -------------------------- */
                Memory32Fixed (ReadWrite,
                    0xFD7C0000, 0x00010000, , Y_CRU)

                /* ---- PMU (power management unit) ----------------------- */
                Memory32Fixed (ReadWrite,
                    0xFD880000, 0x00010000, , Y_PMU)

                /* ---- RGA3 (2D acceleration engine) -------------------- */
                Memory32Fixed (ReadWrite,
                    0xFDB20000, 0x00001000, , Y_RGA)

                /* ---- RKVDEC (hardware video decoder) — v0.7 ----------- */
                Memory32Fixed (ReadWrite,
                    0xFDBD0000, 0x00001000, , Y_VDEC)

                /* ---- Interrupts (GIC SPI numbers + 32) ----------------- *
                 *
                 *  SPI 85  → 117  : GPU combined IRQ
                 *  SPI 35  → 67   : VOP2 frame IRQ
                 *  SPI 77  → 109  : RGA3 completion IRQ
                 *  SPI 115 → 147  : RKVDEC completion IRQ (v0.7)
                 *
                 * All four are Level-triggered, Active-High, Exclusive. */
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive) { 117 }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive) { 67 }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive) { 109 }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive) { 147 }
            })
            Return (RBUF)
        }

        /* ---- Device-specific data (_DSD) ------------------------------ *
         *
         * The Device Properties UUID (daffd814-...) is the standard
         * ACPI device-property binding; Windows understands it and
         * exposes the properties to the driver via IoGetDevicePropertyData.
         *
         * The "compatible" string is for cross-OS identification:
         * Linux devicetree would use the same string for the same HW.
         */
        Name (_DSD, Package ()
        {
            ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
            Package ()
            {
                Package (2) { "compatible",         "rockchip,rk3588-mali" },
                Package (2) { "arm,mali-arch",      "valhall-v9" },
                Package (2) { "arm,mali-shader-cores", 4 },
                Package (2) { "arm,mali-l2-slices",   1 },
                Package (2) { "rockchip,vop2-version", 0x00080200 },
                Package (2) { "rockchip,rga3-version",  0x00030050 },
            }
        })
    }
}
