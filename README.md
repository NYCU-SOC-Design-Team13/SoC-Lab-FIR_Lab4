# SoC-Lab-FIR_Lab4

Labs to experiment Caravel SoC FPGA module design with Verilog & HLS.

In Lab4, we're running a simple simulation with the Caravel SoC. The process involves uploading firmware into the user project's instruction BRAM (user_bram), then extracting and running these instructions. Additionally, we handle the exchange of data with the process IP in the user project area.

## Toolchain Prerequisites
* [Ubuntu 20.04+](https://releases.ubuntu.com/focal/)
* [Xilinx Vitis 2022.1](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/2022-1.html)
* [iverilog](https://github.com/steveicarus/iverilog)
* [GTKWave v3.3.103](https://gtkwave.sourceforge.net/)
* [RISC-V GCC Toolchains rv32i-4.0.0](https://github.com/stnolting/riscv-gcc-prebuilt)

## Setup Toolchain
* Ubuntu 20.04+
* iverilog, GTKWave and RISC-V GCC Toolchains
```console
$ sudo apt update
$ sudo apt install iverilog  gtkwave git -y
$ sudo wget -O /tmp/riscv32-unknown-elf.gcc-12.1.0.tar.gz https://github.com/stnolting/riscv-gcc-prebuilt/releases/download/rv32i-4.0.0/riscv32-unknown-elf.gcc-12.1.0.tar.gz
$ sudo mkdir /opt/riscv
$ sudo tar -xzf /tmp/riscv32-unknown-elf.gcc-12.1.0.tar.gz -C /opt/riscv
$ echo 'export PATH=$PATH:/opt/riscv/bin' >> ~/.bashrc
$ source ~/.bashrc
```

## Lab4 Source
* Lab4-1: [lab-exmem_fir](https://github.com/bol-edu/caravel-soc_fpga-lab/tree/main/lab-exmem_fir)
* Lab4-2: [lab-caravel_fir](https://github.com/bol-edu/caravel-soc_fpga-lab/tree/main/lab-caravel_fir)

## How to start simulation
1. Enter `Lab4-1/testbench/counter_la_fir/` or `Lab4-2/testbench/counter_la_fir/`
  * `source run_sim` to start simulation
    * Use `gtkwave` to load the waveform file (`*.vcd`) for debuging design
  * `source run_clean` to clean up the simulation results
2. **In Lab4-2, there is a statement in `counter_la_fir_tb.v` should be modified. Change the `out_gold.data` read path.**
