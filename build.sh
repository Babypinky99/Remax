#!/bin/bash
set -e

KERNEL_DIR="$(pwd)"
CLANG_DIR="/home/venomsnake/Desktop/toolchains/proton-clang"
export PATH="/usr/bin:/bin:${CLANG_DIR}/bin:${PATH}"
export ARCH=arm64
export SUBARCH=arm64
export CC="${CLANG_DIR}/bin/clang"
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-

DEFCONFIG="vendor/sdm670-perf_defconfig"
OUT_DIR="${KERNEL_DIR}/out"
ANYKERNEL_DIR="/home/venomsnake/Desktop/AnyKernel3"
ZIP_NAME="SilverCore-RMX1921-75Hz-KSU-SUSFS.zip"

mkdir -p "${OUT_DIR}"

echo "=================================================="
echo "Compiling SilverCore Kernel for Realme XT (RMX1921)..."
echo "=================================================="

make O="${OUT_DIR}" ${DEFCONFIG} \
    CC="${CLANG_DIR}/bin/clang" \
    HOSTCC=gcc \
    HOSTCXX=g++ \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi-

make -j$(nproc --all) O="${OUT_DIR}" \
    CC="${CLANG_DIR}/bin/clang" \
    HOSTCC=gcc \
    HOSTCXX=g++ \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
    Image.gz-dtb dtbs

echo "Creating dtbo.img..."
python3 "/home/venomsnake/Desktop/toolchains/mkdtboimg.py" \
    create "${OUT_DIR}/arch/arm64/boot/dtbo.img" --page_size=4096 \
    $(find "${OUT_DIR}/arch/arm64/boot/dts/19651" -name "*.dtbo" | sort)

echo "Creating flashable AnyKernel3 zip with kernel + dtbo..."
cd "${ANYKERNEL_DIR}"
rm -f Image.gz-dtb dtbo.img *.zip
cp "${OUT_DIR}/arch/arm64/boot/Image.gz-dtb" .
cp "${OUT_DIR}/arch/arm64/boot/dtbo.img" .

python3 -c '
import os, zipfile
target_zip = "'"${KERNEL_DIR}/${ZIP_NAME}"'"
with zipfile.ZipFile(target_zip, "w", zipfile.ZIP_DEFLATED) as z:
    for root, dirs, files in os.walk("."):
        if ".git" in root: continue
        for f in files:
            if f.endswith(".zip") or f == "README.md" or f.endswith("placeholder"): continue
            fp = os.path.join(root, f)
            arcname = os.path.relpath(fp, ".")
            z.write(fp, arcname)
print("Packed AnyKernel3 zip successfully!")
'

echo "Successfully packed: ${KERNEL_DIR}/${ZIP_NAME} ($(du -h ${KERNEL_DIR}/${ZIP_NAME} | cut -f1))"
echo "=================================================="
echo "Done! Flashable zip: ${KERNEL_DIR}/${ZIP_NAME}"
echo "=================================================="
