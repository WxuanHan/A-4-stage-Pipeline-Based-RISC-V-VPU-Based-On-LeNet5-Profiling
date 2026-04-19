toolchain:
- deps:
    - export RISCV=/opt/riscv
    - export PATH="$PATH:$RISCV/bin"
    - sudo apt-get install autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev device-tree-compiler

- gcc:
    - git clone https://github.com/riscv-collab/riscv-gnu-toolchain
    - cd riscv-gnu-toolchain
    - ./configure --prefix=$RISCV --with-arch=rv32imav_zifencei --with-abi=ilp32 --enable-multilib
    - In makefile set INSTALL_DIR := /opt/riscv
    - sudo make

- pk:
    - rm -rf build && mkdir build && cd build
    - ../configure --prefix=$RISCV --host=riscv32-unknown-elf --with-arch=rv32gcv_zifencei
    - make
    - sudo make install

- spike:
    - rm -rf build && mkdir build && cd build
    - ../configure --prefix=$RISCV --with-isa=rv32gcv_zifencei --enable-histogram
        - Throws warning --enable-histogram not known
    - make
    - sudo make install
    - run as: spike --isa=rv32gcv_zifencei $RISCV/riscv32-unknown-elf/bin/pk test_instr
