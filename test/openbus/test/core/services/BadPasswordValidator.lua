return function (configs)
  return 
  function (entity, password) -- validate function
    if entity == "error" and password == "Oops!" then
      error("Oops!")
    end
    return false, "BadEntitiesShouldNotPass!"
  end,
  function () -- finalize function
    error("Oops!")
  end
end
