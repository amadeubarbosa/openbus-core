
#include <tec/openbus/util/sequence_iterator.hpp>
#include <tec/core/access_control_servant.hpp>
#include <tec/ssl/bio.hpp>
#include <tec/ssl/rsa.hpp>
#include <tec/ssl/sha256.hpp>

#include <fstream>
#include <cstdlib>
#include <cassert>
#include <stdexcept>
#include <cstdio>
#include <iterator>
#include <algorithm>

#include <openssl/pem.h>

namespace tec { namespace core {

access_control_servant::access_control_servant()
  : db("database.sqlite")
{
  FILE* f = std::fopen("private.pem", "r");
  if(f)
  {
    rsa = ssl::rsa(PEM_read_RSAPrivateKey(f, 0, 0, 0));
  }
  else
    throw std::runtime_error("");
  
  tec::ssl::memory_bio bio;

  if(!PEM_write_bio_RSAPublicKey(bio.raw(), rsa.raw()))
  {
    std::cout << "PEM write error" << std::endl;
  }

  bio.pop();

  using tecgraf::openbus::core::v1_06::OctetSeq;
  public_token.token_octet.length(bio.length());
  tec::openbus::util::sequence_iterator<OctetSeq>
    first(public_token.token_octet)
    , last(public_token.token_octet, bio.length());
  std::copy(bio.begin(), bio.end(), first);
}

tecgraf::openbus::core::v1_06::access_control_service::Token* access_control_servant::getToken()
{
  using tecgraf::openbus::core::v1_06::access_control_service::Token;
  Token* token = new tecgraf::openbus::core::v1_06::access_control_service
    ::Token(public_token);
  return token;
}

void access_control_servant::loginByPassword(OctetSeq const& encrypted_username, OctetSeq const& encrypted_password
                                             , OctetSeq const& client_public_key, OctetSeq_out public_key_signature)
{
  std::cout << "loginByPassword" << std::endl;
  std::string username;
  rsa.private_decrypt(encrypted_username.get_buffer(), encrypted_username.get_buffer()
                      + encrypted_username.length()
                      , std::back_inserter(username));
  std::string password;
  rsa.private_decrypt(encrypted_password.get_buffer(), encrypted_password.get_buffer()
                      + encrypted_password.length()
                      , std::back_inserter(password));

  if(username == "Tester")
    std::cout << "Username is right" << std::endl;
  else
    std::cout << "Wrong username " << username << std::endl;

  if(password == "Tester")
    std::cout << "Password is right" << std::endl;
  else
    std::cout << "Wrong password " << password << std::endl;
  
  std::vector<unsigned char> sha256;
  ssl::sha256(client_public_key.get_buffer(), client_public_key.get_buffer()
              + client_public_key.length(), std::back_inserter(sha256));
  std::vector<unsigned char> signature;
  rsa.sign(sha256.begin(), sha256.end(), std::back_inserter(signature));

  public_key_signature = new OctetSeq;
  public_key_signature->length(signature.size());
  tec::openbus::util::sequence_iterator<OctetSeq>
    first(*public_key_signature);
  std::copy(signature.begin(), signature.end(), first);
}

} }
