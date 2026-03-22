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

  local payload = raw.data or raw
  if type(payload) ~= "table" then
    addError(errors, "Payload JSON must be an object")
    return errors, nil
  end

  if payload.schema == nil then addError(errors, "Missing required field: schema") end
  if payload.revision == nil then addError(errors, "Missing required field: revision") end
  if payload.revision_tag == nil then addError(errors, "Missing required field: revision_tag") end

  if type(payload.asset) ~= "table" then
    addError(errors, "Missing required object: asset")
  else
    if payload.asset.object_name == nil then addError(errors, "Missing required field: asset.object_name") end
    if payload.asset.material_name == nil then addError(errors, "Missing required field: asset.material_name") end
    if payload.asset.image_name == nil then addError(errors, "Missing required field: asset.image_name") end
    if payload.asset.image_path == nil then addError(errors, "Missing required field: asset.image_path") end
  end

  if type(payload.task) ~= "table" then
    addError(errors, "Missing required object: task")
  else
    if payload.task.map_type == nil then addError(errors, "Missing required field: task.map_type") end
    if payload.task.source_path == nil then addError(errors, "Missing required field: task.source_path") end
    if payload.task.export_path == nil then addError(errors, "Missing required field: task.export_path") end
    if payload.task.source_path == "" then addError(errors, "task.source_path cannot be empty") end
    if payload.task.export_path == "" then addError(errors, "task.export_path cannot be empty") end
  end

  return errors, payload
end

local function parseGuides(jobPath, payload)
  local guides = payload.task and payload.task.guides
  local entries = {}

  local function push(name, value)
    if type(value) == "string" and value ~= "" then
      table.insert(entries, { name = name, path = paths.resolve(jobPath, value) })
    end
  end

  local uvPath = ""
  local idPath = ""
  local palettePath = ""

  if type(guides) == "table" and #guides > 0 then
    -- guides array (legacy/current Blender output)
    for i, p in ipairs(guides) do
      if i == 1 then
        push("GUIDE_UV", p)
        uvPath = paths.resolve(jobPath, p)
      else
        push(string.format("GUIDE_EXTRA_%02d", i - 1), p)
      end
    end
  elseif type(guides) == "table" then
    -- guides object
    push("GUIDE_UV", guides.uv_guide_path)
    push("GUIDE_ID", guides.id_map_path)
    push("GUIDE_PALETTE", guides.palette_preview_path)

    if type(guides.mask_paths) == "table" then
      for i, p in ipairs(guides.mask_paths) do
        push(string.format("GUIDE_MASK_%02d", i), p)
      end
    end
    if type(guides.extra_paths) == "table" then
      for i, p in ipairs(guides.extra_paths) do
        push(string.format("GUIDE_EXTRA_%02d", i), p)
      end
    end

    uvPath = guides.uv_guide_path and paths.resolve(jobPath, guides.uv_guide_path) or ""
    idPath = guides.id_map_path and paths.resolve(jobPath, guides.id_map_path) or ""
    palettePath = guides.palette_path and paths.resolve(jobPath, guides.palette_path) or ""
  else
    -- nil or invalid => empty guides
  end

  return {
    palette_path = palettePath,
    uv_guide_path = uvPath,
    id_map_path = idPath,
    entries = entries
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

  local errors, payload = validateSchema(raw)
  if #errors > 0 then return nil, errors end

  local mapType, unknownMapType = sanitizeMapType(payload.task.map_type)
  local guideSet = parseGuides(jobPath, payload)

  local job = {
    schema = payload.schema,
    revision = payload.revision,
    revision_tag = payload.revision_tag,

    asset = payload.asset,
    asset_name = payload.asset.image_name,
    asset_object_name = payload.asset.object_name,
    asset_material_name = payload.asset.material_name,
    image_name = payload.asset.image_name,

    map_type = mapType,
    map_type_unknown = unknownMapType,

    task = {
      map_type = mapType,
      source_path = paths.resolve(jobPath, payload.task.source_path),
      export_path = paths.resolve(jobPath, payload.task.export_path),
      guides = payload.task.guides,
      layer_template = payload.task.layer_template,
      locked_constraints = payload.task.locked_constraints or {},
      width = payload.task.width,
      height = payload.task.height,
      color_mode = payload.task.color_mode
    },

    source_image_path = paths.resolve(jobPath, payload.task.source_path),
    export_image_path = paths.resolve(jobPath, payload.task.export_path),

    palette_path = guideSet.palette_path,
    uv_guide_path = guideSet.uv_guide_path,
    id_map_path = guideSet.id_map_path,
    guide_entries = guideSet.entries,

    layer_template = payload.task.layer_template,
    locked_constraints = payload.task.locked_constraints or {},

    width = payload.task.width,
    height = payload.task.height,
    color_mode = payload.task.color_mode,

    raw = raw,
    payload = payload
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
