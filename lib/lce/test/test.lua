require "lce"

if #arg ~= 3 then
  print("Use: "..arg[0].." <arquivo_der_x509> <arquivo_pem_chave_privada> <texto>")
  os.exit(1)
end

local x509file = arg[1]
local privatekeyfile = arg[2]
local plainText = arg[3]

local x509 = assert(lce.x509.readfromderfile(x509file))
local publicKey = x509:getpublickey()
x509:release()

local cryptedText = lce.cipher.encrypt(publicKey, plainText)
publicKey:release()

local privateKey = assert(lce.key.readprivatefrompemfile(privatekeyfile))
local decryptedText = lce.cipher.decrypt(privateKey, cryptedText)
privateKey:release()

print(decryptedText)
