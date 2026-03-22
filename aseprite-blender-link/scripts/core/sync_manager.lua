local validator = _G.BLENDER_LINK_LOAD("core/validator.lua")

local syncManager = {
  entries = {}
}

local function log(entry, level, msg)
  if not entry or not entry.logger then return end
  local fn = entry.logger[level] or entry.logger.info
  fn(msg)
end

local function spriteId(sprite)
  local filename = (sprite and sprite.filename) and sprite.filename or "unsaved"
  return tostring(sprite) .. "|" .. filename
end

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
    if previous[i] ~= nil then layer.isVisible = previous[i] end
  end
end

local function exportNow(entry, force)
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

  if not ok then
    log(entry, "error", "Auto sync export failed: " .. tostring(err))
    return false, tostring(err)
  end

  entry.state.dirty_state = "EXPORTED_TO_TARGET"
  log(entry, "info", "Auto sync exported: " .. tostring(entry.job.task.export_path))

  if entry.relayClient then
    local sent, sendErr = entry.relayClient.sendTextureExported(entry.job, entry.logger)
    if not sent then log(entry, "warn", "Relay notify failed: " .. tostring(sendErr)) end
  end

  return true
end

function syncManager.detach_sprite_sync(sprite)
  if not sprite then return end
  local key = spriteId(sprite)
  local entry = syncManager.entries[key]
  if not entry then return end

  if entry.timer then
    pcall(function() entry.timer:stop() end)
    log(entry, "debug", "timer stopped for " .. key)
  end

  if entry.listenerCode and sprite.events then
    pcall(function() sprite.events:off(entry.listenerCode) end)
    log(entry, "debug", "listener removed for " .. key .. " code=" .. tostring(entry.listenerCode))
  end

  if entry.closeListenerCode and sprite.events then
    pcall(function() sprite.events:off(entry.closeListenerCode) end)
  end

  syncManager.entries[key] = nil
  log(entry, "info", "sync entry detached for " .. key)
end

function syncManager.attach_sprite_sync(sprite, job, plugin, state, config, logger, relayClient)
  if not sprite or not job or not job.task or not job.task.export_path then
    return false, "Missing sprite/job/export path"
  end

  local key = spriteId(sprite)
  syncManager.detach_sprite_sync(sprite)

  local entry = {
    sprite = sprite,
    job = job,
    plugin = plugin,
    state = state,
    config = config,
    logger = logger,
    relayClient = relayClient,
    pending = false
  }

  local debounce = tonumber(config.get("debounce_seconds") or 0.8) or 0.8
  if debounce <= 0 then debounce = 0.2 end

  local listenerCode = nil
  local closeListenerCode = nil
  local timer = nil

  local ok, attachErr = pcall(function()
    listenerCode = sprite.events:on('change', function()
      if not entry.enabled then return end
      entry.pending = true
      if entry.timer and entry.timer.isRunning then
        entry.timer:stop()
        log(entry, "debug", "timer stopped (debounce reset) for " .. key)
      end
      if entry.timer then
        entry.timer:start()
        log(entry, "debug", "timer started for " .. key)
      end
    end)
    log(entry, "debug", "listener attached for " .. key .. " code=" .. tostring(listenerCode))

    timer = Timer{
      interval = debounce,
      ontick = function()
        if not entry.pending then
          timer:stop()
          log(entry, "debug", "timer stopped (no pending) for " .. key)
          return
        end
        entry.pending = false
        timer:stop()
        log(entry, "debug", "timer fired for " .. key)
        exportNow(entry, false)
      end
    }
    log(entry, "debug", "timer created for " .. key .. " debounce=" .. tostring(debounce))

    closeListenerCode = sprite.events:on('close', function()
      syncManager.detach_sprite_sync(sprite)
    end)
    log(entry, "debug", "close-listener attached for " .. key .. " code=" .. tostring(closeListenerCode))
  end)

  if not ok then
    if timer then pcall(function() timer:stop() end) end
    if listenerCode and sprite.events then pcall(function() sprite.events:off(listenerCode) end) end
    if closeListenerCode and sprite.events then pcall(function() sprite.events:off(closeListenerCode) end) end
    if logger and logger.error then
      logger.error("sync entry attach failed for " .. key .. ": " .. tostring(attachErr))
    end
    return false, "Failed to attach auto sync: " .. tostring(attachErr)
  end

  entry.timer = timer
  entry.listenerCode = listenerCode
  entry.closeListenerCode = closeListenerCode
  entry.enabled = config.get("auto_sync_default")

  syncManager.entries[key] = entry
  log(entry, "info", "sync entry attached for " .. key .. " listener=" .. tostring(listenerCode) .. " closeListener=" .. tostring(closeListenerCode))
  return true
end

function syncManager.toggle(sprite, enabled)
  local entry = syncManager.entries[spriteId(sprite)]
  if not entry then return false, "Auto Sync is not attached to this sprite yet" end

  if enabled == nil then enabled = not entry.enabled end
  entry.enabled = enabled

  if not enabled and entry.timer then
    entry.pending = false
    pcall(function() entry.timer:stop() end)
    log(entry, "debug", "timer stopped by toggle")
  end

  return true, enabled and "Auto sync enabled" or "Auto sync disabled"
end

function syncManager.sync_now(sprite)
  local entry = syncManager.entries[spriteId(sprite)]
  if not entry then return false, "Auto Sync is not attached to this sprite yet" end
  return exportNow(entry, true)
end

function syncManager.detach_all()
  local sprites = {}
  for _, entry in pairs(syncManager.entries) do table.insert(sprites, entry.sprite) end
  for _, s in ipairs(sprites) do syncManager.detach_sprite_sync(s) end
end

return syncManager
