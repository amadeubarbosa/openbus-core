local Suite = require "loop.test.Suite"

return Suite{
  CertificateRegistry = require "openbus.test.core.services.CertificateRegistry",
  EntityRegistry = require "openbus.test.core.services.EntityRegistry",
  LoginRegistry = require "openbus.test.core.services.LoginRegistry",
  OfferRegistry = require "openbus.test.core.services.OfferRegistry",
  LegacySupport = require "openbus.test.core.services.LegacySupport",
}
