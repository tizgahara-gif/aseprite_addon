local constants = _G.BLENDER_LINK_LOAD("core/constants.lua")

local config = {
  data = {},
  plugin = nil
}

local function copyDefaults()
  local out = {}
  for k, v in pairs(constants.defaults) do
    if type(v) == "table" then
      local t = {}
      for i, item in ipairs(v) do t[i] = item end
      out[k] = t
    else
      out[k] = v
    end
  end
  return out
end

local function sanitize(data)
  local d = copyDefaults()
  if type(data) ~= "table" then return d end
  for key, defaultValue in pairs(constants.defaults) do
    local v = data[key]
    if type(defaultValue) == "boolean" then
      d[key] = type(v) == "boolean" and v or defaultValue
    elseif type(defaultValue) == "number" then
      d[key] = (type(v) == "number" and v > 0) and math.floor(v) or defaultValue
    elseif type(defaultValue) == "string" then
      d[key] = type(v) == "string" and v or defaultValue
    elseif type(defaultValue) == "table" then
      d[key] = type(v) == "table" and v or defaultValue
    end
  end
  return d
end

local function persist()
  if not config.plugin then return false, "Plugin not attached" end
  config.plugin.preferences.data = json.encode(config.data)
  return true
end

function config.load(plugin)
  config.plugin = plugin
  local encoded = plugin.preferences.data
  if type(encoded) == "string" and encoded ~= "" then
    local ok, parsed = pcall(function() return json.decode(encoded) end)
    config.data = sanitize(ok and parsed or nil)
  else
    config.data = copyDefaults()
  end
end

function config.save()
  local ok, err = pcall(persist)
  return ok, err
end

function config.get(key)
  return config.data[key]
end

function config.set(key, value)
  config.data[key] = value
end

function config.addRecentJob(path)
  if not path or path == "" then return end
  local recent = { path }
  for _, p in ipairs(config.data.recent_jobs or {}) do
    if p ~= path and app.fs.isFile(p) then
      table.insert(recent, p)
    end
  end
  local max = config.data.recent_jobs_limit or 20
  while #recent > max do table.remove(recent) end
  config.data.recent_jobs = recent
end

return config
