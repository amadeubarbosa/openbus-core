return function (configs)
  return function (login, entity, token)
    local tokenentity, tokenlogin, originators = string.match(token, "^([^@]+)@([^:]+):(.-)$")
    if tokenentity == entity and tokenlogin == login then
      local entities = {}
      for entity in string.gmatch(originators, "([^, ]+)") do
        entities[#entities+1] = entity
      end
      return entities
    end
    return nil, "malformed test token"
  end
end