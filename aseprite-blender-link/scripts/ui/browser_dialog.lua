local browser = {}

function browser.pick(jobs)
  if #jobs == 0 then
    app.alert("No jobs found in selected folder.")
    return nil
  end

  local labels = {}
  for i, item in ipairs(jobs) do
    if item.job then
      labels[i] = string.format("%s | %s | %dx%d | rev %d | %s", item.job.asset_name, item.job.map_type, item.job.width, item.job.height, item.job.revision, item.job.updated_at)
    else
      labels[i] = string.format("[INVALID] %s", app.fs.fileName(item.path))
    end
  end

  local dlg = Dialog("Job Browser")
  dlg:combobox{ id = "job", label = "Jobs", option = labels[1], options = labels }
  dlg:button{ id = "open", text = "Open" }
  dlg:button{ id = "cancel", text = "Cancel" }
  dlg:show{ wait = true }
  local data = dlg.data
  if not data or not data.job then return nil end
  for i, label in ipairs(labels) do
    if label == data.job then return jobs[i] end
  end
  return nil
end

return browser
