#!/bin/bash
# shared_disk_wsl_links.sh: run INSIDE WSL (no sudo) after shared_disk_wsl.ps1.
# Creates the same home shortcuts as native Ubuntu and a mount reminder in ~/.zshrc.
set -euo pipefail
MNT=/mnt/wsl/shared_disk

mountpoint -q "$MNT" || { echo "$MNT not mounted; run the 'WSL mount shared_disk' task first"; exit 1; }

link() {   # $1 = shortcut in ~, $2 = target on the shared disk
  local l=~/"$1"
  if [ -e "$l" ] && [ ! -L "$l" ]; then
    echo "~/$1 is a real directory; moving it to ~/$1.old"
    mv "$l" "$l.old"
  fi
  ln -sfn "$2" "$l"
  echo "~/$1 -> $2"
}

link wslgit      "$MNT/git"
link Latex       "$MNT/Latex"
link shared_disk "$MNT"

MARK='# shared_disk mount check'
if ! grep -qF "$MARK" ~/.zshrc 2>/dev/null; then
  cat >> ~/.zshrc <<'EOF'

# shared_disk mount check
mountpoint -q /mnt/wsl/shared_disk || \
  echo "shared_disk not mounted. In admin PowerShell: Start-ScheduledTask -TaskName 'WSL mount shared_disk'"
EOF
  echo "Added mount reminder to ~/.zshrc"
fi
