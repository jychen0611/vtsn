#!/usr/bin/env bash
set -Eeuo pipefail

KERNEL_DIR="${KERNEL_DIR:-$HOME/kernel-lab/linux}"
GDB_PORT="${GDB_PORT:-1234}"
VMLINUX="$KERNEL_DIR/vmlinux"

if [[ ! -f "$VMLINUX" ]]; then
  echo "ERROR: Missing $VMLINUX. Run scripts/build.sh first." >&2
  exit 1
fi
if ! command -v gdb >/dev/null 2>&1; then
  echo 'ERROR: gdb not found. Install gdb.' >&2
  exit 1
fi

echo "[vTSN] Connecting GDB to QEMU at 127.0.0.1:$GDB_PORT"
exec gdb -q "$VMLINUX" \
  -ex 'set pagination off' \
  -ex "target remote 127.0.0.1:$GDB_PORT" \
  -ex 'break start_kernel' \
  -ex 'continue'
