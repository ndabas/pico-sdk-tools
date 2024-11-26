#!/bin/bash

set -euo pipefail

# Defaults
SKIP_RISCV=${SKIP_RISCV-0}
SKIP_OPENOCD=${SKIP_OPENOCD-0}

# Install prerequisites
/usr/local/bin/brew install jq libtool libusb automake hidapi --quiet
# RISC-V prerequisites
echo "Listing local"
ls /usr/local/bin
rm /usr/local/bin/2to3*
rm /usr/local/bin/idle3*
rm /usr/local/bin/pip*
rm /usr/local/bin/py*
/usr/local/bin/brew install python3 gawk gnu-sed gmp mpfr libmpc isl zlib expat texinfo flock libslirp --quiet

repos=$(cat config/repositories.json | jq -c '.repositories.[]')
export version=$(cat ./version.txt)
suffix="mac"
builddir="build"

# nproc alias
alias nproc="sysctl -n hw.logicalcpu"

mkdir -p $builddir
mkdir -p "bin"

while read -r repo
do
    tree=$(echo "$repo" | jq -r .tree)
    href=$(echo "$repo" | jq -r .href)
    filename=$(basename -- "$href")
    extension="${filename##*.}"
    filename="${filename%.*}"
    filename=${filename%"-rp2350"}
    repodir="$builddir/${filename}"

    echo "${href} ${tree} ${filename} ${extension} ${repodir}"
    rm -rf "${repodir}"
    git clone -b "${tree}" --depth=1 -c advice.detachedHead=false "${href}" "${repodir}" 
done < <(echo "$repos")


cd $builddir
if [[ "$SKIP_OPENOCD" != 1 ]]; then
    if ! ../packages/macos/openocd/build-openocd.sh; then
        echo "OpenOCD Build failed"
        SKIP_OPENOCD=1
    fi
fi
if [[ "$SKIP_RISCV" != 1 ]]; then
    # Takes ages to build
    ../packages/macos/riscv/build-riscv-gcc.sh
fi
cd ..

topd=$PWD
if [[ "$SKIP_OPENOCD" != 1 ]]; then
    # Package OpenOCD separately as well

    version=($("./$builddir/openocd-install/usr/local/bin/openocd" --version 2>&1))
    version=${version[0]}
    version=${version[3]}
    version=$(echo $version | cut -d "-" -f 1)

    echo "OpenOCD version $version"

    filename="openocd-${version}-x64-${suffix}.zip"

    echo "Saving OpenOCD package to $filename"
    pushd "$builddir/openocd-install/usr/local/bin"
    tar -a -cf "$topd/bin/$filename" * -C "../share/openocd" "scripts"
    popd
fi

if [[ "$SKIP_RISCV" != 1 ]]; then
    # Package riscv toolchain separately as well
    version="14"
    echo "Risc-V Toolchain version $version"

    filename="riscv-toolchain-${version}-x64-${suffix}.zip"

    echo "Saving RISC-V Toolchain package to $filename"
    pushd "$builddir/riscv-install/"
    tar -a -cf "$topd/bin/$filename" *
    popd
fi
