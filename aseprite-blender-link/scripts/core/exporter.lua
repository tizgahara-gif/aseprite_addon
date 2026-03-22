local validator = _G.BLENDER_LINK_LOAD("core/validator.lua")
local constants = _G.BLENDER_LINK_LOAD("core/constants.lua")

local exporter = {}

function exporter.export(state, config)
  local job = state.job
  local sprite = state.sprite or app.activeSprite

  local validation = validator.validate(job, sprite, state)
  state.last_validation = validation
  state.validation_state = validation.state
  if validation.state == constants.validationState.ERROR then
    state.dirty_state = constants.dirtyState.VALIDATION_FAILED
    return false, "Validation has ERROR; export blocked", validation
  end

  local fileExists = app.fs.isFile(job.export_image_path)
  if fileExists and config.get("export_overwrite_confirmation") then
    local confirm = app.alert{
      title = "Overwrite export?",
      text = "Target file already exists:\n" .. job.export_image_path,
      buttons = {"Cancel", "Overwrite"}
    }
    if confirm ~= 2 then
      return false, "Export canceled by user", validation
    end
  end

  local originalVisibility = {}
  for i, layer in ipairs(sprite.layers) do
    originalVisibility[i] = layer.isVisible
    if layer.name:sub(1, 6) == "GUIDE_" then
      layer.isVisible = false
    end
  end

  local ok, err = pcall(function()
    sprite:saveCopyAs(job.export_image_path)
  end)

  for i, layer in ipairs(sprite.layers) do
    layer.isVisible = originalVisibility[i]
  end

  if not ok then
    return false, tostring(err), validation
  end

  state.dirty_state = constants.dirtyState.EXPORTED_TO_TARGET
  return true, job.export_image_path, validation
end

return exporter
