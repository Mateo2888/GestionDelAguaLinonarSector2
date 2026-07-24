-- =========================================================
-- CONFIGURACIÓN DE BASE DE DATOS · Gestión del Agua Limonar Sector II
-- Copia y pega TODO este archivo en: Supabase > SQL Editor > New query > Run
-- =========================================================

-- 1) NOTICIAS
create table noticias (
  id bigint generated always as identity primary key,
  titulo text not null,
  imagen text,
  descripcion text,
  fecha date default current_date,
  created_at timestamp with time zone default now()
);

-- 2) GALERÍA
create table galeria (
  id bigint generated always as identity primary key,
  url text not null,
  created_at timestamp with time zone default now()
);

-- 3) MANTENIMIENTOS
create table mantenimientos (
  id bigint generated always as identity primary key,
  fecha date not null,
  actividad text not null,
  responsable text,
  imagen text,
  estado text default 'Completado',
  created_at timestamp with time zone default now()
);

-- 4) TRANSPARENCIA / FINANZAS
create table finanzas (
  id bigint generated always as identity primary key,
  fecha date not null,
  concepto text not null,
  categoria text,
  tipo text not null check (tipo in ('ingreso','gasto')),
  valor numeric not null,
  comprobante text,
  created_at timestamp with time zone default now()
);

-- 5) SOLICITUDES DE AFILIACIÓN
create table afiliaciones (
  id bigint generated always as identity primary key,
  nombre text not null,
  sector text not null,
  direccion text not null,
  telefono text not null,
  estado text default 'Pendiente',
  notif_token text,
  created_at timestamp with time zone default now()
);

-- 6) MENSUALIDADES (control de pagos por vivienda, solo para el administrador)
create table mensualidades (
  id bigint generated always as identity primary key,
  vivienda text not null,
  sector text not null,
  mes text not null,
  estado text not null default 'Pendiente' check (estado in ('Pagado','Pendiente','Atrasado')),
  valor numeric,
  created_at timestamp with time zone default now()
);

-- 7) PROPIETARIOS (códigos para la consulta automática de turnos, estado de pago y comprobante)
create table propietarios (
  id bigint generated always as identity primary key,
  codigo text not null unique,
  nombre text not null,
  sector text not null,
  posicion integer not null default 0,
  activo boolean not null default true,
  turno_fecha_manual date,
  turno_inicio_manual time,
  turno_fin_manual time,
  estado_pago text not null default 'Pendiente' check (estado_pago in ('Pendiente','Al día')),
  ultimo_pago date,
  correo text,
  created_at timestamp with time zone default now()
);

-- =========================================================
-- SEGURIDAD (Row Level Security)
-- Permite que cualquier visitante LEA los datos públicos,
-- pero solo un administrador autenticado pueda escribir/editar/borrar.
-- =========================================================
alter table noticias enable row level security;
alter table galeria enable row level security;
alter table mantenimientos enable row level security;
alter table finanzas enable row level security;
alter table afiliaciones enable row level security;
alter table mensualidades enable row level security;
alter table propietarios enable row level security;

-- Lectura pública para el contenido informativo del sitio
-- (finanzas NO está aquí a propósito: es privada, solo para el administrador)
create policy "lectura publica noticias" on noticias for select using (true);
create policy "lectura publica galeria" on galeria for select using (true);
create policy "lectura publica mantenimientos" on mantenimientos for select using (true);
create policy "lectura publica propietarios" on propietarios for select using (true);

-- Escritura (insert/update/delete) SOLO para usuarios autenticados (el administrador)
create policy "admin escribe noticias" on noticias for all using (auth.role() = 'authenticated');
create policy "admin escribe galeria" on galeria for all using (auth.role() = 'authenticated');
create policy "admin escribe mantenimientos" on mantenimientos for all using (auth.role() = 'authenticated');
create policy "admin escribe finanzas" on finanzas for all using (auth.role() = 'authenticated');

-- Cualquiera puede ENVIAR una solicitud de afiliación,
-- pero solo el administrador puede verla/gestionarla/borrarla.
create policy "cualquiera se afilia" on afiliaciones for insert with check (true);
create policy "admin gestiona afiliaciones" on afiliaciones for select using (auth.role() = 'authenticated');
create policy "admin borra afiliaciones" on afiliaciones for delete using (auth.role() = 'authenticated');
create policy "admin actualiza afiliaciones" on afiliaciones for update using (auth.role() = 'authenticated');

-- Mensualidades: información financiera individual por vivienda, nadie más que el administrador puede leerla ni escribirla.
create policy "admin gestiona mensualidades" on mensualidades for all using (auth.role() = 'authenticated');

-- Propietarios: lectura pública (para la consulta de turno por código), escritura solo del administrador.
create policy "admin escribe propietarios" on propietarios for all using (auth.role() = 'authenticated');
