local parser = _G.BLENDER_LINK_LOAD("core/job_parser.lua")

local registry = {}

function registry.scanFolder(folder)
  local items = app.fs.listFiles(folder)
  local jobs = {}
  for _, filePath in ipairs(items) do
    if app.fs.fileExtension(filePath):lower() == "json" then
      local job, errors = parser.parse(filePath)
      if job then
        table.insert(jobs, { path = filePath, job = job, errors = {} })
      else
        table.insert(jobs, { path = filePath, job = nil, errors = errors or {"Unknown parse error"} })
      end
    end
  end
  table.sort(jobs, function(a, b)
    local aDate = a.job and a.job.updated_at or ""
    local bDate = b.job and b.job.updated_at or ""
    return aDate > bDate
  end)
  return jobs
end

return registry
