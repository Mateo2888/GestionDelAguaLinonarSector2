-- =========================================================
-- MIGRACIÓN: Estado de pago y comprobante por propietario
-- Copia y pega TODO este archivo en: Supabase > SQL Editor > New query > Run
-- =========================================================
-- Agrega a la tabla "propietarios" (ya existente) las columnas que
-- necesitan las dos funciones nuevas:
--   1) Estado de pago ligado al propietario (Pendiente / Al día).
--   2) Comprobante de pago en PDF, enviado al correo del propietario.
--
-- Es seguro ejecutarlo aunque ya hayas corrido esto antes: "add column
-- if not exists" no falla ni duplica nada si la columna ya existe.
-- =========================================================

alter table propietarios add column if not exists estado_pago text not null default 'Pendiente' check (estado_pago in ('Pendiente','Al día'));
alter table propietarios add column if not exists ultimo_pago date;
alter table propietarios add column if not exists correo text;

-- No hace falta ninguna política de RLS nueva: "propietarios" ya tiene
-- lectura pública (para la consulta de turno) y escritura solo-admin
-- (ver supabase-migracion-turnos.sql / supabase-setup.sql) — estas
-- columnas nuevas quedan cubiertas por esas mismas políticas.
