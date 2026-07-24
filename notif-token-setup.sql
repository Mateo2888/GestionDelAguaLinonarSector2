-- =========================================================
-- MIGRACIÓN: columna notif_token en reportes_dano y afiliaciones
-- Copia y pega TODO este archivo en: Supabase > SQL Editor > New query > Run
-- =========================================================
-- Guarda un identificador aleatorio (generado en el propio navegador
-- de quien envía el formulario) que permite avisarle por notificación
-- push cuando el administrador cambie el estado de SU reporte o
-- solicitud, sin depender de leer de vuelta el "id" de la fila recién
-- insertada — algo que estas tablas no permiten a un visitante público
-- por diseño (son privadas, solo el administrador puede leerlas).
-- =========================================================

alter table reportes_dano add column if not exists notif_token text;
alter table afiliaciones add column if not exists notif_token text;
