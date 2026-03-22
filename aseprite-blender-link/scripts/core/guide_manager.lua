local guideManager = {}

local function addGuideLayer(sprite, imagePath, layerName)
  if not imagePath or imagePath == "" or not app.fs.isFile(imagePath) then
    return false, "Guide missing: " .. tostring(imagePath)
  end

  local temp = app.open(imagePath)
  if not temp then return false, "Could not open guide image" end
  local cel = temp.cels[1]
  if not cel then
    temp:close()
    return false, "Guide image has no cel"
  end

  app.transaction(function()
    local layer = sprite:newLayer()
    layer.name = layerName
    layer.isVisible = true
    layer.isEditable = true
    sprite:newCel(layer, 1, cel.image, Point(0, 0))
  end)

  temp:close()
  return true
end

function guideManager.loadGuides(sprite, job)
  local loaded = {}
  local warnings = {}

  local okUv, errUv = addGuideLayer(sprite, job.uv_guide_path, "GUIDE_UV")
  if okUv then table.insert(loaded, job.uv_guide_path) elseif job.uv_guide_path and job.uv_guide_path ~= "" then table.insert(warnings, errUv) end

  local okId, errId = addGuideLayer(sprite, job.id_map_path, "GUIDE_ID")
  if okId then table.insert(loaded, job.id_map_path) elseif job.id_map_path and job.id_map_path ~= "" then table.insert(warnings, errId) end

  for i, maskPath in ipairs(job.mask_paths or {}) do
    local name = string.format("GUIDE_MASK_%02d", i)
    local okMask, errMask = addGuideLayer(sprite, maskPath, name)
    if okMask then table.insert(loaded, maskPath) else table.insert(warnings, errMask) end
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
