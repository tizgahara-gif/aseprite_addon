local constants = {}

constants.mapTypes = {
  BASECOLOR = true,
  EMISSIVE = true,
  OPACITY_MASK = true,
  ID_MAP = true,
  CUSTOM = true
}

constants.lockedConstraintKeys = {
  "lock_resolution",
  "lock_palette",
  "lock_color_mode",
  "lock_required_layers"
}

constants.dirtyState = {
  CLEAN = "CLEAN",
  MODIFIED_UNSAVED = "MODIFIED_UNSAVED",
  SAVED_TO_SOURCE_ONLY = "SAVED_TO_SOURCE_ONLY",
  EXPORTED_TO_TARGET = "EXPORTED_TO_TARGET",
  VALIDATION_FAILED = "VALIDATION_FAILED"
}

constants.externalChangeState = {
  NONE = "NONE",
  SOURCE_CHANGED_EXTERNALLY = "SOURCE_CHANGED_EXTERNALLY",
  TARGET_CHANGED_EXTERNALLY = "TARGET_CHANGED_EXTERNALLY",
  JOB_OUTDATED = "JOB_OUTDATED"
}

constants.validationState = {
  UNKNOWN = "UNKNOWN",
  OK = "OK",
  WARNING = "WARNING",
  ERROR = "ERROR"
}

constants.guideLayerPrefix = "GUIDE_"
constants.layerTemplates = {
  base_template_v1 = { "BASE", "SHADE", "HIGHLIGHT", "EMISSIVE", "MASK" }
}

constants.defaults = {
  default_job_folder = "",
  recent_jobs_limit = 20,
  auto_validate_before_export = true,
  auto_load_palette = true,
  auto_load_guides = true,
  lock_palette_default = true,
  show_guides_by_default = true,
  write_log_file = false,
  log_file_path = "",
  export_overwrite_confirmation = true,
  enable_debug_mode = false,
  recent_jobs = {}
}

constants.commandIds = {
  OPEN_JOB = "blender_link_open_job",
  OPEN_RECENT = "blender_link_open_recent",
  JOB_BROWSER = "blender_link_job_browser",
  RELOAD_JOB = "blender_link_reload_job",
  VALIDATE = "blender_link_validate",
  EXPORT = "blender_link_export",
  OPEN_EXPORT_FOLDER = "blender_link_open_export_folder",
  PREFERENCES = "blender_link_preferences",
  STATUS = "blender_link_status"
}

return constants
