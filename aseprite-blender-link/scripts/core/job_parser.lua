local constants = _G.BLENDER_LINK_LOAD("core/constants.lua")
local paths = _G.BLENDER_LINK_LOAD("core/paths.lua")

local parser = {
  logger = nil
}

function parser.setLogger(logger)
  parser.logger = logger
end

local function logDebug(msg)
  if parser.logger and parser.logger.debug then
    parser.logger.debug(msg)
  else
    print("[BlenderLink][job_parser] " .. msg)
  end
end

local function sanitizeMapType(rawMapType)
  if constants.mapTypes[rawMapType] then return rawMapType, false end
  return "CUSTOM", true
end

local function addError(errors, msg)
  table.insert(errors, msg)
end

local function hasUtf8Bom(text)
  return #text >= 3 and text:byte(1) == 0xEF and text:byte(2) == 0xBB and text:byte(3) == 0xBF
end

local function stripUtf8Bom(text)
  if hasUtf8Bom(text) then
    return text:sub(4), true
  end
  return text, false
end

local function looksUtf16(text)
  if #text < 2 then return false, false end
  local b1, b2 = text:byte(1), text:byte(2)
  if b1 == 0xFF and b2 == 0xFE then return true, true end -- LE BOM
  if b1 == 0xFE and b2 == 0xFF then return true, true end -- BE BOM

  local zerosEven, zerosOdd = 0, 0
  local n = math.min(#text, 64)
  for i = 1, n do
    local c = text:byte(i)
    if c == 0 then
      if i % 2 == 0 then zerosEven = zerosEven + 1 else zerosOdd = zerosOdd + 1 end
    end
  end
  return (zerosEven > 8 or zerosOdd > 8), false
end

local function previewBytes(text, n)
  local limit = math.min(#text, n or 96)
  local out = {}
  for i = 1, limit do
    out[#out + 1] = string.format("%02X", text:byte(i))
  end
  return table.concat(out, " ")
end

local function safeIndex(obj, key)
  local ok, value = pcall(function() return obj[key] end)
  if ok then return value end
  return nil
end

local function validateSchema(raw)
  local errors = {}
  if raw == nil then
    addError(errors, "Decoded JSON is nil")
    return errors, nil
  end

  local payload = safeIndex(raw, "data")
  if payload == nil then payload = raw end

  if payload == nil then
    addError(errors, "Payload JSON is nil")
    return errors, nil
  end

  if safeIndex(payload, "schema") == nil then addError(errors, "Missing required field: schema") end
  if safeIndex(payload, "revision") == nil then addError(errors, "Missing required field: revision") end
  if safeIndex(payload, "revision_tag") == nil then addError(errors, "Missing required field: revision_tag") end

  local asset = safeIndex(payload, "asset")
  if asset == nil then
    addError(errors, "Missing required object: asset")
  else
    if safeIndex(asset, "object_name") == nil then addError(errors, "Missing required field: asset.object_name") end
    if safeIndex(asset, "material_name") == nil then addError(errors, "Missing required field: asset.material_name") end
    if safeIndex(asset, "image_name") == nil then addError(errors, "Missing required field: asset.image_name") end
    if safeIndex(asset, "image_path") == nil then addError(errors, "Missing required field: asset.image_path") end
  end

  local task = safeIndex(payload, "task")
  if task == nil then
    addError(errors, "Missing required object: task")
  else
    if safeIndex(task, "map_type") == nil then addError(errors, "Missing required field: task.map_type") end
    if safeIndex(task, "source_path") == nil then addError(errors, "Missing required field: task.source_path") end
    if safeIndex(task, "export_path") == nil then addError(errors, "Missing required field: task.export_path") end
    if safeIndex(task, "source_path") == "" then addError(errors, "task.source_path cannot be empty") end
    if safeIndex(task, "export_path") == "" then addError(errors, "task.export_path cannot be empty") end
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

  local uvPath, idPath, palettePath = "", "", ""

  if type(guides) == "table" and #guides > 0 then
    for i, p in ipairs(guides) do
      if i == 1 then
        push("GUIDE_UV", p)
        uvPath = paths.resolve(jobPath, p)
      else
        push(string.format("GUIDE_EXTRA_%02d", i - 1), p)
      end
    end
  elseif type(guides) == "table" then
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
  end

  return {
    palette_path = palettePath,
    uv_guide_path = uvPath,
    id_map_path = idPath,
    entries = entries
  }
end

function parser.parse(jobPath)
  logDebug("Parsing job JSON: " .. tostring(jobPath))
  local file = io.open(jobPath, "r")
  if not file then
    return nil, {
      "Could not open job JSON file",
      "Nothing was opened.",
      "Check job path and permissions: " .. tostring(jobPath)
    }
  end

  local text = file:read("*a")
  file:close()

  local size = #text
  if size == 0 then
    return nil, {
      "Job JSON is empty",
      "Job and source image were not opened.",
      "Re-generate from Blender and confirm UTF-8 JSON content."
    }
  end

  local utf16Likely, hadUtf16Bom = looksUtf16(text)
  local hadBom = hasUtf8Bom(text)
  logDebug("file_size=" .. tostring(size) .. " bom_utf8=" .. tostring(hadBom) .. " utf16_bom=" .. tostring(hadUtf16Bom))
  if utf16Likely then
    return nil, {
      "Job JSON appears to be UTF-16",
      "Job and source image were not opened.",
      "Job JSON is not UTF-8. Re-generate from Blender or re-save as UTF-8."
    }
  end

  local stripped, _ = stripUtf8Bom(text)
  local ok, raw = pcall(function() return json.decode(stripped) end)
  logDebug("decode_result_type=" .. tostring(type(raw)))
  if not ok or raw == nil then
    local preview = previewBytes(stripped, 128)
    logDebug("Decode failed for " .. tostring(jobPath))
    logDebug("file_size=" .. tostring(size) .. " bom_utf8=" .. tostring(hadBom) .. " utf16_bom=" .. tostring(hadUtf16Bom))
    logDebug("preview_hex=" .. preview)

    return nil, {
      "Job JSON decode failed (invalid JSON, BOM/encoding issue, or file corruption).",
      "Job and source image were not opened.",
      "Check UTF-8 encoding, remove invalid bytes, and validate JSON syntax."
    }
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
