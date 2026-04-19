# a-4-stage-pipeline-based-RISC-V-VPU-based-on-LeNet5-profiling
This is a RISC-V VPU project based on a 4-stage pipeline.

## Overview

This project performed RTL and microarchitectural optimization on a 32-bit lane-based RISC-V VPU for Xilinx FPGAs. Based on instruction profiling of vectorized LeNet-5 kernels using Spike simulator, restructured the original 2-stage in-order design into a 4-stage  fetch/decode/execute/memory-writeback pipeline and refined decode, control, and execution paths for hotspot operations. Verified functionality with testbenches and assessed timing, resource utilization, power, and Fmax through synthesis and implementation, improving maximum operating frequency by 2.1×.
