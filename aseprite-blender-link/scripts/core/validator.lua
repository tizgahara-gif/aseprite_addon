local constants = _G.BLENDER_LINK_LOAD("core/constants.lua")
local paths = _G.BLENDER_LINK_LOAD("core/paths.lua")

local validator = {}

local function add(out, level, message)
  table.insert(out, { level = level, message = message })
end

local function hasLayer(sprite, name)
  for _, layer in ipairs(sprite.layers) do
    if layer.name == name then return true end
  end
  return false
end

function validator.validate(job, sprite, state)
  local findings = {}
  if not job then
    add(findings, "ERROR", "No job metadata loaded")
    return { state = constants.validationState.ERROR, findings = findings }
  end
  if not sprite then
    add(findings, "ERROR", "No sprite loaded")
    return { state = constants.validationState.ERROR, findings = findings }
  end

  if job.width and job.height then
    if sprite.width ~= job.width or sprite.height ~= job.height then
      add(findings, "ERROR", "Resolution mismatch with job")
    end
  else
    add(findings, "WARNING", "Job does not define width/height; resolution lock skipped")
  end

  local mode = (sprite.colorMode == ColorMode.RGB and "rgb") or (sprite.colorMode == ColorMode.INDEXED and "indexed") or "unknown"
  if job.color_mode then
    if job.color_mode:lower() ~= mode then
      add(findings, "ERROR", "Color mode mismatch")
    end
  else
    add(findings, "WARNING", "Job does not define color_mode; color-mode lock skipped")
  end

  local lockPalette = job.locked_constraints.lock_palette
  if lockPalette == nil then lockPalette = false end
  if job.palette_path and job.palette_path ~= "" and not app.fs.isFile(job.palette_path) then
    add(findings, "WARNING", "Palette path specified but file missing")
  end
  if lockPalette and job.palette_path and job.palette_path ~= "" and (not state.loaded_palette_path or state.loaded_palette_path == "") then
    add(findings, "ERROR", "Palette is locked but not loaded")
  end

  if job.locked_constraints.lock_required_layers and job.layer_template then
    local template = constants.layerTemplates[job.layer_template] or {}
    for _, layerName in ipairs(template) do
      if not hasLayer(sprite, layerName) then
        add(findings, "ERROR", "Missing required layer: " .. layerName)
      end
    end
  end

  for _, layer in ipairs(sprite.layers) do
    if layer.name:sub(1, 6) == "GUIDE_" and layer.isVisible then
      add(findings, "WARNING", "Guide layer visible; exporter will exclude guide layers")
      break
    end
  end

  if not paths.canWrite(job.export_image_path) then
    add(findings, "ERROR", "Export target directory does not exist")
  end

  if job.map_type_unknown then
    add(findings, "WARNING", "Unknown map_type detected. Treated as CUSTOM")
  end

  local finalState = constants.validationState.OK
  for _, item in ipairs(findings) do
    if item.level == "ERROR" then finalState = constants.validationState.ERROR break end
    if item.level == "WARNING" then finalState = constants.validationState.WARNING end
  end

  return { state = finalState, findings = findings }
end

return validator
