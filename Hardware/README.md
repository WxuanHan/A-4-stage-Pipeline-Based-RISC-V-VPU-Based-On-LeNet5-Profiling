# Hardware

This directory contains the hardware implementation of the optimized 4-stage pipeline-based RISC-V Vector Processing Unit (VPU).

The hardware part of this project focuses on restructuring an existing embedded VPU architecture into a more modular 4-stage pipeline consisting of:
- Fetch
- Decode
- Execute
- Memory/Writeback

The implementation is written in SystemVerilog RTL and includes supporting definition files, functional modules, testbenches, and a hardware-oriented architecture description document.

---

## Directory Structure

This folder is organized into the following subdirectories:

- 'include/' – shared definitions, constants, and instruction-format related files
- 'rtl/' – main RTL implementation of the VPU
- 'test_bench/' – SystemVerilog testbenches for functional verification

In addition, this directory also contains:

- 'VPU_Module_Description.pdf' – functional and architectural description of the VPU modules

---

## Overview

The hardware design in this repository reflects the architectural optimization of a RISC-V embedded VPU from an original 2-stage organization into a 4-stage pipeline. The purpose of this redesign is to improve:
- modularity
- dataflow clarity
- control organization
- timing behavior
- overall hardware scalability

In addition to pipeline restructuring, the design separates key functions into more explicit modules, such as execution control, vector register handling, arithmetic processing, and memory/writeback coordination.

---

## 'include/'

The 'include/' directory contains shared files used across the RTL design.

These files typically provide:
- common definitions
- type and structure declarations
- instruction format descriptions
- configuration-related constants

This directory helps keep the RTL modules consistent and avoids duplication of shared declarations across the design.

---

## 'rtl/'

The 'rtl/' directory contains the main SystemVerilog implementation of the VPU.

At a high level, the RTL includes:
- top-level VPU integration
- pipeline stage modules
- execution control logic
- lane-level data processing modules
- arithmetic and multiplier units
- vector register handling
- load/store and memory/writeback support

Representative RTL modules include:
- top-level core integration
- fetch stage
- decode stage
- execute stage
- memory/writeback stage
- execution controller
- lane and lane controller
- vector register file
- arithmetic unit
- ALU
- multiplier
- load/store unit

Together, these modules implement the optimized 4-stage VPU architecture used in this project.

---

## 'test_bench/'

The 'test_bench/' directory contains SystemVerilog testbenches used to verify the hardware modules.

These testbenches support:
- module-level functional checking
- stage-level validation
- top-level integration checking of the VPU core

The verification files help confirm that the redesigned pipeline stages and supporting modules behave as expected before and during hardware evaluation.

---

## Documentation

This directory also contains:

- 'VPU_Module_Description.pdf'

This document provides a functional and architectural description of the VPU modules and can be used as a reference when reading the RTL implementation. It is intended to support understanding of the major hardware blocks, pipeline-stage responsibilities, and module-level organization of the design.

A recommended reading order for this directory is:
1. 'README.md'
2. 'VPU_Module_Description.pdf'
3. 'include/'
4. 'rtl/'
5. 'test_bench/'

---

## Design Goals

The hardware implementation is intended to support:
- clearer separation between pipeline stages
- improved execution control organization
- better lane-level modularity
- more explicit handling of vector register and memory interactions
- easier debugging and maintainability

This directory therefore serves as the main hardware source tree for the RTL-based VPU implementation.

---

## Notes

This folder contains the hardware source files and supporting hardware documentation. For the software-side scalar/vector benchmark comparison and profiling-related validation flow, please refer to the sibling directories:
- '../Simulation/'
- '../rv_profiler/'
