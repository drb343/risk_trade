<!---
-->

## How it works

This project implements a triple-modular-redundant pre-trade risk engine. A price, ref_price, collar_ticks, and diff_threshold are fed into `risk_core_check.v`, which accepts the trade if the price falls within `ref_price ± collar_ticks` and the change from the previous accepted price does not exceed `diff_threshold`.

`risk_engine.v` instantiates three independent copies of `risk_core_check.v`, each evaluating the same inputs in parallel. Their three decisions are fed into `tmr_voter.v`, which outputs the majority decision. If any one of the three replicas disagrees (due to a glitch, bit flip, or injected fault), the voter still outputs the correct majority decision and raises a `fault_detected` flag to signal that a mismatch occurred.

This TMR logic was validated with a fault-injection testbench (forcing a bit flip on one replica's internal state) to confirm the voter masks the fault and the correct decision is still produced.

Because TinyTapeout only exposes 8 dedicated input pins, `tt_um_risk_trade.v` wraps the design with a byte-serial loading protocol: 32-bit price and configuration words are shifted in over `ui_in` four bytes at a time (MSB first), with `uio_in` carrying control signals (byte-valid strobe, config-vs-price select, config register select).

The design was synthesized and hardened through TinyTapeout's Sky130 OpenLane flow via GitHub Actions CI.

## How to test

Reset the design (`rst_n` low, then high). To load a configuration word (e.g. `ref_price`, `collar_ticks`, or `diff_threshold`), drive 4 bytes MSB-first on `ui_in`, one per clock cycle, while holding `uio_in[1]` (is_config) high and `uio_in[3:2]` set to the target register (0=ref_price, 1=collar_ticks, 2=diff_threshold), pulsing `uio_in[0]` (byte_valid) high on each byte. Hold `is_config` one extra cycle after the fourth byte with `byte_valid` low to complete the write.

To load a price, repeat the same 4-byte sequence with `uio_in[1]` held low instead.

After a price load completes, `uo_out[0]` reflects the trade decision (1 = accepted) and `uo_out[1]` reflects `fault_detected` (1 = a TMR replica disagreed and was outvoted).

See `test/test.py` for a working cocotb example of this load sequence.

## External hardware

N/A
