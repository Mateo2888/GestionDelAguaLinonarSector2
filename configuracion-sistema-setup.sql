-- Tabla de configuración del sistema, editable desde el panel admin
-- (pestaña "Configuración") sin tocar código.
create table configuracion (
  clave text primary key,
  valor text not null,
  descripcion text,
  updated_at timestamp with time zone default now()
);

alter table configuracion enable row level security;

-- Lectura pública (el sitio necesita leer la config para funcionar,
-- incluso para visitantes que no iniciaron sesión: modo mantenimiento,
-- WhatsApp del encargado, valor de la mensualidad, etc.)
create policy "lectura publica config" on configuracion for select using (true);

-- Solo admin puede editar
create policy "admin edita config" on configuracion for all using (auth.role() = 'authenticated');

-- Valores por defecto = los valores reales que ya tiene el sitio hoy
insert into configuracion (clave, valor, descripcion) values
('notificaciones_activas', 'true', 'Activar o desactivar el sistema de notificaciones push y voz'),
('voz_activa', 'true', 'Activar o desactivar los avisos de voz cuando la página está abierta'),
('minutos_aviso_inicio', '10', 'Minutos de anticipación para notificar antes de que inicie el turno'),
('minutos_aviso_fin', '5', 'Minutos de anticipación para notificar antes de que termine el turno'),
('duracion_turno_horas', '2', 'Duración de cada turno en horas'),
('valor_mensualidad', '25000', 'Valor del aporte mensual en COP'),
('whatsapp_encargado', '573170427446', 'Número de WhatsApp del encargado (con código de país, sin +)'),
('nombre_encargado', 'Mateo Castro', 'Nombre del encargado principal'),
('correo_encargado', 'gestionagualimonall@gmail.com', 'Correo del encargado'),
('sitio_en_mantenimiento', 'false', 'Mostrar un aviso de mantenimiento a los visitantes'),
('mensaje_mantenimiento', 'El sistema está en mantenimiento. Volvemos pronto.', 'Mensaje mostrado durante el mantenimiento'),
('ciclo_inicio_fecha', '2026-01-01', 'Fecha de inicio del ciclo de rotación de turnos (YYYY-MM-DD)');
