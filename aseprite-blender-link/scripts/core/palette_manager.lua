local paletteManager = {}

function paletteManager.load(sprite, palettePath)
  if not palettePath or palettePath == "" then
    return false, "No palette specified"
  end
  if not app.fs.isFile(palettePath) then
    return false, "Palette file not found"
  end
  local ok, err = pcall(function() app.command.LoadPalette{ filename = palettePath } end)
  return ok, err
end

return paletteManager
