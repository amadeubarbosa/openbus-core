--
-- Configuração dos tempos do mecanismo de tolerância a falhas
--
return {
  reply        = {  MAX_TIMES = 30,
                    sleep = 0.1,
                 },
  non_existent = {  MAX_TIMES = 30,
                    sleep = 0.1,
                 },
  -- TEMPO MÁXIMO DE BUSCA POR ALGUMA RÉPLICA = 3 MINUTOS = 180 segundos
  -- 22 * [ 5 s (tempo de tentativa entre cada réplica) 
  --      + 3 s (tempo máximo do non_existent) ]  = 176 =~ 3 minutos (tempo máximo)
  fetch        = {  MAX_TIMES = 22,
                    sleep = 5,
                 },
   -- TEMPO MÁXIMO QUE O MONITOR FICOU TENTANDO LEVANTAR UMA RÉPLICA
  -- 750 * [ 5 s (sleep) 
  --       + 3 s (tempo máximo do non_existent) ]  = 6000 = 10 minutos (tempo máximo)
   monitor     = {   MAX_TIMES = 750,
                     sleep = 5,
                 },
}
