local command = {}

function command.run(ctx)
  if not ctx.state.job then
    app.alert("No active job")
    return
  end
  local dir = app.fs.filePath(ctx.state.job.export_image_path)
  if app.fs.isDirectory(dir) then
    app.command.OpenFile{ filename = dir }
  else
    app.alert("Could not open export folder.\nPath: " .. tostring(dir))
  end
end

return command
