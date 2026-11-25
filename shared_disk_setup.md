# Shared ext4 disk for dual-boot Ubuntu and WSL

One dynamically growing ext4 disk image, `D:\linux\shared_disk.vhdx`, holds the
git repos (Jekyll sites) and LaTeX projects. Native Ubuntu and WSL both mount it,
so both get real ext4 speed and permissions instead of working through NTFS.

| | Native Ubuntu | WSL (Ubuntu 22.04) |
|---|---|---|
| Image | `/mnt/d/linux/shared_disk.vhdx` | `D:\linux\shared_disk.vhdx` |
| Attached as | `/dev/nbd1` via `qemu-nbd` | `wsl --mount --vhd` |
| Mount point | `/mnt/wsl_shared_disk` | `/mnt/wsl/shared_disk` |
| Shortcuts | `~/wslgit` → `git/`, `~/Latex` → `Latex/` | same names |
| Owner | `vinayak` (UID 1000) | `vinayak` (UID 1000) |

Files in this repo:

| File | Runs on | Purpose |
|---|---|---|
| `shared_disk_setup.sh` | Ubuntu | `create`, `automount`, `mount`, `unmount`, `status`, `uninstall` |
| `shared_disk_wsl.ps1` | Windows, admin PowerShell | logon task that mounts the disk into WSL, turns off Fast Startup |
| `shared_disk_wsl_links.sh` | inside WSL | `~/wslgit`, `~/Latex` shortcuts plus a "not mounted" warning |

**Quick start**
```bash
# Ubuntu
sudo apt install qemu-utils
sudo ./shared_disk_setup.sh create        # once
sudo ./shared_disk_setup.sh automount     # once
ln -sfn /mnt/wsl_shared_disk/git ~/wslgit; ln -sfn /mnt/wsl_shared_disk/Latex ~/Latex
```
```powershell
# Windows, admin PowerShell, from this folder
powershell -ExecutionPolicy Bypass -File .\shared_disk_wsl.ps1
```
```bash
# inside WSL
bash shared_disk_wsl_links.sh
```

---

## Ground rules

1. **Never open the disk in both systems at once.** On one dual-boot machine
   that can only happen if Windows didn't truly shut down. See rule 2.
2. **Fast Startup and hibernation must be off in Windows** (`powercfg /h off`,
   which `shared_disk_wsl.ps1` runs). Otherwise "Shut down" leaves D: and
   the VHDX half-open, and writing to them from Ubuntu can corrupt them. Warning
   sign: `C:\hiberfil.sys` keeps getting a fresh timestamp.
3. **Leave Windows** with a real Shut down or Restart. Run `wsl --shutdown`
   first as a habit. **Leave Ubuntu** normally: systemd unmounts the disk and
   detaches it before D: is unmounted.
4. **Build environments stay per-OS:** `.venv` (`uv sync`), Ruby gems
   (`bundle install`, never commit `vendor/bundle`), `node_modules`, `_site`.
   They contain compiled code and absolute paths for one system.
5. **Keep it backed up.** Push the repos. Anything in `Latex/` that isn't a git
   repo exists only on this disk.

---

## Design decisions

- **Why not keep the files on NTFS?** On Ubuntu every file lookup goes through
  ntfs-3g (a userspace FUSE driver), which is about 6× slower for `git status`
  and Jekyll/LaTeX rebuilds. From WSL, `/mnt/d` goes over 9P, which is
  10–50× slower and mangles permissions and exec bits.
- **Why a disk image?** Inside the image both kernels run their native
  ext4 driver. Measured on Ubuntu: looking up 3,000 files ×5 took 0.023 s
  (image), 0.148 s (NTFS) and 0.022 s (native btrfs).
- **Trade-off:** large sequential writes into the image are slow on Ubuntu
  (about 60 MB/s, through qemu-nbd → VHDX → ntfs-3g). Keep big datasets,
  checkpoints and results off it.
- **VHDX, not VHD:** VHDX has a metadata log that survives power loss and
  crashes. Both formats work with `wsl --mount`.
