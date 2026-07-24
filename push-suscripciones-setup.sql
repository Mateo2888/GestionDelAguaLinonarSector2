-- =========================================================
-- MIGRACIÓN: Tabla de suscripciones a notificaciones push
-- Copia y pega TODO este archivo en: Supabase > SQL Editor > New query > Run
-- =========================================================
-- Guarda la "suscripción" que el navegador de cada propietario genera
-- al activar notificaciones (endpoint + llaves de cifrado del Web
-- Push estándar). No contiene datos personales más allá del código
-- de propietario que la activó.
-- =========================================================

create table if not exists push_suscripciones (
  id bigint generated always as identity primary key,
  propietario_codigo text not null,
  endpoint text not null unique,
  p256dh text not null,
  auth text not null,
  created_at timestamp with time zone default now()
);

alter table push_suscripciones enable row level security;

-- Cualquiera puede suscribirse (insertar) y volver a activar la misma
-- suscripción (actualizar) — no hay login para los propietarios, así
-- que esto tiene que ser público. NOTA: el código de propietario que
-- viaja aquí ya es público de por sí (ver tabla "propietarios").
drop policy if exists "insertar suscripcion" on push_suscripciones;
create policy "insertar suscripcion" on push_suscripciones for insert with check (true);

drop policy if exists "actualizar suscripcion propia" on push_suscripciones;
create policy "actualizar suscripcion propia" on push_suscripciones for update using (true);

-- Solo el administrador puede ver/borrar la lista completa de
-- suscripciones (el cron también usa la service_role key, que
-- siempre se salta RLS, así que no necesita política propia).
drop policy if exists "admin gestiona suscripciones" on push_suscripciones;
create policy "admin gestiona suscripciones" on push_suscripciones for select using (auth.role() = 'authenticated');
create policy "admin borra suscripciones" on push_suscripciones for delete using (auth.role() = 'authenticated');
