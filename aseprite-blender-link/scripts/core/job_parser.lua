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
    return errors
  end

  if raw.schema == nil then addError(errors, "Missing required field: schema") end
  if raw.created_at == nil then addError(errors, "Missing required field: created_at") end
  if raw.revision == nil then addError(errors, "Missing required field: revision") end
  if raw.revision_tag == nil then addError(errors, "Missing required field: revision_tag") end

  if type(raw.asset) ~= "table" then
    addError(errors, "Missing required object: asset")
  else
    if raw.asset.object_name == nil then addError(errors, "Missing required field: asset.object_name") end
    if raw.asset.material_name == nil then addError(errors, "Missing required field: asset.material_name") end
    if raw.asset.image_name == nil then addError(errors, "Missing required field: asset.image_name") end
    if raw.asset.image_path == nil then addError(errors, "Missing required field: asset.image_path") end
  end

  if type(raw.task) ~= "table" then
    addError(errors, "Missing required object: task")
  else
    if raw.task.map_type == nil then addError(errors, "Missing required field: task.map_type") end
    if raw.task.source_path == nil then addError(errors, "Missing required field: task.source_path") end
    if raw.task.export_path == nil then addError(errors, "Missing required field: task.export_path") end
    if raw.task.source_path == "" then addError(errors, "task.source_path cannot be empty") end
    if raw.task.export_path == "" then addError(errors, "task.export_path cannot be empty") end
  end

  return errors
end

local function parseGuides(jobPath, raw)
  local guides = raw.task and raw.task.guides or {}
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

  local errors = validateSchema(raw)
  if #errors > 0 then return nil, errors end

  local mapType, unknownMapType = sanitizeMapType(raw.task.map_type)
  local guideSet = parseGuides(jobPath, raw)

  local job = {
    schema = raw.schema,
    created_at = raw.created_at,
    revision = raw.revision,
    revision_tag = raw.revision_tag,

    asset = raw.asset,
    asset_name = raw.asset.image_name,
    asset_object_name = raw.asset.object_name,
    asset_material_name = raw.asset.material_name,
    image_name = raw.asset.image_name,

    map_type = mapType,
    map_type_unknown = unknownMapType,

    source_image_path = paths.resolve(jobPath, raw.task.source_path),
    export_image_path = paths.resolve(jobPath, raw.task.export_path),

    palette_path = guideSet.palette_path,
    uv_guide_path = guideSet.uv_guide_path,
    id_map_path = guideSet.id_map_path,
    mask_paths = guideSet.mask_paths,

    layer_template = raw.task.layer_template or raw.layer_template,
    locked_constraints = raw.task.locked_constraints or raw.locked_constraints or {},

    width = raw.task.width,
    height = raw.task.height,
    color_mode = raw.task.color_mode,

    raw = raw
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
