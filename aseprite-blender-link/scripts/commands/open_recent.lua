local openJob = _G.BLENDER_LINK_LOAD("commands/open_job.lua")

local command = {}

function command.run(ctx)
  local recent = ctx.config.get("recent_jobs") or {}
  if #recent == 0 then
    app.alert("No recent jobs")
    return
  end

  local existing = {}
  for _, p in ipairs(recent) do
    if app.fs.isFile(p) then table.insert(existing, p) end
  end
  if #existing == 0 then
    app.alert("No recent jobs found on disk")
    return
  end

  local dlg = Dialog("Open Recent Job")
  dlg:combobox{ id = "path", label = "Recent", option = existing[1], options = existing }
  dlg:button{ id = "open", text = "Open" }
  dlg:button{ id = "cancel", text = "Cancel" }
  dlg:show{ wait = true }
  local data = dlg.data
  if data and data.path then openJob.openByPath(ctx, data.path) end
end

return command
