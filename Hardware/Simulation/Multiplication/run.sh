set -e

declare -a FILE_LIST=("matmul") 

bash "./build.sh"

for file in ${FILE_LIST[@]};
do
    echo "-- Running: ${file}_O3"
    spike --isa=rv32gcv_zifencei $RISCV/riscv32-unknown-elf/bin/pk ./out/${file}_O3
done
