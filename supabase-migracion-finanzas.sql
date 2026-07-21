-- =========================================================
-- MIGRACIÓN: Contabilidad y finanzas completo
-- Gestión del Agua Limonar Sector II
--
-- Este script es para un proyecto Supabase QUE YA TIENE las tablas
-- creadas con supabase-setup.sql (no vuelvas a correr ese archivo).
-- Copia y pega TODO este script en: Supabase > SQL Editor > New query > Run
-- Ejecútalo UNA SOLA VEZ.
-- =========================================================

-- 1) Agregar categoría y comprobante (foto/recibo) a los movimientos existentes de finanzas
alter table finanzas add column if not exists categoria text;
alter table finanzas add column if not exists comprobante text;

-- 2) Nueva tabla: control de pagos de mensualidad por vivienda
create table if not exists mensualidades (
  id bigint generated always as identity primary key,
  vivienda text not null,
  sector text not null,
  mes text not null,
  estado text not null default 'Pendiente' check (estado in ('Pagado','Pendiente','Atrasado')),
  valor numeric,
  created_at timestamp with time zone default now()
);

alter table mensualidades enable row level security;

-- Mensualidades es información financiera individual de cada vecino:
-- solo el administrador autenticado puede leerla, agregarla, editarla o borrarla.
-- Ningún visitante público puede verla (no se crea ninguna política de lectura pública).
create policy "admin gestiona mensualidades" on mensualidades for all using (auth.role() = 'authenticated');
