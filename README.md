# risk_trade

![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

Fault-tolerant pre-trade risk engine with TMR (Triple Modular Redundancy), hardened via the TinyTapeout Sky130 ASIC flow.

## Fault Detection Simulation Run

Have a decision 0, decision 1, and then a decision 1 but with an injected error, causing TMR to still have 2/3 majority vote for 1:

<img width="262" height="78" alt="image" src="https://github.com/user-attachments/assets/120647d7-7014-43c9-99a9-c53fc9ef60bb" />

## About Tiny Tapeout

This project is built on the [Tiny Tapeout](https://tinytapeout.com) Verilog template, which uses [LibreLane](https://www.zerotoasiccourse.com/terminology/librelane/) via GitHub Actions to build the ASIC files against the Sky130 PDK.

- [Read the documentation for this project](docs/info.md)
- [FAQ](https://tinytapeout.com/faq/)
- [Digital design lessons](https://tinytapeout.com/digital_design/)
