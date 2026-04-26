# rv_profiler

This directory contains the benchmark framework used for correctness validation, instruction profiling, and result generation.

Compared with the kernel-level implementations in 'Simulation/', this directory provides a more structured benchmark organization. It combines benchmark source files, configuration variants, and deterministic data sets so that scalar and vectorized implementations can be validated and analyzed within a consistent profiling flow.

---

## Overview

The primary purpose of this directory is to support:
- correctness validation of benchmark implementations
- structured organization of scalar and vectorized benchmark variants
- instruction-level profiling across multiple benchmark configurations
- generation of benchmark-level comparison results

The benchmark logic used here is closely related to the operator implementations developed in 'Simulation/'. In practice, the kernel implementations from 'Simulation/' are integrated into the benchmark structure in this directory, where they are combined with benchmark-specific data files and configuration variants.

---

## Directory Organization

This directory contains benchmark-specific folders together with profiling-related helper files.

Each benchmark folder typically includes:
- a scalar baseline implementation
- vectorized implementations for multiple element widths
- deterministic data files used for validation

A typical benchmark directory contains files such as:
- '*_base.c'
- '*_v_vec8.c'
- '*_v_vec16.c'
- '*_v_vec32.c'
- '*_data_base.c'
- '*_data_v_vec8.c'
- '*_data_v_vec16.c'
- '*_data_v_vec32.c'

This organization allows the same workload to be evaluated under:
- a scalar baseline
- an 8-bit vectorized configuration
- a 16-bit vectorized configuration
- a 32-bit vectorized configuration

---

## Benchmarks Covered

This directory is organized around representative workloads used throughout the project, including:
- matrix multiplication
- 2D convolution
- fully connected computation
- max pooling
- LeNet-5

The profiling flow explicitly operates on benchmark/configuration combinations such as:
- 'matmul256'
- 'conv256'
- 'fc1024'
- 'maxpooling256'
- 'mlenet5'

under configurations such as:
- 'base'
- 'v_vec8'
- 'v_vec16'
- 'v_vec32'

---

## Role of 'common.h'

The file 'common.h' serves as the shared benchmark configuration header for this profiling framework. It centralizes the workload dimensions and benchmark parameters used across multiple source files, ensuring that all scalar, vectorized, and data-bearing variants are built against a consistent set of problem definitions.

In particular, 'common.h' defines the benchmark sizes used in this directory, including:
- 'MATMUL_SIZE 256'
- 'CONV_IN_SIZE 256'
- 'MAXPOOL_IN_SIZE 256'
- 'FC_IN_SIZE 1024'
- 'FC_OUT_SIZE 1024'

Because these parameters are shared globally, 'common.h' plays an important role in:
- keeping benchmark variants consistent
- aligning scalar and vectorized implementations
- ensuring that validation data matches the expected workload dimensions
- simplifying maintenance when benchmark sizes or common constants need to be updated

---

## Naming Convention

The benchmark names encode both workload type and configuration.

### Benchmark prefixes

- 'matmul256' – matrix multiplication benchmark with problem size 256
- 'conv256' – convolution benchmark with input size 256
- 'maxpooling256' – max-pooling benchmark with input size 256
- 'fc1024' – fully connected benchmark with input and output size 1024
- 'mlenet5' – LeNet-5 benchmark

These names are consistent with the shared benchmark parameters defined in 'common.h'.

### Configuration suffixes

- 'base' – scalar baseline implementation
- 'v_vec8' – vectorized implementation using 8-bit elements
- 'v_vec16' – vectorized implementation using 16-bit elements
- 'v_vec32' – vectorized implementation using 32-bit elements

The vectorized source files reflect these element widths directly. For example, the convolution vector variants use width-specific integer data types and RVV intrinsics specialized for the selected element width.

Taken together, the naming scheme distinguishes:
- the benchmark problem size, indicated by values such as '256' and '1024'
- the vector element width, indicated by values such as '8', '16', and '32'

