-- lsyncd.conf.lua: live one-way mirrors from native Ubuntu to the shared disk.
-- Run by lsyncd-shared.service. Projects are listed in projects.lua (same folder).

local cfg = dofile("/home/vinayak/DevTools/Linux-Setup/lsyncd/projects.lua")

-- Guard 1: the shared disk must really be mounted. Otherwise lsyncd would sync
-- into the empty mount-point folder on the root filesystem, and with delete on,
-- the first sync after the real disk mounts would be wrong.
if not os.execute("mountpoint -q '" .. cfg.shared .. "'") then
  error(cfg.shared .. " is not mounted; refusing to start")
end

settings {
  nodaemon      = true,     -- systemd supervises; logs go to the journal
  insist        = true,     -- keep retrying instead of exiting on a transient error
  statusFile    = os.getenv("HOME") .. "/.local/state/lsyncd.status",
  statusInterval = 30,
  maxProcesses  = 2,
}

local function concat(a, b)
  local out = {}
  for _, v in ipairs(a or {}) do out[#out + 1] = v end
  for _, v in ipairs(b or {}) do out[#out + 1] = v end
  return out
end

local function isdir(p) return os.execute("test -d '" .. p .. "'") end

for _, p in ipairs(cfg.projects) do
  local src = p.src:gsub("/+$", "")
  local dst = p.dst:gsub("/+$", "")

  -- Guard 2: never mirror (with delete) onto the disk root or outside it
  if dst:sub(1, #cfg.shared + 1) ~= cfg.shared .. "/" then
    error("dst must be inside " .. cfg.shared .. ": " .. dst)
  end
  -- Guard 3: a missing source would otherwise be a fatal error; skip it instead
  if not isdir(src) then
    log("Warn", "skipping, source missing: " .. src)
  else
    os.execute("mkdir -p '" .. dst .. "'")
    sync {
      default.rsync,
      source  = src .. "/",
      target  = dst .. "/",
      delete  = (p.delete ~= false),        -- default: mirror deletions
      delay   = p.delay or 5,
      exclude = concat(cfg.exclude, p.exclude),
      rsync   = { archive = true },         -- keeps exec bits, symlinks, times
    }
  end
end
