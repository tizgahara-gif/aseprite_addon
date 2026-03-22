local openJob = _G.BLENDER_LINK_LOAD("commands/open_job.lua")
local parser = _G.BLENDER_LINK_LOAD("core/job_parser.lua")

local command = {}

function command.run(ctx)
  if not ctx.state.jobPath then
    app.alert("No active job.")
    return
  end

  if app.activeSprite and app.activeSprite.isModified then
    local res = app.alert{ title = "Unsaved changes", text = "Current document has unsaved changes.", buttons = {"Cancel", "Reload"} }
    if res ~= 2 then return end
  end

  local parsed, errors = parser.parse(ctx.state.jobPath)
  if not parsed then
    app.alert("Reload failed:\n" .. table.concat(errors or {"Unknown parse error"}, "\n"))
    return
  end

  if ctx.state.current_revision and parsed.revision ~= ctx.state.current_revision then
    app.alert(string.format("Job revision changed: %s -> %s", tostring(ctx.state.current_revision), tostring(parsed.revision)))
  end

  ctx.logger.info("Reloading job: " .. ctx.state.jobPath)
  openJob.openByPath(ctx, ctx.state.jobPath)
end

return command
