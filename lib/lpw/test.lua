require "lpw"

local prompt = "password: "
local pass, err = lpw.getpass(prompt)
if pass then
  print("Passord typed: " .. pass)
else
  print("Error: " .. err)
end
