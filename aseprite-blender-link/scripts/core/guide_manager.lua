local guideManager = {}

local function findLayer(sprite, name)
  for _, layer in ipairs(sprite.layers) do
    if layer.name == name then return layer end
  end
  return nil
end

local function removeLayerIfExists(sprite, name)
  local existing = findLayer(sprite, name)
  if existing then
    app.transaction(function() sprite:deleteLayer(existing) end)
  end
end

local function createReferenceLayer(sprite, name)
  app.command.NewLayer{ reference = true }
  local layer = app.activeLayer
  if not layer then return nil, "Could not create layer" end
  layer.name = name
  layer.isVisible = true
  return layer
end

local function upsertGuideReferenceLayer(sprite, entry)
  if not entry.path or entry.path == "" then
    return false, "Guide path is empty for " .. entry.name
  end
  if not app.fs.isFile(entry.path) then
    return false, "Guide file missing: " .. entry.path
  end

  local okImage, imageOrErr = pcall(function()
    return Image{ fromFile = entry.path }
  end)
  if not okImage or not imageOrErr then
    return false, "Failed to read guide image: " .. entry.path
  end

  removeLayerIfExists(sprite, entry.name)

  local okLayer, layerOrErr = pcall(function()
    return createReferenceLayer(sprite, entry.name)
  end)
  if not okLayer or not layerOrErr then
    return false, "Failed to create reference layer: " .. tostring(layerOrErr)
  end
  local layer = layerOrErr

  local okCel, celErr = pcall(function()
    local frame = sprite.frames[1] or 1
    sprite:newCel(layer, frame, imageOrErr, Point(0, 0))
  end)
  if not okCel then
    return false, "Failed to place guide cel: " .. tostring(celErr)
  end

  return true
end

function guideManager.loadGuides(sprite, job)
  local loaded = {}
  local warnings = {}

  local entries = job.guide_entries or {}
  for _, entry in ipairs(entries) do
    local ok, err = upsertGuideReferenceLayer(sprite, entry)
    if ok then
      table.insert(loaded, entry.path)
    else
      table.insert(warnings, err)
    end
  end

  return loaded, warnings
end

function guideManager.removeGuideLayers(sprite)
  app.transaction(function()
    for i = #sprite.layers, 1, -1 do
      local layer = sprite.layers[i]
      if layer.name:sub(1, 6) == "GUIDE_" then
        sprite:deleteLayer(layer)
      end
    end
  end)
end

return guideManager
