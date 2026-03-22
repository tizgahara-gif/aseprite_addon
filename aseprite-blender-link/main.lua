local scriptFile = debug.getinfo(1, "S").source:sub(2)
local rootDir = app.fs.filePath(scriptFile)

_G.BLENDER_LINK_ROOT = rootDir
_G.BLENDER_LINK_LOAD = function(relPath)
  return dofile(app.fs.joinPath(rootDir, "scripts", relPath))
end

local bootstrap = _G.BLENDER_LINK_LOAD("bootstrap.lua")

function init(plugin)
  bootstrap.init(plugin, rootDir)
end

function exit(plugin)
  bootstrap.exit(plugin)
end
