local relay = {
  socket = nil,
  connected = false,
  url = nil
}

local function canUseWebSocket()
  return type(WebSocket) == "function" or type(WebSocket) == "table"
end

function relay.connect(config, logger)
  local url = config.get("relay_url")
  relay.url = url
  if not url or url == "" then
    relay.connected = false
    return false, "relay_url is empty"
  end
  if not canUseWebSocket() then
    relay.connected = false
    return false, "WebSocket API unavailable in this Aseprite build"
  end

  local ok, sock = pcall(function()
    if type(WebSocket) == "function" then
      return WebSocket{ url = url, deflate = config.get("deflate_enabled") }
    end
    return WebSocket.new(url)
  end)

  if not ok or not sock then
    relay.connected = false
    return false, "Failed to create WebSocket"
  end

  relay.socket = sock
  relay.connected = true
  if logger then logger.info("Relay connected: " .. url) end
  return true
end

function relay.disconnect(logger)
  if relay.socket then
    pcall(function() relay.socket:close() end)
  end
  relay.socket = nil
  relay.connected = false
  if logger then logger.info("Relay disconnected") end
end

function relay.sendText(payload, logger)
  if not relay.connected or not relay.socket then
    return false, "Relay not connected"
  end
  local ok, err = pcall(function()
    relay.socket:sendText(payload)
  end)
  if ok then return true end
  if logger then logger.warn("Relay send failed: " .. tostring(err)) end
  return false, tostring(err)
end

local function isoNow()
  return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

function relay.sendTextureExported(job, logger)
  local event = {
    event_id = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999)),
    type = "texture_exported",
    export_path = job.task and job.task.export_path or job.export_image_path,
    revision = job.revision,
    asset_name = job.asset_name,
    map_type = job.map_type,
    timestamp = isoNow()
  }
  local payload = json.encode(event)
  return relay.sendText(payload, logger)
end

return relay
