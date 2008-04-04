local interface = [[
  interface foo {
    void run() ;
  } ;
]]

local impl = {
  run = function()
    print("OiL is answering a calling of foo:run() while a read operation is waiting data on the channel...")
  end
}

oil.loadidl(interface)
foo = oil.newservant(impl, "IDL:foo:1.0")
print("Servant:", foo)
ior = oil.tostring(foo)
print("IOR:", ior)
oil.writeto("ref.ior", ior  )
