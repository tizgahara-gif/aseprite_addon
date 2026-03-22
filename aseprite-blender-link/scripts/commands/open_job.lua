local parser = _G.BLENDER_LINK_LOAD("core/job_parser.lua")
local paletteManager = _G.BLENDER_LINK_LOAD("core/palette_manager.lua")
local guideManager = _G.BLENDER_LINK_LOAD("core/guide_manager.lua")
local layerTemplate = _G.BLENDER_LINK_LOAD("core/layer_template.lua")
local dialogs = _G.BLENDER_LINK_LOAD("ui/dialogs.lua")

local openJob = {}

function openJob.openByPath(ctx, jobPath)
  local job, errors = parser.parse(jobPath)
  if not job then
    dialogs.showError("Job JSON validation failed", "Job was not opened.", table.concat(errors or {}, "\n"))
    ctx.logger.error("Job parse failed: " .. table.concat(errors or {}, "; "))
    return false
  end

  if not app.fs.isFile(job.source_image_path) then
    dialogs.showError("Source image does not exist", "No document opened.", "Check source_image_path in job JSON.")
    return false
  end

  local sprite = app.open(job.source_image_path)
  if not sprite then
    dialogs.showError("Failed to open source PNG", "No document opened.", "Check file permissions/path.")
    return false
  end

  ctx.state.setJob(jobPath, job, sprite)

  if job.locked_constraints.lock_palette == nil then
    job.locked_constraints.lock_palette = ctx.config.get("lock_palette_default")
  end

  if ctx.config.get("auto_load_palette") and job.palette_path and job.palette_path ~= "" then
    local ok, err = paletteManager.load(sprite, job.palette_path)
    if ok then
      ctx.state.loaded_palette_path = job.palette_path
    else
      dialogs.showWarning("Palette load failed: " .. tostring(err))
    end
  end

  if ctx.config.get("auto_load_guides") then
    local loaded, warnings = guideManager.loadGuides(sprite, job)
    ctx.state.loaded_guide_paths = loaded
    if #warnings > 0 then dialogs.showWarning(table.concat(warnings, "\n")) end
  end

  if job.layer_template and job.layer_template ~= "" then
    local ok, err = layerTemplate.apply(sprite, job.layer_template)
    if not ok then dialogs.showWarning("Layer template was not applied: " .. tostring(err)) end
  end

  ctx.config.addRecentJob(jobPath)
  ctx.config.set("default_job_folder", app.fs.filePath(jobPath))
  ctx.config.save()
  ctx.logger.info("Opened job: " .. job.job_id)

  if job.map_type_unknown then
    dialogs.showWarning("Unknown map_type detected. Treated as CUSTOM (UI shows unknown).")
  end

  dialogs.showInfo("Job opened:\n" .. job.asset_name .. " / " .. job.map_type)
  return true
end

function openJob.run(ctx)
  local filePath = app.fs.fileDialog{
    title = "Open Blender Job JSON",
    open = true,
    filename = ctx.config.get("default_job_folder")
  }

  if filePath and filePath ~= "" then
    openJob.openByPath(ctx, filePath)
  end
end

return openJob
