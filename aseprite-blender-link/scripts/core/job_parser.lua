local constants = _G.BLENDER_LINK_LOAD("core/constants.lua")
local paths = _G.BLENDER_LINK_LOAD("core/paths.lua")

local parser = {}

local function validateSchema(raw)
  local errors = {}
  for _, field in ipairs(constants.requiredFields) do
    if raw[field] == nil then
      table.insert(errors, "Missing required field: " .. field)
    end
  end

  if type(raw.width) ~= "number" or raw.width <= 0 or math.floor(raw.width) ~= raw.width then
    table.insert(errors, "width must be a positive integer")
  end
  if type(raw.height) ~= "number" or raw.height <= 0 or math.floor(raw.height) ~= raw.height then
    table.insert(errors, "height must be a positive integer")
  end
  if type(raw.revision) ~= "number" or math.floor(raw.revision) ~= raw.revision then
    table.insert(errors, "revision must be an integer")
  end
  if raw.source_image_path == "" then table.insert(errors, "source_image_path cannot be empty") end
  if raw.export_image_path == "" then table.insert(errors, "export_image_path cannot be empty") end

  return errors
end

local function sanitizeMapType(rawMapType)
  if constants.mapTypes[rawMapType] then return rawMapType, false end
  return "CUSTOM", true
end

function parser.parse(jobPath)
  local file = io.open(jobPath, "r")
  if not file then return nil, {"Could not open job JSON file"} end
  local text = file:read("*a")
  file:close()

  local ok, raw = pcall(function() return json.decode(text) end)
  if not ok or type(raw) ~= "table" then
    return nil, {"Invalid JSON format"}
  end

  local errors = validateSchema(raw)
  if #errors > 0 then return nil, errors end

  local mapType, unknownMapType = sanitizeMapType(raw.map_type)

  local job = {
    job_id = raw.job_id,
    asset_id = raw.asset_id,
    asset_name = raw.asset_name,
    map_type = mapType,
    map_type_unknown = unknownMapType,
    source_image_path = paths.resolve(jobPath, raw.source_image_path),
    export_image_path = paths.resolve(jobPath, raw.export_image_path),
    width = raw.width,
    height = raw.height,
    color_mode = raw.color_mode,
    revision = raw.revision,
    created_at = raw.created_at,
    updated_at = raw.updated_at,
    palette_path = paths.resolve(jobPath, raw.palette_path),
    uv_guide_path = paths.resolve(jobPath, raw.uv_guide_path),
    id_map_path = paths.resolve(jobPath, raw.id_map_path),
    mask_paths = {},
    layer_template = raw.layer_template,
    locked_constraints = raw.locked_constraints or {},
    raw = raw
  }

  if type(raw.mask_paths) == "table" then
    for _, p in ipairs(raw.mask_paths) do
      table.insert(job.mask_paths, paths.resolve(jobPath, p))
    end
  end

  for _, key in ipairs(constants.lockedConstraintKeys) do
    local v = job.locked_constraints[key]
    if v ~= nil and type(v) ~= "boolean" then
      return nil, {"locked_constraints." .. key .. " must be boolean"}
    end
  end

  return job, nil
end

return parser
