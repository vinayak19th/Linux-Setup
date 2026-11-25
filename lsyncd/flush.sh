#!/bin/bash
# flush.sh: one full rsync pass for every project in projects.lua.
# lsyncd-shared.service runs it when lsyncd stops (shutdown/reboot/restart), so
# changes still waiting in lsyncd's batching delay aren't lost. Safe to run by hand.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)

# Print the projects as tab-separated "src dst delete excludes..." using the same Lua file
LIST=$(lua5.3 - "$HERE/projects.lua" <<'EOF'
local cfg = dofile(arg[1])
for _, p in ipairs(cfg.projects) do
  local row = { p.src, p.dst, (p.delete == false) and "0" or "1" }
  for _, e in ipairs(cfg.exclude or {}) do row[#row + 1] = e end
  for _, e in ipairs(p.exclude  or {}) do row[#row + 1] = e end
  print(table.concat(row, "\t"))
end
print("SHARED\t" .. cfg.shared)
EOF
) || { echo "flush: could not read projects.lua"; exit 1; }

SHARED=$(awk -F'\t' '$1=="SHARED"{print $2}' <<<"$LIST")
mountpoint -q "$SHARED" || { echo "flush: $SHARED not mounted, nothing to do"; exit 0; }

rc=0
while IFS=$'\t' read -r src dst del rest; do
  [ "$src" = SHARED ] && continue
  src=${src%/}; dst=${dst%/}
  case "$dst" in "$SHARED"/?*) ;; *) echo "flush: refusing dst outside $SHARED: $dst"; rc=1; continue ;; esac
  [ -d "$src" ] || { echo "flush: skipping, source missing: $src"; continue; }
  opts=(-a)
  [ "$del" = 1 ] && opts+=(--delete)
  IFS=$'\t' read -r -a excl <<<"$rest"
  for e in "${excl[@]}"; do [ -n "$e" ] && opts+=(--exclude="$e"); done
  mkdir -p "$dst"
  if rsync "${opts[@]}" "$src/" "$dst/"; then
    echo "flush: $src -> $dst ok"
  else
    echo "flush: $src -> $dst FAILED"; rc=1
  fi
done <<<"$LIST"
exit $rc
