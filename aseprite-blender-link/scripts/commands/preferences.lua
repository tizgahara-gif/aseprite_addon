local command = {}

local function toNumberOr(current, text)
  local n = tonumber(text)
  if not n or n <= 0 then return current end
  return math.floor(n)
end

function command.run(ctx)
  local dlg = Dialog("Blender Link Preferences")
  dlg:entry{ id = "default_job_folder", label = "Job Folder", text = ctx.config.get("default_job_folder") or "" }
  dlg:entry{ id = "recent_jobs_limit", label = "Recent Limit", text = tostring(ctx.config.get("recent_jobs_limit") or 20) }
  dlg:check{ id = "auto_validate_before_export", label = "Auto Validate", selected = ctx.config.get("auto_validate_before_export") }
  dlg:check{ id = "auto_load_palette", label = "Auto Palette", selected = ctx.config.get("auto_load_palette") }
  dlg:check{ id = "auto_load_guides", label = "Auto Guides", selected = ctx.config.get("auto_load_guides") }
  dlg:check{ id = "lock_palette_default", label = "Lock Palette", selected = ctx.config.get("lock_palette_default") }
  dlg:check{ id = "show_guides_by_default", label = "Show Guides", selected = ctx.config.get("show_guides_by_default") }
  dlg:check{ id = "write_log_file", label = "Write Log", selected = ctx.config.get("write_log_file") }
  dlg:entry{ id = "log_file_path", label = "Log Path", text = ctx.config.get("log_file_path") or "" }
  dlg:check{ id = "export_overwrite_confirmation", label = "Confirm Overwrite", selected = ctx.config.get("export_overwrite_confirmation") }
  dlg:check{ id = "enable_debug_mode", label = "Debug Mode", selected = ctx.config.get("enable_debug_mode") }
  dlg:button{ id = "save", text = "Save" }
  dlg:button{ id = "cancel", text = "Cancel" }
  dlg:show{ wait = true }

  local d = dlg.data
  if not d then return end

  ctx.config.set("default_job_folder", d.default_job_folder or "")
  ctx.config.set("recent_jobs_limit", toNumberOr(ctx.config.get("recent_jobs_limit"), d.recent_jobs_limit))
  ctx.config.set("auto_validate_before_export", d.auto_validate_before_export)
  ctx.config.set("auto_load_palette", d.auto_load_palette)
  ctx.config.set("auto_load_guides", d.auto_load_guides)
  ctx.config.set("lock_palette_default", d.lock_palette_default)
  ctx.config.set("show_guides_by_default", d.show_guides_by_default)
  ctx.config.set("write_log_file", d.write_log_file)
  ctx.config.set("log_file_path", d.log_file_path or "")
  ctx.config.set("export_overwrite_confirmation", d.export_overwrite_confirmation)
  ctx.config.set("enable_debug_mode", d.enable_debug_mode)

  local ok, err = ctx.config.save()
  if ok then
    app.alert("Preferences saved")
    ctx.logger.info("Preferences updated")
  else
    app.alert("Failed to save preferences: " .. tostring(err))
  end
end

return command
