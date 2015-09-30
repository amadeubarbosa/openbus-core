return function (configs)
  return function (entity, password)
    if entity == "error" and password == "Oops!" then
      error("Oops!")
    end
  end
end
