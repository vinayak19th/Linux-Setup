-- projects.lua: the ONE file to edit when adding a project.
-- Read by lsyncd.conf.lua (live sync) and flush.sh (final sync at shutdown).
--
-- Each entry mirrors src -> dst one-way. Deletions ARE mirrored by default,
-- so treat dst as read-only (in WSL, write outputs somewhere else).
--
--   src     : folder on native Ubuntu (source of truth)
--   dst     : folder on the shared disk; must be below SHARED, never SHARED itself
--   exclude : optional extra rsync exclude patterns for this project
--   delete  : optional, set false to keep files in dst that were deleted in src
--   delay   : optional, seconds to batch changes (default 5)

local HOME   = "/home/vinayak"
local SHARED = "/mnt/wsl_shared_disk"

return {
  shared = SHARED,

  -- excluded from every project
  exclude = { "__pycache__/", ".ipynb_checkpoints/", "*.pyc", "*.swp", "*.tmp",
              ".venv/", "node_modules/", ".git/" },

  projects = {
    { src = HOME .. "/git/QuIRK/experiments",
      dst = SHARED .. "/git/QuIRK/experiments" },

    -- Examples:
    -- { src = HOME .. "/git/NewProject/results",
    --   dst = SHARED .. "/git/NewProject/results",
    --   exclude = { "*.ckpt", "wandb/" } },
    -- { src = HOME .. "/git/Archive/outputs",
    --   dst = SHARED .. "/git/Archive/outputs", delete = false },
  },
}
