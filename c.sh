#!/bin/bash

#=============================#
#        CONFIG SECTION       #
#=============================#

# Set kernel directory to current working directory
KERNEL_DIR="$(pwd)"

# Set output directory for the build
OUT_DIR="$KERNEL_DIR/out"

# Path to compiled kernel image directory
KERNEL_IMAGE_DIR="$OUT_DIR/arch/arm64/boot"

# Path to kernel image
KERNEL_IMAGE="$KERNEL_IMAGE_DIR/Image.gz-dtb"

# Path to clang
CLANGDIR="/workspaces/Remax/clang"

# Codename device
CODENAME="RMX1851"

# Defconfig file for building
CONFIG_NAME="rmx1851_defconfig"

# AnyKernel3 repository and branch
ANYKERNEL_REPO="https://github.com/Babypinky99/AnyKernel3"
ANYKERNEL_BRANCH="$CODENAME"
ANYKERNEL_DIR="$KERNEL_DIR/AnyKernel3"

# Kernel flashable file name
KERNEL_FLASH_NAME="REMUX-RESUKI_$CODENAME"

# Kernel source branch and latest commit id
KERNEL_BRANCH=$(git rev-parse --abbrev-ref HEAD)
KERNEL_COMMIT_ID=$(git rev-parse --short=7 HEAD)

#=============================#
#         START BUILD         #
#=============================#

# Export environment variables for kernel build
export KBUILD_BUILD_USER=Super
export KBUILD_BUILD_HOST=Me
export PATH="$CLANGDIR/bin:$PATH"

# Clean up previous build
rm -f "$LOG_FILE"
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

# Generate defconfig
make O="$OUT_DIR" ARCH=arm64 "$CONFIG_NAME"

# Compile the kernel
make -j"$(nproc --all)" \
    O="$OUT_DIR" \
    ARCH=arm64 \
    CC=clang \
    LD=ld.lld \
    AR=llvm-ar \
    AS=llvm-as \
    NM=llvm-nm \
    OBJCOPY=llvm-objcopy \
    OBJDUMP=llvm-objdump \
    OBJSIZE=llvm-size \
    READELF=llvm-readelf \
    STRIP=llvm-strip \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_COMPAT=arm-linux-gnueabi- 2>&1 | tee -a "$LOG_FILE"

#=============================#
#     CREATE FLASHABLE ZIP    #
#=============================#

# If kernel image exists, package it
if [ -f "$KERNEL_IMAGE" ]; then

    # Clone AnyKernel3 if it doesn't exist
    if [ ! -d "$ANYKERNEL_DIR" ]; then
        git clone "$ANYKERNEL_REPO" "$ANYKERNEL_DIR"
    fi

    # Ensure correct branch
    cd "$ANYKERNEL_DIR"
    git fetch origin
    git checkout "$ANYKERNEL_BRANCH"
    cd "$KERNEL_DIR"

    # Copy compiled kernel image to AnyKernel
    cp "$KERNEL_IMAGE" "$ANYKERNEL_DIR/Image.gz-dtb"

    # Create flashable zip
    cd "$ANYKERNEL_DIR"
    ZIP_NAME="${KERNEL_FLASH_NAME}-$(date +%Y%m%d)-${KERNEL_COMMIT_ID}.zip"
    zip -r9 "../$ZIP_NAME" ./* > /dev/null
    cd "$KERNEL_DIR"
    fi
