local constants = _G.BLENDER_LINK_LOAD("core/constants.lua")
local paths = _G.BLENDER_LINK_LOAD("core/paths.lua")

local parser = {}

local function sanitizeMapType(rawMapType)
  if constants.mapTypes[rawMapType] then return rawMapType, false end
  return "CUSTOM", true
end

local function addError(errors, msg)
  table.insert(errors, msg)
end

local function validateSchema(raw)
  local errors = {}
  if type(raw) ~= "table" then
    addError(errors, "Root JSON must be an object")
    return errors, nil
  end

  local data = raw.data
  if type(data) ~= "table" then
    addError(errors, "Missing required object: data")
    return errors, nil
  end

  if data.schema == nil then addError(errors, "Missing required field: data.schema") end
  if data.revision == nil then addError(errors, "Missing required field: data.revision") end
  if data.revision_tag == nil then addError(errors, "Missing required field: data.revision_tag") end

  if type(data.asset) ~= "table" then
    addError(errors, "Missing required object: data.asset")
  else
    if data.asset.object_name == nil then addError(errors, "Missing required field: data.asset.object_name") end
    if data.asset.material_name == nil then addError(errors, "Missing required field: data.asset.material_name") end
    if data.asset.image_name == nil then addError(errors, "Missing required field: data.asset.image_name") end
    if data.asset.image_path == nil then addError(errors, "Missing required field: data.asset.image_path") end
  end

  if type(data.task) ~= "table" then
    addError(errors, "Missing required object: data.task")
  else
    if data.task.map_type == nil then addError(errors, "Missing required field: data.task.map_type") end
    if data.task.source_path == nil then addError(errors, "Missing required field: data.task.source_path") end
    if data.task.export_path == nil then addError(errors, "Missing required field: data.task.export_path") end
    if data.task.guides == nil then addError(errors, "Missing required field: data.task.guides") end
    if data.task.source_path == "" then addError(errors, "data.task.source_path cannot be empty") end
    if data.task.export_path == "" then addError(errors, "data.task.export_path cannot be empty") end
  end

  return errors, data
end

local function parseGuides(jobPath, data)
  local guides = data.task and data.task.guides or {}
  if type(guides) ~= "table" then guides = {} end

  local maskPaths = {}
  if type(guides.mask_paths) == "table" then
    for _, p in ipairs(guides.mask_paths) do
      table.insert(maskPaths, paths.resolve(jobPath, p))
    end
  end

  return {
    palette_path = paths.resolve(jobPath, guides.palette_path),
    uv_guide_path = paths.resolve(jobPath, guides.uv_guide_path),
    id_map_path = paths.resolve(jobPath, guides.id_map_path),
    mask_paths = maskPaths
  }
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

  local errors, data = validateSchema(raw)
  if #errors > 0 then return nil, errors end

  local mapType, unknownMapType = sanitizeMapType(data.task.map_type)
  local guideSet = parseGuides(jobPath, data)

  local job = {
    schema = data.schema,
    revision = data.revision,
    revision_tag = data.revision_tag,

    asset = data.asset,
    asset_name = data.asset.image_name,
    asset_object_name = data.asset.object_name,
    asset_material_name = data.asset.material_name,
    image_name = data.asset.image_name,

    map_type = mapType,
    map_type_unknown = unknownMapType,

    source_image_path = paths.resolve(jobPath, data.task.source_path),
    export_image_path = paths.resolve(jobPath, data.task.export_path),

    palette_path = guideSet.palette_path,
    uv_guide_path = guideSet.uv_guide_path,
    id_map_path = guideSet.id_map_path,
    mask_paths = guideSet.mask_paths,

    layer_template = data.task.layer_template,
    locked_constraints = data.task.locked_constraints or {},

    width = data.task.width,
    height = data.task.height,
    color_mode = data.task.color_mode,

    raw = raw,
    data = data
  }

  for _, key in ipairs(constants.lockedConstraintKeys) do
    local v = job.locked_constraints[key]
    if v ~= nil and type(v) ~= "boolean" then
      return nil, {"locked_constraints." .. key .. " must be boolean"}
    end
  end

  return job, nil
end

return parser
