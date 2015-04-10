#!/usr/bin/env busadmin

local Arguments = require "loop.compiler.Arguments"

local args = Arguments{
  certdir = "",
  legacy = false,
  revert = false,
  errors = "ask",
  verbose = 3,
  help = false,
}
args._alias = {
  c = "certdir",
  e = "errors",
  l = "legacy",
  r = "revert",
  v = "verbose",
  h = "help",
}


-- parse command line parameters
local argidx, errmsg = args(...)
if argidx == nil or 1+argidx > select("#", ...) then
  args.help = true
end

if args.help then
  io.stderr:write([[
Usage:  [options] <source> <destiny>
Options:

  -c, -certdir <path>        diretório para armazenar certificados
  -e, -errors [fix|ignore]   fix=corrige erros, ignore=ignora erros
  -l, -legacy                exporta no formato de descritor legado
  -r, -revert                desfaz no destino as definições carregadas
  -v, -verbose <log level>   0=nada, 1=erros, 2=tudo (default=2)
  -h, -help                  exibe esta mensagem e encerra a execução

]])
  return 1
end

if args.certdir == "" then
  args.certdir = nil
end

local source, destiny = select(argidx, ...)

local function logto(spec)
  if string.match(spec, "^!") then
    assert(load(spec:sub(2), nil, "t"))()
    return true
  end
end

local defs = newdesc()

if args.errors == "fix" then
  defs.quiet = true
elseif args.errors == "ignore" then
  defs.quiet = false
end

defs.log:level(args.verbose)

if logto(source) then
  defs:download()
else
  defs:import(source, args.certdir)
end

if logto(destiny) then
  if args.revert then
    defs:revert()
  else
    defs:upload()
  end
elseif not args.revert then
  defs:export(destiny, args.certdir or "certificates", args.legacy and "legacy" or nil)
else
  stderr:write("unable to revert definition into a file.\n")
end
