-- Sistema de contabilidad: categorías + movimientos, con conciliación
-- automática de pagos de mensualidad contra la tabla "propietarios".

-- Categorías de movimientos
create table contabilidad_categorias (
  id bigint generated always as identity primary key,
  nombre text not null unique,
  tipo text not null check (tipo in ('ingreso','gasto')),
  color text default '#1565C0',
  icono text default 'fa-circle',
  activa boolean default true
);

-- Movimientos contables
create table contabilidad_movimientos (
  id bigint generated always as identity primary key,
  fecha date not null default current_date,
  tipo text not null check (tipo in ('ingreso','gasto')),
  categoria_id bigint references contabilidad_categorias(id),
  descripcion text not null,
  valor numeric not null check (valor > 0),
  propietario_codigo text references propietarios(codigo),
  conciliado boolean default false,
  comprobante_url text,
  notas text,
  created_at timestamp with time zone default now()
);

-- RLS
alter table contabilidad_categorias enable row level security;
alter table contabilidad_movimientos enable row level security;

create policy "admin contabilidad categorias" on contabilidad_categorias for all using (auth.role() = 'authenticated');
create policy "admin contabilidad movimientos" on contabilidad_movimientos for all using (auth.role() = 'authenticated');

-- Categorías por defecto
insert into contabilidad_categorias (nombre, tipo, color, icono) values
('Mensualidad', 'ingreso', '#2E7D32', 'fa-droplet'),
('Otros ingresos', 'ingreso', '#1565C0', 'fa-coins'),
('Materiales y tubería', 'gasto', '#D32F2F', 'fa-wrench'),
('Mano de obra', 'gasto', '#E65100', 'fa-hammer'),
('Herramientas', 'gasto', '#6A1B9A', 'fa-toolbox'),
('Transporte', 'gasto', '#00838F', 'fa-truck'),
('Servicios (agua, luz)', 'gasto', '#558B2F', 'fa-bolt'),
('Imprevistos', 'gasto', '#BF360C', 'fa-triangle-exclamation'),
('Administración', 'gasto', '#37474F', 'fa-file-invoice');
