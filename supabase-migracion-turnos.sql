-- =========================================================
-- MIGRACIÓN: Sistema de turnos automáticos por código de propietario
-- Copia y pega TODO este archivo en: Supabase > SQL Editor > New query > Run
-- Es seguro ejecutarlo aunque ya hayas creado la tabla "propietarios" antes:
-- crea la tabla solo si no existe y reemplaza las políticas de seguridad
-- (por si el script que ya corriste no las incluía).
-- =========================================================

create table if not exists propietarios (
  id bigint generated always as identity primary key,
  codigo text not null unique,
  nombre text not null,
  sector text not null,
  posicion integer not null default 0,
  activo boolean not null default true,
  turno_fecha_manual date,
  turno_inicio_manual time,
  turno_fin_manual time,
  created_at timestamp with time zone default now()
);

alter table propietarios enable row level security;

-- Lectura pública: necesaria para que cualquier visitante consulte su turno
-- escribiendo su código en la sección "Mi turno" del sitio (sin iniciar sesión).
-- Nota: esto hace que la tabla completa (código, nombre, sector, posición) sea
-- legible por cualquiera con la clave pública, igual que ya ocurre con la tabla
-- "programacion" (persona + sector + horario). No incluye teléfono ni dirección.
drop policy if exists "lectura publica propietarios" on propietarios;
create policy "lectura publica propietarios" on propietarios for select using (true);

-- Escritura (insert/update/delete) SOLO para el administrador autenticado
drop policy if exists "admin escribe propietarios" on propietarios;
create policy "admin escribe propietarios" on propietarios for all using (auth.role() = 'authenticated');
