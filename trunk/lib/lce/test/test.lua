require "lce"

if #arg ~= 3 then
  print("Use: "..arg[0].." <arquivo_der_x509> <arquivo_pem_chave_privada> <texto>")
  os.exit(1)
end

local x509File = arg[1]
local privateKeyFile = arg[2]
local plainText = arg[3]

function getPublicKeyFromX509DERFile()
  local x509 = assert(lce.x509.readfromderfile(x509File))
  return x509:getpublickey()
end

function getPublicKeyFromX509StringDERFile()
  local certificateFile = assert(io.open(x509File))
  local x509String = certificateFile:read("*a")
  certificateFile:close()

  local x509 = assert(lce.x509.readfromderstring(x509String))
  return x509:getpublickey()
end

function encrypt(publicKey)
  return assert(lce.cipher.encrypt(publicKey, plainText))
end

function readPrivateKeyFromPEMFile()
  return assert(lce.key.readprivatefrompemfile(privateKeyFile))
end

function readPrivateKeyFromStringPEMFile()
  local keyFile = assert(io.open(privateKeyFile))
  local privateKeyString = keyFile:read("*a")
  keyFile:close()

  return assert(lce.key.readprivatefrompemstring(privateKeyString))
end

function decrypt(privateKey, cryptedText)
  return assert(lce.cipher.decrypt(privateKey, cryptedText))
end

local publicKey
local cryptedText
local privateKey

publicKey = getPublicKeyFromX509DERFile()
cryptedText = encrypt(publicKey)
privateKey = readPrivateKeyFromPEMFile()
print(decrypt(privateKey, cryptedText))
privateKey = readPrivateKeyFromStringPEMFile()
print(decrypt(privateKey, cryptedText))

publicKey = getPublicKeyFromX509StringDERFile()
cryptedText = encrypt(publicKey)
privateKey = readPrivateKeyFromPEMFile()
print(decrypt(privateKey, cryptedText))
privateKey = readPrivateKeyFromStringPEMFile()
print(decrypt(privateKey, cryptedText))
