local validator = _G.BLENDER_LINK_LOAD("core/validator.lua")

local syncManager = {
  entries = {}
}

local function setGuideVisibility(sprite, visible)
  local previous = {}
  for i, layer in ipairs(sprite.layers) do
    previous[i] = layer.isVisible
    if layer.name:sub(1, 6) == "GUIDE_" then
      layer.isVisible = visible
    end
  end
  return previous
end

local function restoreVisibility(sprite, previous)
  for i, layer in ipairs(sprite.layers) do
    if previous[i] ~= nil then
      layer.isVisible = previous[i]
    end
  end
end

local function doExport(entry, force)
  local sprite = entry.sprite
  if not sprite or sprite.isClosed then return false, "Sprite is closed" end

  if entry.config.get("auto_validate_before_export") then
    local result = validator.validate(entry.job, sprite, entry.state)
    entry.state.last_validation = result
    entry.state.validation_state = result.state
    if result.state == "ERROR" and not force then
      return false, "Auto sync blocked by validation errors"
    end
  end

  local previous = setGuideVisibility(sprite, false)
  local ok, err = pcall(function()
    sprite:saveCopyAs(entry.job.task.export_path)
  end)
  restoreVisibility(sprite, previous)

  if ok then
    entry.state.dirty_state = "EXPORTED_TO_TARGET"
    entry.logger.info("Auto sync exported: " .. tostring(entry.job.task.export_path))
    if entry.config.get("show_sync_status") then
      app.tip("Blender Link auto-sync exported")
    end
    if entry.relayClient then
      local sent, sendErr = entry.relayClient.sendTextureExported(entry.job, entry.logger)
      if not sent then
        entry.logger.warn("Relay notify failed: " .. tostring(sendErr))
      end
    end
    return true
  end

  entry.logger.error("Auto sync export failed: " .. tostring(err))
  return false, tostring(err)
end

local function keyFor(sprite)
  return tostring(sprite)
end

function syncManager.detach_sprite_sync(sprite)
  if not sprite then return end
  local key = keyFor(sprite)
  local entry = syncManager.entries[key]
  if not entry then return end

  pcall(function() if entry.timer then entry.timer:stop() end end)
  if entry.listener and sprite.events then
    pcall(function() sprite.events:off(entry.listener) end)
  end
  if entry.closeListener and sprite.events then
    pcall(function() sprite.events:off(entry.closeListener) end)
  end
  syncManager.entries[key] = nil
end

function syncManager.attach_sprite_sync(sprite, job, plugin, state, config, logger, relayClient)
  if not sprite or not job or not job.task or not job.task.export_path then
    return false, "Missing sprite/job/export path"
  end

  syncManager.detach_sprite_sync(sprite)

  local debounce = tonumber(config.get("debounce_seconds") or 0.8) or 0.8
  if debounce <= 0 then debounce = 0.2 end

  local timer = Timer{ interval = debounce }
  timer.onTick = function()
    timer:stop()
    local entry = syncManager.entries[keyFor(sprite)]
    if not entry then return end
    doExport(entry, false)
  end

  local listener = nil
  if sprite.events and config.get("auto_sync_default") then
    listener = sprite.events:on('change', function()
      if timer.isRunning then timer:stop() end
      timer:start()
    end)
  end

  syncManager.entries[keyFor(sprite)] = {
    sprite = sprite,
    job = job,
    plugin = plugin,
    state = state,
    config = config,
    logger = logger,
    relayClient = relayClient,
    timer = timer,
    listener = listener,
    closeListener = (sprite.events and sprite.events:on('close', function() syncManager.detach_sprite_sync(sprite) end)) or nil,
    enabled = config.get("auto_sync_default")
  }

  return true
end

function syncManager.toggle(sprite, enabled)
  local entry = syncManager.entries[keyFor(sprite)]
  if not entry then return false, "No sync entry" end

  if enabled == nil then enabled = not entry.enabled end
  entry.enabled = enabled

  if not sprite.events then return false, "Sprite events unavailable" end

  if entry.listener then
    pcall(function() sprite.events:off(entry.listener) end)
    entry.listener = nil
  end

  if enabled then
    entry.listener = sprite.events:on('change', function()
      if entry.timer.isRunning then entry.timer:stop() end
      entry.timer:start()
    end)
    return true, "Auto sync enabled"
  else
    pcall(function() if entry.timer then entry.timer:stop() end end)
    return true, "Auto sync disabled"
  end
end

function syncManager.sync_now(sprite)
  local entry = syncManager.entries[keyFor(sprite)]
  if not entry then return false, "No sync entry" end
  return doExport(entry, true)
end

function syncManager.detach_all()
  local pending = {}
  for _, entry in pairs(syncManager.entries) do
    table.insert(pending, entry.sprite)
  end
  for _, sprite in ipairs(pending) do
    syncManager.detach_sprite_sync(sprite)
  end
end

return syncManager
