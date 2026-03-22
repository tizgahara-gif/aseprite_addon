local messages = _G.BLENDER_LINK_LOAD("ui/messages.lua")

local dialogs = {}

function dialogs.showError(what, impact, action)
  app.alert{ title = "Blender Link Error", text = messages.failure(what, impact, action) }
end

function dialogs.showWarning(text)
  app.alert{ title = "Blender Link Warning", text = text }
end

function dialogs.showInfo(text)
  app.alert{ title = "Blender Link", text = text }
end

return dialogs
