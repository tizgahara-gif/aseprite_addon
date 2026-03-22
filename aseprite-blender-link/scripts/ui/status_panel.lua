local statusManager = _G.BLENDER_LINK_LOAD("core/status_manager.lua")

local panel = {}

function panel.show(state)
  app.alert{ title = "Blender Link Status", text = statusManager.summary(state) }
end

return panel
