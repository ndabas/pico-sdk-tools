#!/bin/bash

set -euo pipefail

INSTALLDIR="riscv-install/${MSYSTEM,,}"
rm -rf $INSTALLDIR
mkdir -p $INSTALLDIR

BUILDDIR=$(pwd)

cd riscv-gnu-toolchain
./configure --prefix=$BUILDDIR/$INSTALLDIR --with-arch=rv32ima_zicsr_zifencei_zba_zbb_zbs_zbkb_zca_zcb --with-abi=ilp32 --with-multilib-generator="rv32ima_zicsr_zifencei_zba_zbb_zbs_zbkb_zca_zcb-ilp32--;rv32imac_zicsr_zifencei_zba_zbb_zbs_zbkb-ilp32--"
make -j$(nproc)

cd "$BUILDDIR/$INSTALLDIR"
"$BUILDDIR/../packages/windows/copy-deps.sh"