- **Dynamic:** the file starts small and grows. It **never shrinks** on its own
  (see [Reclaiming space](#reclaiming-space)).
- **ext4, not btrfs/XFS:** fastest for many small files, native to WSL, and
  `fsck` works on both sides. btrfs's copy-on-write makes a dynamic image grow
  much faster than the data in it, and XFS's newer format features can trip up
  WSL's older tools.
- **D: stays on ntfs-3g:** it's the most mature driver for the rest of D:.
  `ntfs3` (Paragon, kernel 5.15+) and the new `ntfs` driver (kernel 7.1+,
  2026) were both considered too young for a 1.2 TB general-purpose volume.

---

## Part 1: Create the disk (Ubuntu, once)

Run `sudo ./shared_disk_setup.sh create`, or do it by hand:

### 0. Check that nothing is in the way
```bash
ls -lh /mnt/d/linux/          # no shared_disk.vhdx yet
lsblk /dev/nbd1               # 0B = free (nbd0 is kept for the WSL system image)
```

### 1. Create a dynamic VHDX
```bash
qemu-img create -f vhdx -o subformat=dynamic,block_size=32M /mnt/d/linux/shared_disk.vhdx 256G
qemu-img info /mnt/d/linux/shared_disk.vhdx
```
- `subformat=dynamic`: grows as data is written, up to 256G.
- `block_size=32M`: the unit the file grows by; the Windows/Hyper-V default.
- No `sudo` needed: D: is mounted with `uid=1000`.

### 2. Attach it as a block device
```bash
sudo modprobe nbd max_part=8
sudo qemu-nbd --connect=/dev/nbd1 --cache=writeback /mnt/d/linux/shared_disk.vhdx
lsblk /dev/nbd1               # 256G disk
```
`qemu-nbd` translates the VHDX format, so the kernel sees a raw disk.

### 3. Format ext4
```bash
sudo mkfs.ext4 -L shared_disk -O ^orphan_file -i 32768 -m 0 /dev/nbd1
sudo blkid /dev/nbd1          # LABEL="shared_disk" TYPE="ext4"
```
- **Whole disk, no partition table**, which `wsl --mount` handles directly.
- `-L shared_disk`: fstab finds the disk by this label.
- `-O ^orphan_file`: WSL is Ubuntu 22.04 (e2fsprogs 1.46), which can't fsck
  this newer ext4 feature (on by default in e2fsprogs 1.47+).
- `-i 32768`: one inode per 32 KB, about 8M files on 256G. Smaller inode tables
  keep the initial image small.
- `-m 0`: no space reserved for root on a data disk.

### 4. Mount and take ownership
```bash
sudo mkdir -p /mnt/wsl_shared_disk
sudo mount -o noatime /dev/nbd1 /mnt/wsl_shared_disk
sudo chown vinayak:vinayak /mnt/wsl_shared_disk
```

### 5. Move data in
Copy with rsync and leave the per-OS build folders out:
```bash
EXCL="--exclude=.venv/ --exclude=node_modules/ --exclude=vendor/bundle/ \
      --exclude=_site/ --exclude=.jekyll-cache/ --exclude=__pycache__/"
# From NTFS everything shows as 777, so normalise the modes:
rsync -rltH --chmod=D755,F644 $EXCL --info=progress2 ~/d/git/ /mnt/wsl_shared_disk/git/
```
Then restore the executable bits each repo tracks (run inside each repo):
```bash
git ls-files -s | awk '$1=="100755"{print $4}' | xargs -r chmod +x
git status            # should be clean apart from real changes
```

---

## Part 2: Automount on Ubuntu

Run `sudo ./shared_disk_setup.sh automount`, or do it by hand:

### 1. Service that attaches the VHDX
```bash
sudo tee /etc/systemd/system/shared-disk-nbd.service >/dev/null <<'EOF'
[Unit]
Description=Attach D:\linux\shared_disk.vhdx as /dev/nbd1
RequiresMountsFor=/mnt/d

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStartPre=/sbin/modprobe nbd max_part=8
ExecStart=/usr/bin/qemu-nbd --connect=/dev/nbd1 --cache=writeback /mnt/d/linux/shared_disk.vhdx
ExecStart=/bin/sh -c 'for i in $$(seq 100); do [ "$$(cat /sys/block/nbd1/size)" != 0 ] && exit 0; sleep 0.1; done; exit 1'
ExecStop=/usr/bin/qemu-nbd --disconnect /dev/nbd1
TimeoutStopSec=60
EOF
systemd-analyze verify /etc/systemd/system/shared-disk-nbd.service
```
- `RequiresMountsFor=/mnt/d`: starts after D: is mounted and stops *before*
  D: is unmounted at shutdown, so the image is never cut off mid-write.
- `oneshot` + `RemainAfterExit`: `qemu-nbd` daemonises itself, and the unit
  stays "active" until it's stopped.
- The loop waits up to 10 s for the device to report a size. `$$` is how a
  unit file passes a literal `$` to the shell.
- No `[Install]` section: the fstab entry pulls it in.

### 2. fstab entry
```bash
sudo cp /etc/fstab /etc/fstab.bak
echo 'LABEL=shared_disk  /mnt/wsl_shared_disk  ext4  noatime,nofail,x-systemd.requires=shared-disk-nbd.service,x-systemd.device-timeout=30s  0  2' | sudo tee -a /etc/fstab
sudo systemctl daemon-reload
```
- `x-systemd.requires=`: systemd starts the service before mounting, and
  stops it after unmounting.
- `nofail` + `device-timeout=30s`: if D: is locked, boot carries on without
  this disk.
- Last field `2`: fsck at boot.

This makes it a boot service. systemd generates `mnt-wsl_shared_disk.mount`
from the fstab line with `WantedBy=local-fs.target`. Mount units made from
fstab can't be `systemctl enable`d, and don't need to be.

### 3. Test it, through systemd
```bash
sudo systemctl start mnt-wsl_shared_disk.mount
systemctl status shared-disk-nbd.service mnt-wsl_shared_disk.mount --no-pager
sudo systemctl stop mnt-wsl_shared_disk.mount     # stops the service as well
sudo reboot                                       # the real test
```

### Boot and shutdown order
```
boot:     /mnt/d (ntfs-3g) → shared-disk-nbd.service (nbd1) → fsck → /mnt/wsl_shared_disk
shutdown: the same steps in reverse
```

---

## Part 3: Automount in WSL

`wsl --mount` needs administrator rights, so a scheduled task with highest
privileges runs it at every Windows logon. `shared_disk_wsl.ps1` does all of
this.

### 1. Try it by hand (admin PowerShell)
```powershell
wsl --mount --vhd D:\linux\shared_disk.vhdx --name shared_disk
wsl -e findmnt /mnt/wsl/shared_disk
```
There's no partition table, so `--partition` isn't needed, and ext4 is the
default type. The disk appears at `/mnt/wsl/shared_disk` in every distro.

### 2. Logon task (admin PowerShell)
```powershell
powercfg /h off
$action    = New-ScheduledTaskAction -Execute "wsl.exe" `
               -Argument '--mount --vhd D:\linux\shared_disk.vhdx --name shared_disk'
$trigger   = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Highest -LogonType Interactive
$settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
               -ExecutionTimeLimit (New-TimeSpan -Minutes 2)
Register-ScheduledTask -TaskName "WSL mount shared_disk" `
  -Action $action -Trigger $trigger -Principal $principal -Settings $settings
Start-ScheduledTask -TaskName "WSL mount shared_disk"
```
Remove it with
`Unregister-ScheduledTask -TaskName "WSL mount shared_disk"`, or run
`shared_disk_wsl.ps1 -Uninstall`.

### 3. Shortcuts inside WSL
`bash shared_disk_wsl_links.sh` creates `~/wslgit`, `~/Latex` and `~/shared_disk`.
If one of those is a real directory (the old `~/wslgit` is), it's renamed to
`*.old` rather than overwritten. The script also adds a "not mounted" warning
to `~/.zshrc`.

### Notes
- `wsl --shutdown` unmounts the disk. Remount it with
  `Start-ScheduledTask -TaskName "WSL mount shared_disk"`.
- Windows apps can open it at
  `\\wsl.localhost\Ubuntu-22.04\mnt\wsl\shared_disk` while WSL is running
  (`wsl -l -v` shows the distro name).

---

## Day-to-day commands (Ubuntu)

```bash
./shared_disk_setup.sh status
sudo ./shared_disk_setup.sh mount      # = systemctl start mnt-wsl_shared_disk.mount
sudo ./shared_disk_setup.sh unmount    # unmount + detach
```

---

## Troubleshooting and gotchas

| Symptom | Cause / fix |
|---|---|
| `sudo mount /mnt/wsl_shared_disk` prints nothing and the folder is empty | Plain `mount` bypasses systemd, so the service never runs. `nofail` then hides the "label not found" error. Use `systemctl start mnt-wsl_shared_disk.mount`. |
| `findmnt --verify`: `[E] unreachable on boot required source: LABEL=shared_disk` | Expected while the disk is detached. findmnt doesn't know the service creates the device. It disappears once mounted. |
| `findmnt --verify`: `ntfs-3g seems unsupported by the current kernel` | False alarm: ntfs-3g is FUSE, not a kernel driver. |
| `qemu-img: ... contains a log that needs to be replayed` | Image not closed cleanly (WSL still running, or Fast Startup). Back it up, then `qemu-img check -r all <img>`, or boot Windows and shut down properly. |
| `qemu-img: Failed to get shared "write" lock` | The image is attached. Unmount first. |
| Service fails at boot | `journalctl -b -u shared-disk-nbd.service -u mnt-wsl_shared_disk.mount`. Usually D: came up read-only because Windows hibernated. |
| `git status` slow the first time after switching OS | Git rescans files because its saved file info differs between machines. Harmless, once per switch. |
| WSL: `wsl --mount` fails with "in use" | The image is still attached in some other session. Run `wsl --unmount \\?\D:\linux\shared_disk.vhdx`, then retry. |

Undo everything on Ubuntu with `sudo ./shared_disk_setup.sh uninstall` (keeps
the image), or restore `/etc/fstab.bak`, remove the service file and run
`daemon-reload`.

---

## Reclaiming space

Deleting files frees space *inside* the image, but the `.vhdx` file stays the
same size.

```bash
sudo fstrim -av                     # inside WSL, with the disk mounted
```
```powershell
wsl --shutdown
# one-off compaction (admin; works for any VHDX)
diskpart
  select vdisk file="D:\linux\shared_disk.vhdx"
  attach vdisk readonly
  compact vdisk
  detach vdisk
  exit
# for WSL's own system disk, it can reclaim space automatically:
wsl --manage Ubuntu-22.04 --set-sparse true
```

WSL's system image `ext4.vhdx` (89 GB) is mostly caches: `~/.cache` 42 GB
(uv 31, pip 8.7), `~/miniconda3` 16 GB, and editor servers about 7 GB (Nov 2026).
Clean them up in WSL (`uv cache clean`, `pip cache purge`, `conda clean -a`),
then compact as above.

---

## Appendix: open WSL's own system disk from Ubuntu

Useful for getting files out of WSL without booting Windows. Do it only when
WSL is fully shut down.
```bash
sudo modprobe nbd max_part=8
sudo qemu-nbd --connect=/dev/nbd0 /mnt/d/linux/ext4.vhdx    # add --read-only to only look
sudo mkdir -p /mnt/wsl && sudo mount /dev/nbd0 /mnt/wsl
# ... done:
sudo umount /mnt/wsl && sudo qemu-nbd --disconnect /dev/nbd0
```
If it complains about a log that needs replaying, see Troubleshooting.
