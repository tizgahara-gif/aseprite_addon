local registry = _G.BLENDER_LINK_LOAD("core/job_registry.lua")
local browserDialog = _G.BLENDER_LINK_LOAD("ui/browser_dialog.lua")
local openJob = _G.BLENDER_LINK_LOAD("commands/open_job.lua")

local command = {}

function command.run(ctx)
  local folder = app.fs.fileDialog{ title = "Pick job folder", open = false, save = false, filename = ctx.config.get("default_job_folder") }
  if not folder or folder == "" then return end

  local jobs = registry.scanFolder(folder)
  local picked = browserDialog.pick(jobs)
  if not picked then return end
  if not picked.job then
    app.alert("Selected job JSON is invalid.\n" .. table.concat(picked.errors, "\n"))
    return
  end

  openJob.openByPath(ctx, picked.path)
end

return command
