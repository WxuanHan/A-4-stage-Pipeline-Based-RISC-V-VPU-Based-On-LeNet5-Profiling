# Simulation

This directory contains the kernel-level simulation code used to compare scalar and vectorized implementations of representative neural-network operators.

The purpose of this part of the project is to study how RISC-V vectorization changes the computational behavior of selected kernels before they are integrated into the profiling and validation flow.

---

## Overview

The files in this directory are used for operator-level comparison between:
- scalar implementations written in standard C
- vectorized implementations written in RISC-V intrinsic C

The simulation work focuses on representative kernels related to neural-network workloads. These implementations are used to study the effect of vectorization on the number of operations or instructions required by each kernel.

This directory mainly serves as a development and comparison space for individual kernels. The benchmark-style organization used for correctness validation and profiling is provided separately in the sibling directory 'rv_profiler/'.

---

## Directory Structure

This folder is organized into the following subdirectories:

- 'Convolution/' – 2D convolution kernels
- 'Full_Connected/' – fully connected layer kernels
- 'Maxpooling/' – max-pooling kernels
- 'Multiplication/' – matrix multiplication kernels

Each subdirectory contains scalar and vectorized versions of the corresponding kernel.

---

## Simulation Scope

The simulation code in this folder focuses on representative neural-network operators, including:
- 2D convolution
- fully connected computation
- max pooling
- matrix multiplication

For each operator, the main goal is to compare:
- a scalar implementation
- a vectorized implementation based on RISC-V vector intrinsics

The scalar implementation is intended to serve as a baseline, while the vectorized version is used to study the effect of data-level parallelism on the kernel.

---

## Scalar and Vectorized Implementations

The implementations in this directory follow two styles:

- scalar versions written in standard C
- vectorized versions written in RISC-V intrinsic C

The scalar versions are used as reference baselines for conventional operation flow. The vectorized versions are used to explore how representative neural-network kernels can be expressed using RISC-V vector operations.

At this level, the focus is not on final benchmark packaging, but on kernel behavior and implementation comparison.

---

## Role in the Overall Project

This directory represents the kernel-development side of the project.

The typical workflow is:
1. implement or refine a scalar version of a kernel
2. implement the corresponding vectorized version using RISC-V intrinsics
3. compare the scalar and vectorized forms at the operator level
4. migrate or integrate the kernel logic into the benchmark structure inside 'rv_profiler/' for correctness validation and profiling

In other words, this folder is mainly used for kernel-level comparison, while 'rv_profiler/' is used for benchmark-level validation and profiling.

---

## Relationship to 'rv_profiler/'

The 'Simulation/' and 'rv_profiler/' directories are closely related, but they serve different purposes.

- 'Simulation/'  
  contains the kernel-level scalar and vectorized implementations used for algorithm and operator comparison

- 'rv_profiler/'  
  contains the structured benchmark versions, together with deterministic data files, used for correctness checking, profiling, and result generation

The kernel logic developed in this directory is later integrated into the benchmark framework in 'rv_profiler/'.

---

## Design Focus

The simulation code in this directory is mainly intended to:
- compare scalar and vectorized implementations at the kernel level
- observe reductions in operations or instruction counts enabled by vectorization
- prepare kernel logic for later integration into the profiling flow
- provide a simpler code-level view of the main operators before full benchmark packaging

This makes the directory useful for understanding the algorithmic side of the project before moving on to validation, profiling, and hardware-related design.

---

## Notes

This folder contains kernel-level simulation code only.  
For benchmark-oriented validation and profiling, please refer to:
- '../rv_profiler/'

For the RTL implementation and hardware verification files, please refer to:
- '../Hardware/'
