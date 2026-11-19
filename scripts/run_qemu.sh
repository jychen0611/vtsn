#!/usr/bin/env bash
set -Eeuo pipefail

KERNEL_DIR="${KERNEL_DIR:-$HOME/kernel-lab/linux}"
INITRAMFS="${INITRAMFS:-$HOME/kernel-lab/initramfs.cpio.gz}"
GDB_PORT="${GDB_PORT:-1234}"
KERNEL_IMAGE="$KERNEL_DIR/arch/x86/boot/bzImage"

for file in "$KERNEL_IMAGE" "$INITRAMFS"; do
  if [[ ! -f "$file" ]]; then
    echo "ERROR: Missing file: $file" >&2
    exit 1
  fi
done

if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
  echo 'ERROR: qemu-system-x86_64 not found. Install qemu-system-x86.' >&2
  exit 1
fi

echo "[vTSN] Starting QEMU (GDB TCP port $GDB_PORT)"
echo '[vTSN] CPU is paused until GDB continues execution.'
echo '[vTSN] To exit QEMU: Ctrl+A, then X.'
exec qemu-system-x86_64 \
  -machine q35 \
  -m 2048 \
  -smp 2 \
  -kernel "$KERNEL_IMAGE" \
  -initrd "$INITRAMFS" \
  -append 'console=ttyS0 nokaslr' \
  -nographic \
  -gdb "tcp:127.0.0.1:$GDB_PORT" \
  -S
