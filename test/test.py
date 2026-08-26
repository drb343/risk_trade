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
        # uio_in[0]=byte_valid, [1]=is_config, [3:2]=cfg_sel
        dut.uio_in.value = (cfg_sel << 2) | (is_config << 1) | 1
        await ClockCycles(dut.clk, 1)
    # deassert byte_valid after the load
    dut.uio_in.value = (cfg_sel << 2) | (is_config << 1) | 0
    await ClockCycles(dut.clk, 1)


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    dut._log.info("Test project behavior")

    # TODO: confirm cfg_sel encoding against risk_core_check.v
    # (which select value maps to ref_price_reg / collar_ticks_reg / diff_threshold)
    await load_word(dut, 1000, is_config=1, cfg_sel=0)  # e.g. ref_price
    await load_word(dut, 50,   is_config=1, cfg_sel=1)  # e.g. collar_ticks
    await load_word(dut, 100,  is_config=1, cfg_sel=2)  # e.g. diff_threshold

    # Load a price that should pass collar + velocity checks
    await load_word(dut, 1010, is_config=0)

    # Wait a cycle for tmr_decision/fault_detected to settle
    await ClockCycles(dut.clk, 1)

    assert dut.uo_out.value[0] == 1  # tmr_decision: trade accepted
    assert dut.uo_out.value[1] == 0  # fault_detected: no fault
