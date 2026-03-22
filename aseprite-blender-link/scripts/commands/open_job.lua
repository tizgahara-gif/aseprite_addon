local parser = _G.BLENDER_LINK_LOAD("core/job_parser.lua")
local paletteManager = _G.BLENDER_LINK_LOAD("core/palette_manager.lua")
local guideManager = _G.BLENDER_LINK_LOAD("core/guide_manager.lua")
local layerTemplate = _G.BLENDER_LINK_LOAD("core/layer_template.lua")
local dialogs = _G.BLENDER_LINK_LOAD("ui/dialogs.lua")

local openJob = {}

local function isApiAvailable()
  if not app or not app.fs then
    return false, "Aseprite app.fs API is unavailable"
  end
  if type(json) ~= "table" or type(json.decode) ~= "function" then
    return false, "json.decode() is unavailable (Aseprite v1.3-rc5+ required)"
  end
  if type(app.open) ~= "function" then
    return false, "app.open() is unavailable"
  end
  return true
end

function openJob.openByPath(ctx, jobPath)
  if parser.setLogger then parser.setLogger(ctx.logger) end
  local okApi, apiErr = isApiAvailable()
  if not okApi then
    dialogs.showError("Required Aseprite API is missing", "Job JSON and source image were not opened.", apiErr)
    return false
  end

  if not jobPath or jobPath == "" then
    dialogs.showError("Job path is empty", "No file was opened.", "Enter a valid .json path and retry.")
    return false
  end

  if not app.fs.isFile(jobPath) then
    dialogs.showError("Job JSON path does not exist", "No file was opened.", "Check the path and file permissions.")
    return false
  end

  local job, errors = parser.parse(jobPath)
  if not job then
    dialogs.showError("Job JSON validation failed", "Job and source image were not opened.", table.concat(errors or {}, "\n"))
    ctx.logger.error("Job parse failed: " .. table.concat(errors or {}, "; "))
    return false
  end

  if not app.fs.isFile(job.source_image_path) then
    dialogs.showError("Source image does not exist", "No sprite was opened.", "Check task.source_path in job JSON.")
    return false
  end

  local sprite = app.open(job.source_image_path)
  if not sprite then
    dialogs.showError("Failed to open source PNG", "No sprite was opened.", "Check source file path and access rights.")
    return false
  end

  ctx.state.setJob(jobPath, job, sprite)

  if ctx.syncManager then
    ctx.syncManager.attach_sprite_sync(sprite, job, ctx.plugin, ctx.state, ctx.config, ctx.logger, ctx.relayClient)
  end

  if job.locked_constraints.lock_palette == nil then
    job.locked_constraints.lock_palette = ctx.config.get("lock_palette_default")
  end

  if ctx.config.get("auto_load_palette") and job.palette_path and job.palette_path ~= "" then
    local okPalette, errPalette = paletteManager.load(sprite, job.palette_path)
    if okPalette then
      ctx.state.loaded_palette_path = job.palette_path
    else
      dialogs.showWarning("Palette load failed: " .. tostring(errPalette))
    end
  end

  if ctx.config.get("auto_load_guides") then
    local loaded, warnings = guideManager.loadGuides(sprite, job)
    ctx.state.loaded_guide_paths = loaded
    if #warnings > 0 then dialogs.showWarning(table.concat(warnings, "\n")) end
  end

  if job.layer_template and job.layer_template ~= "" then
    local okTemplate, errTemplate = layerTemplate.apply(sprite, job.layer_template)
    if not okTemplate then dialogs.showWarning("Layer template was not applied: " .. tostring(errTemplate)) end
  end

  ctx.config.addRecentJob(jobPath)
  ctx.config.set("default_job_folder", app.fs.filePath(jobPath))
  ctx.config.save()
  ctx.logger.info("Opened job: " .. (job.image_name or "unknown") .. " / rev " .. tostring(job.revision or "?"))

  if job.map_type_unknown then
    dialogs.showWarning("Unknown map_type detected. Treated as CUSTOM (UI shows unknown).")
  end

  dialogs.showInfo("Job opened:\n" .. job.asset_name .. " / " .. job.map_type)
  return true
end

function openJob.run(ctx)
  local defaultFolder = ctx.config.get("default_job_folder") or ""
  local prefill = defaultFolder ~= "" and app.fs.joinPath(defaultFolder, "") or ""

  local dlg = Dialog("Open Blender Job")
  dlg:entry{ id = "job_path", label = "Job JSON", text = prefill }
  dlg:button{ id = "open", text = "Open" }
  dlg:button{ id = "cancel", text = "Cancel" }
  dlg:show{ wait = true }

  local data = dlg.data
  if not data or not data.job_path then return end

  local path = data.job_path:gsub("^%s+", ""):gsub("%s+$", "")
  if path == "" then
    dialogs.showError("Job path is empty", "No file was opened.", "Enter a valid job JSON path.")
    return
  end

  openJob.openByPath(ctx, path)
end

return openJob
