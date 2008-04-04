local fg = require "RemoteFileChannel.tests.FileGenerator"
print('Gerando arquivo de 5Gb...')
fg("/tmp/5Gb", 5000000000, '*')

