local logger = { cfg = nil }

local function now()
  return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

local function emit(level, message)
  local line = string.format("[%s] [%s] %s", now(), level, tostring(message))
  print(line)
  if not logger.cfg then return end
  if not logger.cfg.get("write_log_file") then return end
  local logPath = logger.cfg.get("log_file_path")
  if not logPath or logPath == "" then return end
  pcall(function()
    local f = io.open(logPath, "a")
    if f then
      f:write(line .. "\n")
      f:close()
    end
  end)
end

function logger.setConfig(cfg)
  logger.cfg = cfg
end
function logger.info(msg) emit("INFO", msg) end
function logger.warn(msg) emit("WARN", msg) end
function logger.error(msg) emit("ERROR", msg) end
function logger.debug(msg)
  if logger.cfg and logger.cfg.get("enable_debug_mode") then emit("DEBUG", msg) end
end

return logger
