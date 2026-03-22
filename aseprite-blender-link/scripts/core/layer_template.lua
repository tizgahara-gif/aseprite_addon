local constants = _G.BLENDER_LINK_LOAD("core/constants.lua")

local layerTemplate = {}

local function hasLayer(sprite, name)
  for _, layer in ipairs(sprite.layers) do
    if layer.name == name then return true end
  end
  return false
end

function layerTemplate.apply(sprite, templateName)
  local template = constants.layerTemplates[templateName]
  if not template then return false, "Unknown layer template" end

  app.transaction(function()
    for _, name in ipairs(template) do
      if not hasLayer(sprite, name) then
        local layer = sprite:newLayer()
        layer.name = name
      end
    end
  end)

  return true
end

return layerTemplate
