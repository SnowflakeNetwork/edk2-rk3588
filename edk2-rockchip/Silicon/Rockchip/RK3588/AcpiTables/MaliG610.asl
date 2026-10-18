/** @file
 *
 *  Mali-G610 MC4 GPU for RK3588/RK3588S.
 *
 *  Values taken from the upstream Linux rk3588s.dtsi:
 *    gpu@fb000000  reg 0xfb000000 0x200000
 *                  interrupts SPI 92 (job), SPI 93 (mmu), SPI 94 (gpu)
 *    vop@fdd90000  reg 0xfdd90000 0x4200, gamma-lut 0xfdd95000 0x1000
 *                  interrupt SPI 156
 *    rga@fdb60000  (RGA3 core0) reg 0xfdb60000 0x1000, SPI 114
 *
 *  ACPI interrupt number = GIC SPI + 32.
 *
 *  Resource order (driver must index in this order):
 *    Mem 0  GPU        Int 0  GPU job
 *    Mem 1  VOP2       Int 1  GPU mmu
 *    Mem 2  VOP2 LUT   Int 2  GPU gpu
 *    Mem 3  RGA3       Int 3  VOP2
 *                      Int 4  RGA3
 *
 *  Copyright (c) 2024, Open Source Mali-WOA Project
 *
 *  SPDX-License-Identifier: BSD-2-Clause-Patent
 *
 **/
#include "AcpiTables.h"

  Device (GPU0) {
    Name (_HID, "ARMF5100")
    Name (_UID, 0)
    Name (_CCA, 0)

    Method (_STA) {
      Return (0xF)
    }

    Method (_CRS, 0x0, Serialized) {
      Name (RBUF, ResourceTemplate() {
        // Mali-G610
        Memory32Fixed (ReadWrite, 0xfb000000, 0x200000)
        // VOP2
        Memory32Fixed (ReadWrite, 0xfdd90000, 0x4200)
        // VOP2 gamma LUT
        Memory32Fixed (ReadWrite, 0xfdd95000, 0x1000)
        // RGA3 core0
        Memory32Fixed (ReadWrite, 0xfdb60000, 0x1000)

        Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive) { 124 } // GPU job
        Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive) { 125 } // GPU mmu
        Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive) { 126 } // GPU gpu
        Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive) { 188 } // VOP2
        Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive) { 146 } // RGA3 core0
      })
      Return (RBUF)
    }

    Name (_DSD, Package () {
      ToUUID("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
      Package () {
        Package (2) { "compatible", Package () { "rockchip,rk3588-mali", "arm,mali-valhall-csf" } },
        Package (2) { "interrupt-names", Package () { "job", "mmu", "gpu", "vop", "rga" } },
      }
    })
  }
