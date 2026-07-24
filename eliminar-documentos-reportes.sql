-- =========================================================
-- MIGRACIÓN: eliminar por completo "Documentos" y "Reportes de daño"
-- Copia y pega TODO este archivo en: Supabase > SQL Editor > New query > Run
-- =========================================================
-- El sitio ya no usa estas dos tablas (se quitaron sus pestañas del
-- panel admin y, en el caso de "Reportar daño", el formulario público
-- ahora redirige directo a WhatsApp en vez de guardar en Supabase).
-- Este script borra las tablas Y las fotos que hubieran quedado
-- guardadas en Storage por reportes de daño antiguos, para no dejar
-- nada huérfano ocupando espacio.
-- =========================================================

-- Fotos de reportes de daño guardadas en el bucket "fotos" (carpeta
-- "reportes/"). No afecta las fotos de comprobantes de Finanzas
-- ("comprobantes/"), esas se quedan igual.
delete from storage.objects where bucket_id = 'fotos' and name like 'reportes/%';

drop table if exists reportes_dano;
drop table if exists documentos;
