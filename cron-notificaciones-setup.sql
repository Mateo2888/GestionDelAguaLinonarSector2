-- =========================================================
-- CRON: disparar la Edge Function "notificar-turnos" cada minuto
-- Copia y pega TODO este archivo en: Supabase > SQL Editor > New query > Run
-- =========================================================
-- IMPORTANTE: antes de correr esto, la función "notificar-turnos" debe
-- existir y estar desplegada (ver prompt-notificaciones-push.md).
--
-- Si "pg_cron" o "pg_net" no están habilitadas en tu proyecto, este
-- script las habilita solas (create extension if not exists) — no
-- rompe nada si ya estaban habilitadas.
-- =========================================================

create extension if not exists pg_cron with schema extensions;
create extension if not exists pg_net with schema extensions;

-- Se usa la URL real del proyecto y la anon key directamente (los
-- valores "current_setting('app.supabase_url')" que a veces se ven en
-- ejemplos de internet NO existen por defecto en un proyecto nuevo de
-- Supabase, y esta llamada fallaría con "unrecognized configuration
-- parameter" si se usaran tal cual).
select cron.schedule(
  'revisar-turnos-cada-minuto',
  '* * * * *',
  $$
  select net.http_post(
    url := 'https://owhtiqoshemfchrsvsib.supabase.co/functions/v1/notificar-turnos',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer sb_publishable_rjcqOTf9_lAYpeoqpqfSDA_vaZVqsFj'
    ),
    body := '{}'::jsonb
  );
  $$
);

-- Para revisar que el cron quedó programado:
--   select * from cron.job;
-- Para borrarlo si algún día ya no lo quieres:
--   select cron.unschedule('revisar-turnos-cada-minuto');
