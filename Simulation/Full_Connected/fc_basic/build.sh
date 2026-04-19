set -e

if [ -d "./out" ] ; then
    rm -rf ./out
fi

mkdir out
cd out

declare -a SRC_FILE_LIST=("fc_basic") 

for file in ${SRC_FILE_LIST[@]};
do
    riscv32-unknown-elf-gcc -O3 -o ${file}_O3 ../$file.c
    riscv32-unknown-elf-objdump -d ${file}_O3 > ${file}_O3.dump

done

