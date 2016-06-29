## Dependências

[lua](https://git.tecgraf.puc-rio.br/openbus-3rd-party/lua/tree/master)
[loop](https://git.tecgraf.puc-rio.br/engdist/loop/tree/master)
[oil](https://git.tecgraf.puc-rio.br/engdist/oil/tree/master)
[lce](https://git.tecgraf.puc-rio.br/engdist/lce/tree/master)
[luuid](https://git.tecgraf.puc-rio.br/openbus-3rd-party/luuid/tree/1.0)
[luascs](https://git.tecgraf.puc-rio.br/scs/scs-core-lua/tree/SCS_CORE_LUA_v1_02_03_2012_05_10)
[scs-idl](https://git.tecgraf.puc-rio.br/scs/scs-core-idl/tree/SCS_CORE_IDL_v1_02_2010_09_21)
[lualdap](https://git.tecgraf.puc-rio.br/openbus-3rd-party/lualdap/tree/1.1.0)
[luafilesystem](https://git.tecgraf.puc-rio.br/openbus-3rd-party/luafilesystem/tree/1.4.2)
[luasocket](https://git.tecgraf.puc-rio.br/openbus-3rd-party/luasocket/tree/2.0.2)
[luastruct](https://git.tecgraf.puc-rio.br/openbus-3rd-party/luastruct/tree/1.0)
[luavararg](https://git.tecgraf.puc-rio.br/openbus-3rd-party/luavararg/tree/1.1)
[openbuslua](https://git.tecgraf.puc-rio.br/openbus/openbus-sdk-lua/luaopenbus/02_00_01)
[openbus-idl](https://git.tecgraf.puc-rio.br/openbus/openbus-idl/tree/02_00)
[openbus-idl-lib](https://git.tecgraf.puc-rio.br/openbus/openbus-sdk-idl/tree/02_00)
[openbus-legacy-idl](https://git.tecgraf.puc-rio.br/openbus/openbus-idl/tree/OB_IDL_v1_05_2010_05_13)
[openssl-1.1.0o](http://webserver2.tecgraf.puc-rio.br/ftp_pub/openbus/repository/openssl-1.0.0o.tar.gz)
[openssl.jam](https://git.tecgraf.puc-rio.br/boost-build/openssl.jam/tree/master)
[openldap-2.4.39](http://webserver2.tecgraf.puc-rio.br/ftp_pub/openbus/repository/openldap-2.4.39.tgz)
[openldap.jam](https://git.tecgraf.puc-rio.br/boost-build/openldap.jam/tree/master)
[boost-build](http://webserver2.tecgraf.puc-rio.br/ftp_pub/openbus/repository/boost-build-2014-10_tecgraf_28112014snapshot.tgz)

## Build
0. Escolher um diretório para o processo de build, que será referenciado neste 
através da varíavel de ambiente `BUILD`.
1. Obter as dependências e disponibilizar cada uma em um 
diretório com o nome da dependência como listado acima. Os diretórios 
devem ser subdiretórios do diretório `BUILD`. Por exemplo: `$BUILD/lua`,
`$BUILD/loop`, `$BUILD/oil` e assim por diante. 
2. Disparar o Boost Build em `$BUILD/openbus-core/bbuild` informando os local 
da instalação da OpenSSL e OpenLDAP (somente Unix):
### Unix
```bash
cd $BUILD/openbus-core/bbuild
$INSTALL/boost-build/b2 warnings=off \
  -sOPENSSL_INSTALL=$OPENLDAP_INSTALL \ 
  -sOPENSSL_INSTALL=$OPENSSL_INSTALL
```
### Windows
```
cd %BUILD%\openbus-core\bbuild
%INSTALL%\boost-build\b2 warnings=off ^
  -sOPENSSL_INSTALL=%OPENSSL_INSTALL%
```
A variável `OPENSSL_INSTALL` indica o local da instalação da OpenSSL que deve 
conter os diretórios `include` e `lib`. Esses diretórios podem ser informados 
de forma separada através das variáveis `OPENSSL_INC` e `OPENSSL_LIB`.

Os locais de instalação das bibliotecas OpenSSL e OpenLDAP podem ser informados 
através das variáveis `OPENSSL_INSTALL` e `OPENLDAP_INSTALL`. A estrutura da 
instalação deve conter os diretórios `include` e `lib`. Como alternativa, esses 
diretórios podem ser informados de forma separada através das variáveis 
`OPENSSL_INC` e `OPENSSL_LIB`.

As outras dependências são buscadas automaticamente no diretório pai do pacote 
`openbus-core`. Para cada dependência descrita na tabela acima, a Boost Build 
procura um diretório com o nome da dependência que contenha a extração do pacote 
da mesma. É possível informar caminhos customizados para cada uma das 
dependências através das seguintes variáveis de ambiente:
LUA
LOOP
OIL
LCE
LUUID
LUALDAP
LUAFILESYSTEM
LUASOCKET
LUASTRUCT
LUAVARARG
SCSLUA
SCS_IDL
OPENBUSLUA
OPENBUS_IDL
OPENBUS_LEGACY_IDL
OPENBUS_LIB_IDL
OPENSSL_JAM
OPENLDAP_JAM

Os produtos do build são disponibilizados em 
`%BUILD%\openbus-core\bbuild\install`.