local bootstrap = {}

function bootstrap.init(plugin, rootDir)
  if not json or type(json.decode) ~= "function" then
    app.alert("Blender Link requires Aseprite v1.3-rc5 or later (json.decode unavailable).")
    return
  end

  local load = _G.BLENDER_LINK_LOAD

  local constants = load("core/constants.lua")
  local config = load("core/config.lua")
  local logger = load("core/logger.lua")
  local state = load("core/state.lua")
  local dialogs = load("ui/dialogs.lua")
  local statusPanel = load("ui/status_panel.lua")

  local ctx = {
    config = config,
    logger = logger,
    state = state,
    rootDir = rootDir,
    plugin = plugin
  }

  local commands = {
    openJob = load("commands/open_job.lua"),
    openRecent = load("commands/open_recent.lua"),
    jobBrowser = load("commands/job_browser.lua"),
    reloadJob = load("commands/reload_job.lua"),
    validateTexture = load("commands/validate_texture.lua"),
    exportToBlender = load("commands/export_to_blender.lua"),
    openExportFolder = load("commands/open_export_folder.lua"),
    preferences = load("commands/preferences.lua")
  }

  config.load(plugin)
  logger.setConfig(config)
  logger.info("Extension bootstrapped")

  local function runWithErrors(fn)
    local ok, err = pcall(fn)
    if not ok then
      logger.error(err)
      dialogs.showError("Unexpected error", "Operation aborted safely.", "Check log file and retry.")
    end
  end

  plugin:newCommand{ id = constants.commandIds.OPEN_JOB, title = "Open Blender Job", group = "file_scripts", onclick = function() runWithErrors(function() commands.openJob.run(ctx) end) end }
  plugin:newCommand{ id = constants.commandIds.OPEN_RECENT, title = "Open Recent Job", group = "file_scripts", onclick = function() runWithErrors(function() commands.openRecent.run(ctx) end) end }
  plugin:newCommand{ id = constants.commandIds.JOB_BROWSER, title = "Job Browser", group = "file_scripts", onclick = function() runWithErrors(function() commands.jobBrowser.run(ctx) end) end }
  plugin:newCommand{ id = constants.commandIds.RELOAD_JOB, title = "Reload Current Job", group = "file_scripts", onclick = function() runWithErrors(function() commands.reloadJob.run(ctx) end) end }
  plugin:newCommand{ id = constants.commandIds.VALIDATE, title = "Validate Texture", group = "file_scripts", onclick = function() runWithErrors(function() commands.validateTexture.run(ctx) end) end }
  plugin:newCommand{ id = constants.commandIds.EXPORT, title = "Export to Blender Target", group = "file_scripts", onclick = function() runWithErrors(function() commands.exportToBlender.run(ctx) end) end }
  plugin:newCommand{ id = constants.commandIds.OPEN_EXPORT_FOLDER, title = "Open Export Folder", group = "file_scripts", onclick = function() runWithErrors(function() commands.openExportFolder.run(ctx) end) end }
  plugin:newCommand{ id = constants.commandIds.PREFERENCES, title = "Preferences", group = "file_scripts", onclick = function() runWithErrors(function() commands.preferences.run(ctx) end) end }
  plugin:newCommand{ id = constants.commandIds.STATUS, title = "Show Blender Link Status", group = "file_scripts", onclick = function() statusPanel.show(state) end }
end

function bootstrap.exit(plugin)
  -- Commands are cleaned up by Aseprite automatically when extension unloads.
end

return bootstrap
