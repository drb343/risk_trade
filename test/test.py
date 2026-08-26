# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


async def load_word(dut, value, is_config, cfg_sel=0):
    """Load a 32-bit word into the wrapper over 4 bytes, MSB first."""
    for shift in (24, 16, 8, 0):
        byte = (value >> shift) & 0xFF
        dut.ui_in.value = byte
        dut.uio_in.value = (cfg_sel << 2) | (is_config << 1) | 1
        await ClockCycles(dut.clk, 1)
    dut.uio_in.value = (cfg_sel << 2) | (is_config << 1) | 0
    await ClockCycles(dut.clk, 1)


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    dut._log.info("Test project behavior")

    await load_word(dut, 1000, is_config=1, cfg_sel=0)  # ref_price
    await load_word(dut, 50,   is_config=1, cfg_sel=1)  # collar_ticks
    await load_word(dut, 2000, is_config=1, cfg_sel=2)  # diff_threshold

    dut._log.info(f"ref_price_reg={dut.dut1.uut1.ref_price_reg.value}")
    dut._log.info(f"collar_ticks_reg={dut.dut1.uut1.collar_ticks_reg.value}")
    dut._log.info(f"diff_threshold={dut.dut1.uut1.diff_threshold.value}")

    await load_word(dut, 1010, is_config=0)

    dut._log.info(f"price_in_reg={dut.dut1.price_in_reg.value}")
    dut._log.info(f"prev_price={dut.dut1.uut1.prev_price.value}")

    await ClockCycles(dut.clk, 1)

    assert dut.uo_out.value[0] == 1
    assert dut.uo_out.value[1] == 0