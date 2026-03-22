local exporter = _G.BLENDER_LINK_LOAD("core/exporter.lua")

local command = {}

function command.run(ctx)
  if not ctx.state.job then
    app.alert("No job is loaded.")
    return
  end

  if ctx.config.get("auto_validate_before_export") then
    -- validation is always executed inside exporter as final safety gate
  end

  local ok, message, validation = exporter.export(ctx.state, ctx.config)
  ctx.state.last_validation = validation
  if ok then
    app.alert("Exported PNG to:\n" .. message)
    ctx.logger.info("Export success: " .. message)
  else
    app.alert("Export failed:\n" .. message)
    ctx.logger.error("Export failure: " .. tostring(message))
  end
end

return command
