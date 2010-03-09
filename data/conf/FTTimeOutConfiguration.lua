--
-- Configura��o dos tempos do mecanismo de toler�ncia a falhas
--
return {
  reply        = {  MAX_TIMES = 30,
                    sleep = 0.1,
                 },
  non_existent = {  MAX_TIMES = 30,
                    sleep = 0.1,
                 },
  -- TEMPO M�XIMO DE BUSCA POR ALGUMA R�PLICA = 3 MINUTOS = 180 segundos
  -- 22 * [ 5 s (tempo de tentativa entre cada r�plica) 
  --      + 3 s (tempo m�ximo do non_existent) ]  = 176 =~ 3 minutos (tempo m�ximo)
  fetch        = {  MAX_TIMES = 22,
                    sleep = 5,
                 },
   -- TEMPO M�XIMO QUE O MONITOR FICOU TENTANDO LEVANTAR UMA R�PLICA
  -- 750 * [ 5 s (sleep) 
  --       + 3 s (tempo m�ximo do non_existent) ]  = 6000 = 10 minutos (tempo m�ximo)
   monitor     = {   MAX_TIMES = 750,
                     sleep = 5,
                 },
}
