local messages = {}

function messages.failure(what, impact, action)
  return string.format("%s\n\nNot applied/saved: %s\n\nNext step: %s", what, impact, action)
end

return messages
