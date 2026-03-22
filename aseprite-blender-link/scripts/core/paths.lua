local paths = {}

function paths.isAbsolute(path)
  if not path or path == "" then return false end
  return path:match("^%a:[/\\]") ~= nil or path:sub(1,1) == "/"
end

function paths.normalize(path)
  if not path then return "" end
  return app.fs.normalizePath(path)
end

function paths.resolve(baseFilePath, value)
  if not value or value == "" then return "" end
  if paths.isAbsolute(value) then return paths.normalize(value) end
  local baseDir = app.fs.filePath(baseFilePath)
  return paths.normalize(app.fs.joinPath(baseDir, value))
end

function paths.parent(path)
  return app.fs.filePath(path or "")
end

function paths.exists(path)
  return path and path ~= "" and app.fs.isFile(path)
end

function paths.canWrite(filePath)
  local parent = app.fs.filePath(filePath)
  return parent ~= "" and app.fs.isDirectory(parent)
end

return paths
