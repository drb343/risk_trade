
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


async def load_word(dut, value, is_config, cfg_sel=0):
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

    await load_word(dut, 1000, is_config=1, cfg_sel=0)
    await load_word(dut, 50,   is_config=1, cfg_sel=1)
    await load_word(dut, 2000, is_config=1, cfg_sel=2)

    # re-assert ref_price and collar last, since diff_threshold write
    # can still clobber them under the wrapper's current config_we timing
    await load_word(dut, 1000, is_config=1, cfg_sel=0)
    await load_word(dut, 50,   is_config=1, cfg_sel=1)

    # In the gate level netlist, these 3 components don't exist, but they exist in the RTL sim, so we aren't worried about these not passing
    try:
        dut._log.info(f"ref_price_reg={dut.user_project.dut1.uut1.ref_price_reg.value}")
        dut._log.info(f"collar_ticks_reg={dut.user_project.dut1.uut1.collar_ticks_reg.value}")
        dut._log.info(f"diff_threshold={dut.user_project.dut1.uut1.diff_threshold.value}")
    except AttributeError:
        pass

    await load_word(dut, 1010, is_config=0)

    #These 2 exist in the RTL sim, just not in the gate level netlist (variable name not preserved during synthesis)
    try:
        dut._log.info(f"price_in_reg={dut.user_project.price_in_reg.value}")
        dut._log.info(f"prev_price={dut.user_project.dut1.uut1.prev_price.value}")
    except AttributeError:
        pass

    await ClockCycles(dut.clk, 1)

    assert dut.uo_out.value[0] == 1
    assert dut.uo_out.value[1] == 0