#!/bin/bash
set -eu

DIR=/mnt/raid-lab
SIZE_MB=512

if [ "$(id -u)" -ne 0 ]; then
    echo "Запустите через sudo" >&2
    exit 1
fi

mkdir -p "$DIR" /mnt/raid /mnt/logs

for n in 1 2 3; do
    [ -f "$DIR/disk$n.img" ] || dd if=/dev/zero of="$DIR/disk$n.img" bs=1M count="$SIZE_MB" status=none
done

attach() {
    local dev
    dev=$(losetup -j "$1" | cut -d: -f1 | head -n1)
    [ -n "$dev" ] || dev=$(losetup -fP --show "$1")
    echo "$dev"
}

LOOP1=$(attach "$DIR/disk1.img")
LOOP2=$(attach "$DIR/disk2.img")
LOOP3=$(attach "$DIR/disk3.img")
echo "loop-устройства: $LOOP1 $LOOP2 $LOOP3"

udevadm settle

AUTO=$(awk '/^md/ && /loop/ {print "/dev/"$1}' /proc/mdstat | grep -v '^/dev/md0$' || true)
for md in $AUTO; do
    mdadm --stop "$md"
done

if ! grep -q '^md0 : active' /proc/mdstat; then
    mdadm --stop /dev/md0 >/dev/null 2>&1 || true
    if mdadm --examine "$LOOP1" >/dev/null 2>&1; then
        mdadm --assemble /dev/md0 "$LOOP1" "$LOOP2"
    else
        yes | mdadm --create /dev/md0 --level=1 --raid-devices=2 "$LOOP1" "$LOOP2"
        mkfs.ext4 -q /dev/md0
    fi
fi
mountpoint -q /mnt/raid || mount /dev/md0 /mnt/raid

pvscan --cache >/dev/null 2>&1 || true
if ! vgs vg_data >/dev/null 2>&1; then
    yes | pvcreate "$LOOP3"
    vgcreate vg_data "$LOOP3"
    yes | lvcreate -L 200M -n lv_logs vg_data
    mkfs.ext4 -q /dev/vg_data/lv_logs
fi
vgchange -ay vg_data >/dev/null
mountpoint -q /mnt/logs || mount /dev/vg_data/lv_logs /mnt/logs

cat /proc/mdstat
lvs vg_data
df -h /mnt/raid /mnt/logs
