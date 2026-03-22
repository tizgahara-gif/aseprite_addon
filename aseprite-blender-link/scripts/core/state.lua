local constants = _G.BLENDER_LINK_LOAD("core/constants.lua")

local state = {
  sprite = nil,
  jobPath = nil,
  job = nil,
  current_job_id = nil,
  current_asset_id = nil,
  current_asset_name = nil,
  current_map_type = nil,
  current_revision = nil,
  source_image_path = nil,
  export_image_path = nil,
  loaded_palette_path = nil,
  loaded_guide_paths = {},
  validation_state = constants.validationState.UNKNOWN,
  dirty_state = constants.dirtyState.CLEAN,
  external_change_state = constants.externalChangeState.NONE,
  last_validation = nil
}

function state.reset()
  state.sprite = nil
  state.jobPath = nil
  state.job = nil
  state.current_job_id = nil
  state.current_asset_id = nil
  state.current_asset_name = nil
  state.current_map_type = nil
  state.current_revision = nil
  state.source_image_path = nil
  state.export_image_path = nil
  state.loaded_palette_path = nil
  state.loaded_guide_paths = {}
  state.validation_state = constants.validationState.UNKNOWN
  state.dirty_state = constants.dirtyState.CLEAN
  state.external_change_state = constants.externalChangeState.NONE
  state.last_validation = nil
end

function state.setJob(jobPath, job, sprite)
  state.jobPath = jobPath
  state.job = job
  state.sprite = sprite
  state.current_job_id = (job.asset_object_name or "") .. ":" .. (job.image_name or "") .. ":" .. tostring(job.revision or "")
  state.current_asset_id = job.asset_object_name
  state.current_asset_name = job.image_name or job.asset_name
  state.current_map_type = job.map_type
  state.current_revision = job.revision
  state.source_image_path = job.source_image_path
  state.export_image_path = job.export_image_path
  state.loaded_palette_path = nil
  state.loaded_guide_paths = {}
  state.validation_state = constants.validationState.UNKNOWN
  state.dirty_state = constants.dirtyState.CLEAN
  state.external_change_state = constants.externalChangeState.NONE
  state.last_validation = nil
end

return state
