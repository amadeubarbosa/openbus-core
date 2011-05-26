#ifndef TEC_CORE_ACCESS_CONTROL_SERVANT_HPP
#define TEC_CORE_ACCESS_CONTROL_SERVANT_HPP

#include "access_control_service.h"
#include <tec/ssl/rsa.hpp>
#include <tec/sql/database.hpp>

namespace tec { namespace core {

using tecgraf::openbus::core::v1_06::OctetSeq;
using tecgraf::openbus::core::v1_06::OctetSeq_out;

struct access_control_servant : POA_tecgraf::openbus::core::v1_06::access_control_service::IAccessControlService
{
  access_control_servant();
  tecgraf::openbus::core::v1_06::access_control_service::Token* getToken();
  void loginByPassword (OctetSeq const& encrypted_username, OctetSeq const& encrypted_password
                        , OctetSeq const& client_public_key, OctetSeq_out public_key_signature);

  tecgraf::openbus::core::v1_06::access_control_service::Token public_token;

  ssl::rsa rsa;
  sql::database db;
};

} }

#endif
