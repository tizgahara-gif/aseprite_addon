local validator = _G.BLENDER_LINK_LOAD("core/validator.lua")

local command = {}

function command.run(ctx)
  local result = validator.validate(ctx.state.job, ctx.state.sprite or app.activeSprite, ctx.state)
  ctx.state.validation_state = result.state
  ctx.state.last_validation = result

  local lines = {"Validation: " .. result.state}
  for _, item in ipairs(result.findings) do
    table.insert(lines, string.format("[%s] %s", item.level, item.message))
  end
  if #result.findings == 0 then table.insert(lines, "No issues detected.") end

  app.alert(table.concat(lines, "\n"))
  ctx.logger.info("Validation result: " .. result.state)
end

return command
