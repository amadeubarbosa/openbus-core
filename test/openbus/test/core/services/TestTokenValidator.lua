return function (configs)
  return function (login, entity, token, imported)
    local tokenentity, tokenlogin, originators = string.match(token, "^([^@]+)@([^:]+):(.-)$")
    if tokenentity == entity and tokenlogin == login then
      for entity in string.gmatch(originators, "([^, ]+)") do
        imported:push(entity)
      end
      return true
    end
    return nil, "malformed test token"
  end
end