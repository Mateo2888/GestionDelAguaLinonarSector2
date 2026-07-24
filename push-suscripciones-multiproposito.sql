-- =========================================================
-- MIGRACIÓN: permitir que un mismo celular/navegador tenga varias
-- suscripciones a la vez (turno + admin + un reporte específico, etc.)
-- Copia y pega TODO este archivo en: Supabase > SQL Editor > New query > Run
-- =========================================================
-- Hasta ahora, "push_suscripciones" tenía "endpoint" (identifica al
-- celular/navegador) como único. Eso significa que si el mismo
-- dispositivo se suscribía a un segundo propósito (por ejemplo, el
-- administrador activa "avisarme de reportes nuevos" en el mismo
-- celular donde ya tenía activado su propio turno), la segunda
-- suscripción SOBRESCRIBÍA la primera y la dejaba sin efecto.
--
-- Ahora lo único que debe ser único es la combinación
-- (endpoint, propietario_codigo) — así el mismo dispositivo puede
-- estar suscrito a varias cosas a la vez, cada una en su propia fila.
-- =========================================================

alter table push_suscripciones drop constraint if exists push_suscripciones_endpoint_key;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'push_suscripciones_endpoint_codigo_key'
  ) then
    alter table push_suscripciones
      add constraint push_suscripciones_endpoint_codigo_key unique (endpoint, propietario_codigo);
  end if;
end $$;
