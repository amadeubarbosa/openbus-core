-----------------------------------------------------------------------------
-- Mecanismo para debug do OpenBus baseado no m�dulo Verbose provido pelo LOOP
--
-- �ltima altera��o:
--   $Id$
-----------------------------------------------------------------------------
local Viewer = require "loop.debug.Viewer"
local Verbose = require "loop.debug.Verbose"

module ("openbus.common.Log", Verbose)

-- Coloca data e hora no log
timed = "%d/%m %H:%M:%S"

-- Usa uma inst�ncia pr�pria do Viewer para n�o interferir com o do OiL
viewer = Viewer{
           maxdepth = 2,
           indentation = "|  ",
           -- output = io.output()
         }

-- Defini��o dos tags que comp�em cada grupo
groups.basic = {"init", "warn", "error"}
groups.mechanism = {"interceptor", "lease"}
groups.core = {"scs", "member"}
groups.all = {"basic", "service", "mechanism", "core"}

-- Defini��o dos n�veis de debug (em ordem crescente)
_M:newlevel{"basic"}
_M:newlevel{"service"}
_M:newlevel{"mechanism"}
_M:newlevel{"core"}

-- Caso seja necess�rio exibir o hor�rio do registro
-- timed.basic =  "%d/%m %H:%M:%S"
-- timed.all =  "%d/%m %H:%M:%S"
