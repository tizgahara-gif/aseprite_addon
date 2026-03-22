local statusManager = {}

function statusManager.summary(state)
  local job = state.job
  if not job then return "No active Blender job." end
  return table.concat({
    "Asset: " .. tostring(job.asset_name),
    "Map: " .. tostring(job.map_type .. (job.map_type_unknown and " (unknown)" or "")),
    "Resolution: " .. (job.width and job.height and (tostring(job.width) .. "x" .. tostring(job.height)) or "(from sprite)"),
    "Revision: " .. tostring(job.revision),
    "Palette: " .. (state.loaded_palette_path and "loaded" or "not loaded"),
    "Guides: " .. ((state.loaded_guide_paths and #state.loaded_guide_paths > 0) and "loaded" or "not loaded"),
    "Dirty: " .. tostring(state.dirty_state),
    "Validation: " .. tostring(state.validation_state)
  }, "\n")
end

return statusManager
