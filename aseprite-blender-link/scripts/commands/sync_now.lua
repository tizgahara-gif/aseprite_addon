local command = {}

function command.run(ctx)
  local sprite = ctx.state.sprite or app.activeSprite

  local ok, msg = ctx.syncManager.sync_now(sprite)
  if ok then
    app.alert("Synced to Blender target")
    ctx.logger.info("Manual sync success")
  else
    app.alert("Manual sync failed: " .. tostring(msg))
    ctx.logger.error("Manual sync failed: " .. tostring(msg))
  end
end

return command
