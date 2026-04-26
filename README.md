# A-4-stage-Pipeline-Based-RISC-V-VPU-Based-On-LeNet5-Profiling

This repository contains a project on optimizing the dataflow of a RISC-V Vector Processing Unit (VPU) through both software-level simulation and hardware redesign.

The project combines:
- a **simulation study** for comparing scalar and vectorized implementations of representative neural-network kernels
- a **hardware implementation** of an optimized **4-stage pipeline-based RISC-V VPU** in SystemVerilog RTL

This repository serves as a backup and reference archive for the project source files, including benchmark kernels, profiling and validation code, RTL implementation, testbenches, and supporting documentation.

---

## Overview

This project focuses on a 32-bit lane-based RISC-V VPU for Xilinx FPGAs. Based on profiling of vectorized LeNet-5-related kernels using the Spike simulator, the original 2-stage in-order design was restructured into a 4-stage fetch/decode/execute/memory-writeback pipeline, with refinements to decode, control, and execution paths for hotspot operations. The design was functionally checked with testbenches and evaluated through hardware implementation flows.

---

## Repository Structure

At the top level, the repository contains three main folders and one overview 'README.md':

- 'Hardware/'  
  SystemVerilog hardware implementation of the optimized 4-stage VPU, including RTL, testbenches, and hardware-oriented documentation

- 'Simulation/'  
  Scalar and vectorized kernel implementations used for operator-level comparison

- 'rv_profiler/'  
  Benchmark and data organization used for correctness validation and profiling

- 'README.md'  
  Top-level project overview

---

## Folder Guide

### 'Hardware/'

The 'Hardware/' folder contains the SystemVerilog hardware implementation of the optimized 4-stage VPU, together with testbenches and hardware-oriented documentation. It is organized into:

- 'include/'
- 'rtl/'
- 'test_bench/'

This part contains the RTL implementation of the optimized VPU, including pipeline stages, control logic, lane-level processing modules, arithmetic units, and verification testbenches. The hardware-related functional/module description document is also placed in this folder.

### 'Simulation/'

The 'Simulation/' folder contains kernel-level source code used for scalar-versus-vector comparison. It is organized into:

- 'Convolution/'
- 'Full_Connected/'
- 'Maxpooling/'
- 'Multiplication/'

In this folder, the key comparison targets are the scalar and vectorized implementations of representative kernels. The scalar versions are written in standard C, while the vectorized versions are written in RISC-V intrinsic C. These files are used to compare the computational behavior of scalar and vectorized implementations, especially in terms of operation or instruction reduction.

### 'rv_profiler/'

The 'rv_profiler/' folder contains the benchmark organization used for validation and profiling. Each benchmark folder contains:
- baseline source files
- vectorized source files for different element widths
- corresponding data files

For example, a benchmark directory contains files such as:
- '*_base.c'
- '*_v_vec8.c'
- '*_v_vec16.c'
- '*_v_vec32.c'
- '*_data_base.c'
- '*_data_v_vec8.c'
- '*_data_v_vec16.c'
- '*_data_v_vec32.c'

These files are used to validate correctness and support profiling. In practice, the kernel logic developed in 'Simulation/' is integrated into the benchmark structure here, together with deterministic data files, so that baseline and vectorized implementations can be checked against expected outputs before profiling results are analyzed.

---

## Project Workflow

The project can be understood in two connected stages:

### 1. Kernel-Level Simulation

Representative kernels are first implemented in scalar C and RISC-V intrinsic C vectorized versions. These implementations are used to study the effect of vectorization on representative neural-network operators such as:
- 2D convolution
- fully connected computation
- max pooling
- matrix multiplication

The purpose of this stage is to compare scalar and vectorized implementations at the kernel level and observe the reduction in operations or instruction counts enabled by vectorization.

### 2. Profiling and Validation

After the kernel logic is prepared, it is integrated into the benchmark structure inside 'rv_profiler/', together with benchmark-specific data files.

These data files are used for:
- correctness checking of baseline and vectorized implementations
- deterministic validation of outputs
- profiling and post-processing of instruction statistics

The profiling flow is supported by helper scripts that:
- filter histogram outputs to the relevant benchmark address range
- map histogram addresses to instruction names
- aggregate instruction counts
- generate CSV summaries and plots

The profiling scripts include:
- 'filter_his.py' for filtering histogram data to the selected benchmark code range
- 'create_data.py' for mapping addresses to instruction names and exporting CSV and histogram plots
- 'plot_summary.py' for building the final benchmark-level comparison plot across 'base', 'vec32', 'vec16', and 'vec8'

---

## Hardware Summary

The hardware part of the project redesigns an existing embedded VPU into a 4-stage pipeline:
- Fetch
- Decode
- Execute
- Memory/Writeback

The redesign emphasizes:
- improved modularity
- clearer execution control
- better lane-level organization
- explicit separation of key functions such as execution control and vector register handling

The hardware implementation was evaluated through implementation flows targeting Xilinx FPGA platforms, with analysis covering timing, power, and resource utilization.

---

## Suggested Reading Order

For a quick overview of the project, the recommended reading order is:

1. 'README.md'  
   for the overall project structure

2. 'Simulation/'  
   for kernel-level scalar/vector comparison

3. 'rv_profiler/'  
   for validation and profiling-oriented benchmark organization

4. 'Hardware/'  
   for RTL implementation, testbenches, and hardware-oriented documentation

---

## Tools and Technologies

This project involves:
- C
- RISC-V intrinsic C
- Python
- SystemVerilog RTL
- Spike simulator with RISC-V vector-extension support
- Vivado 2023.2
- Xilinx FPGA platform

---

## Notes

This repository is intended as a project backup and reference archive. It contains source files and supporting artifacts related to profiling-driven simulation and hardware redesign for a RISC-V VPU optimization project.
