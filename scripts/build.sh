#!/usr/bin/env bash
set -Eeuo pipefail

KERNEL_DIR="${KERNEL_DIR:-$HOME/kernel-lab/linux}"
JOBS="${JOBS:-$(nproc)}"

if [[ ! -f "$KERNEL_DIR/Makefile" || ! -x "$KERNEL_DIR/scripts/config" ]]; then
  echo "ERROR: Kernel source not found at $KERNEL_DIR" >&2
  echo "Set KERNEL_DIR=/path/to/linux if necessary." >&2
  exit 1
fi

cd "$KERNEL_DIR"
if [[ ! -f .config ]]; then
  echo '[vTSN] Creating x86_64 default configuration'
  make x86_64_defconfig
fi

# Enable debugging features for QEMU/GDB. Disable BTF to avoid extra pahole dependencies.
scripts/config --enable DEBUG_INFO \
               --enable DEBUG_INFO_DWARF5 \
               --disable DEBUG_INFO_BTF \
               --enable GDB_SCRIPTS \
               --enable FRAME_POINTER
make olddefconfig

echo "[vTSN] Building bzImage and vmlinux with $JOBS jobs"
make -j"$JOBS" bzImage vmlinux

echo '[vTSN] Build complete:'
ls -lh arch/x86/boot/bzImage vmlinux
