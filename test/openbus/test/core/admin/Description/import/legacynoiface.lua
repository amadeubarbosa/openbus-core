Category {
  id = "SomeCategory",
  name = "Some category",
}
Entity {
  id = "SomeEntity",
  name = "Some entity",
  category = "SomeCategory",
}
Grant {
  id = "SomeEntity",
  interfaces = {
    "IDL:somemodule/for/MissingInterface:1.0",
  },
}
