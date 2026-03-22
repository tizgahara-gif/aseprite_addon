local registry = _G.BLENDER_LINK_LOAD("core/job_registry.lua")
local browserDialog = _G.BLENDER_LINK_LOAD("ui/browser_dialog.lua")
local openJob = _G.BLENDER_LINK_LOAD("commands/open_job.lua")

local command = {}

function command.run(ctx)
  local defaultFolder = ctx.config.get("default_job_folder") or ""
  local dlg = Dialog("Pick Job Folder")
  dlg:entry{ id = "folder", label = "Folder", text = defaultFolder }
  dlg:button{ id = "scan", text = "Scan" }
  dlg:button{ id = "cancel", text = "Cancel" }
  dlg:show{ wait = true }

  local data = dlg.data
  if not data or not data.folder then return end
  local folder = data.folder:gsub("^%s+", ""):gsub("%s+$", "")
  if folder == "" then
    app.alert("Folder path is empty.")
    return
  end
  if not app.fs.isDirectory(folder) then
    app.alert("Folder does not exist:\n" .. folder)
    return
  end

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
