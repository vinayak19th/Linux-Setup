#!/bin/bash
# shared_disk_setup.sh: an ext4 VHDX on the Windows D: drive, shared between
# native Ubuntu and WSL. See shared_disk_setup.md for the full walkthrough.
#
# Usage (native Ubuntu):
#   sudo ./shared_disk_setup.sh create      # one-off: create + format + mount the VHDX
#   sudo ./shared_disk_setup.sh automount   # install systemd service + fstab entry, mount via systemd
#   sudo ./shared_disk_setup.sh mount       # mount now (through systemd)
#   sudo ./shared_disk_setup.sh unmount     # unmount + detach (do this before booting Windows if unsure)
#        ./shared_disk_setup.sh status      # show state
#   sudo ./shared_disk_setup.sh uninstall   # remove service + fstab entry (the image is kept)
set -euo pipefail

# ---- configuration --------------------------------------------------------
IMG=/mnt/d/linux/shared_disk.vhdx   # D:\linux\shared_disk.vhdx on Windows
HOST_MNT=/mnt/d                     # filesystem that holds $IMG
SIZE=256G                           # max size; the file grows on demand
NBD=/dev/nbd1                       # nbd0 is left for the WSL system image
MNT=/mnt/wsl_shared_disk
LABEL=shared_disk
OWNER=vinayak                       # UID 1000 on both Ubuntu and WSL
SERVICE=shared-disk-nbd.service
# ---------------------------------------------------------------------------

NBDNAME=${NBD#/dev/}
MOUNT_UNIT=$(systemd-escape -p --suffix=mount "$MNT")
FSTAB_LINE="LABEL=$LABEL  $MNT  ext4  noatime,nofail,x-systemd.requires=$SERVICE,x-systemd.device-timeout=30s  0  2"

die()  { echo "error: $*" >&2; exit 1; }
need_root() { [ "$(id -u)" = 0 ] || die "run with sudo"; }

wait_for_nbd() {
  for _ in $(seq 100); do
    [ "$(cat /sys/block/$NBDNAME/size)" != 0 ] && return 0
    sleep 0.1
  done
  die "$NBD did not come up"
}

cmd_create() {
  need_root
  [ -e "$IMG" ] && die "$IMG already exists; refusing to overwrite"
  mountpoint -q "$HOST_MNT" || die "$HOST_MNT is not mounted"
  findmnt -no OPTIONS "$HOST_MNT" | grep -qw rw || die "$HOST_MNT is read-only (Windows hibernated / Fast Startup?)"
  [ "$(cat /sys/block/$NBDNAME/size 2>/dev/null || echo 0)" = 0 ] || die "$NBD is in use"

  echo "==> creating dynamic VHDX $IMG ($SIZE max)"
  qemu-img create -f vhdx -o subformat=dynamic,block_size=32M "$IMG" "$SIZE"

  echo "==> attaching as $NBD"
  modprobe nbd max_part=8
  qemu-nbd --connect="$NBD" --cache=writeback "$IMG"
  wait_for_nbd

  # ^orphan_file: WSL's Ubuntu 22.04 (e2fsprogs 1.46) can't fsck that feature
  # -i 32768    : ~8M inodes on 256G; plenty for git/LaTeX/Jekyll, small inode tables
  # -m 0        : no root-reserved blocks on a data disk
  echo "==> formatting ext4 (whole disk, no partition table)"
  mkfs.ext4 -L "$LABEL" -O ^orphan_file -i 32768 -m 0 "$NBD"

  mkdir -p "$MNT"
  mount -o noatime "$NBD" "$MNT"
  chown "$OWNER:$OWNER" "$MNT"
  echo "==> mounted at $MNT"
  ls -lh "$IMG"
  echo "Next: sudo $0 automount"
}

cmd_automount() {
  need_root
  [ -e "$IMG" ] && command -v qemu-nbd >/dev/null || die "need $IMG and qemu-nbd (apt install qemu-utils)"

  echo "==> writing /etc/systemd/system/$SERVICE"
  cat > /etc/systemd/system/$SERVICE <<EOF
[Unit]
Description=Attach $IMG as $NBD
RequiresMountsFor=$HOST_MNT

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStartPre=/sbin/modprobe nbd max_part=8
ExecStart=/usr/bin/qemu-nbd --connect=$NBD --cache=writeback $IMG
ExecStart=/bin/sh -c 'for i in \$\$(seq 100); do [ "\$\$(cat /sys/block/$NBDNAME/size)" != 0 ] && exit 0; sleep 0.1; done; exit 1'
ExecStop=/usr/bin/qemu-nbd --disconnect $NBD
TimeoutStopSec=60
EOF

  if grep -qE "^[^#]*[[:space:]]$MNT[[:space:]]" /etc/fstab; then
    echo "==> /etc/fstab already has an entry for $MNT; leaving it"
  else
    echo "==> adding fstab entry (backup: /etc/fstab.bak-shared-disk)"
    cp /etc/fstab /etc/fstab.bak-shared-disk
    echo "$FSTAB_LINE" >> /etc/fstab
  fi
  mkdir -p "$MNT"

  # Release a manual mount so the systemd path gets tested
  if mountpoint -q "$MNT" && ! systemctl is-active -q "$MOUNT_UNIT"; then
    echo "==> releasing manual mount"
    umount "$MNT"
  fi
  if [ "$(cat /sys/block/$NBDNAME/size)" != 0 ] && ! systemctl is-active -q "$SERVICE"; then
    qemu-nbd --disconnect "$NBD"
  fi

  systemctl daemon-reload
  cmd_mount
  echo "Done. It will mount at every boot (WantedBy=local-fs.target)."
}

cmd_mount()   { need_root; systemctl start "$MOUNT_UNIT"; cmd_status; }
cmd_unmount() { need_root; systemctl stop "$MOUNT_UNIT"; systemctl stop "$SERVICE" 2>/dev/null || true; cmd_status; }

cmd_status() {
  echo "service : $(systemctl is-active "$SERVICE" 2>/dev/null || true)"
  echo "mount   : $(systemctl is-active "$MOUNT_UNIT" 2>/dev/null || true)  ($MOUNT_UNIT)"
  findmnt "$MNT" || true
  df -h "$MNT" 2>/dev/null | tail -1 || true
  ls -lh "$IMG" 2>/dev/null || true
}

cmd_uninstall() {
  need_root
  systemctl stop "$MOUNT_UNIT" 2>/dev/null || true
  systemctl stop "$SERVICE" 2>/dev/null || true
  cp /etc/fstab /etc/fstab.bak-shared-disk
  sed -i "\|^LABEL=$LABEL[[:space:]]\+$MNT[[:space:]]|d" /etc/fstab
  rm -f /etc/systemd/system/$SERVICE
  systemctl daemon-reload
  echo "Removed service and fstab entry. Image kept: $IMG"
}

case "${1:-}" in
  create)    cmd_create ;;
  automount) cmd_automount ;;
  mount)     cmd_mount ;;
  unmount)   cmd_unmount ;;
  status)    cmd_status ;;
  uninstall) cmd_uninstall ;;
  *) sed -n '2,13p' "$0"; exit 1 ;;
esac
