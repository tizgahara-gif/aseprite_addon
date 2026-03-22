local command = {}

function command.run(ctx)
  local sprite = ctx.state.sprite or app.activeSprite
  if not sprite then
    app.alert("No active sprite.")
    return
  end

  local desired = not ctx.config.get("auto_sync_default")
  ctx.config.set("auto_sync_default", desired)
  ctx.config.save()

  local ok, msg = ctx.syncManager.toggle(sprite, desired)
  if ok then
    app.alert(msg)
    ctx.logger.info(msg)
  else
    app.alert("Failed to toggle auto sync: " .. tostring(msg))
  end
end

return command