---

## Why Are Most Benchmarks Labeled '256' While the Fully Connected Benchmark Is '1024'?

This naming difference reflects the underlying structure of the workloads rather than an inconsistency in the benchmark framework.

For convolution, matrix multiplication, and max pooling, the workload is naturally described by spatial size or matrix dimension. As a result, these benchmarks are labeled using '256', which corresponds to the size parameters defined in 'common.h', such as 'CONV_IN_SIZE 256', 'MATMUL_SIZE 256', and 'MAXPOOL_IN_SIZE 256'.

The fully connected benchmark follows a different convention because its most natural scaling parameter is not a spatial dimension but the input/output feature dimension. In this project, the fully connected workload is defined by 'FC_IN_SIZE 1024' and 'FC_OUT_SIZE 1024', so the benchmark is labeled 'fc1024'.

This distinction is also reflected in the summary plotting logic, where the benchmarks are represented in forms such as:
- convolution with a 256-scale input setting
- fully connected computation as '1024->1024'
- matrix multiplication with 256-scale matrix dimensions
- max pooling with a 256-scale input setting

In other words:
- '256' is used where the benchmark is naturally characterized by an input size or matrix dimension
- '1024' is used for the fully connected benchmark because its natural scale is the feature dimension of the layer

---

## Correctness Validation

A central role of this directory is correctness validation.

Each benchmark variant is paired with deterministic data files that provide:
- benchmark inputs
- weights or other workload-specific parameters
- expected output references

By combining the benchmark source files with these deterministic data sets, both scalar and vectorized implementations can be checked against known reference outputs before profiling data is used for comparative analysis.

This validation step is essential because it ensures that instruction-count comparisons are based on functionally correct implementations rather than incomplete or mismatched benchmark variants.

---

## Profiling Workflow

Once correctness has been established, the benchmark outputs are used in the profiling flow.

The profiling process includes:
- collecting histogram or execution-related outputs
- isolating the relevant benchmark code region
- mapping instruction addresses to instruction names
- aggregating instruction counts
- exporting CSV summaries
- generating benchmark-level comparison plots

This directory therefore serves as the bridge between kernel implementation and quantitative evaluation.

---

## Relationship to the Profiling Scripts

The profiling flow is supported by helper scripts in the project, including:
- 'filter_his.py'
- 'create_data.py'
- 'plot_summary.py'

Their roles can be summarized as follows:

- 'filter_his.py'  
  filters histogram data so that only the relevant benchmark code range is retained

- 'create_data.py'  
  maps instruction addresses to instruction names, aggregates instruction counts, exports CSV summaries, and generates per-benchmark histograms

- 'plot_summary.py'  
  builds the final benchmark-level comparison plot across 'base', 'vec32', 'vec16', and 'vec8', and labels the benchmark categories used in the evaluation summary figure

These scripts operate on the benchmark structure provided in this directory.

---

## Relationship to 'Simulation/'

The 'Simulation/' and 'rv_profiler/' directories are closely related, but they serve different purposes.

- 'Simulation/'  
  focuses on kernel-level scalar and vectorized implementations for operator-level comparison

- 'rv_profiler/'  
  focuses on structured benchmark packaging, deterministic validation, profiling, and result generation

The kernel logic developed in 'Simulation/' is integrated into the benchmark framework here for validation and profiling.

---

## Design Intent

This directory is intended to:
- provide a structured benchmark framework
- support deterministic correctness checking
- package scalar and vectorized variants consistently
- enable profiling-driven comparison across workload types and element widths
- connect kernel development with benchmark-level evaluation

As a result, this directory plays a central role in translating individual kernel implementations into reproducible and measurable benchmark results.

---

## Notes

This folder contains benchmark-oriented validation and profiling files.

For kernel-level scalar/vector implementation comparison, please refer to:
- '../Simulation/'

For RTL implementation and hardware verification, please refer to:
- '../Hardware/'
