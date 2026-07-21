-- =========================================================
-- MIGRACIÓN: Eliminar la tabla "programacion" (ya no se usa en el sitio)
-- Copia y pega TODO este archivo en: Supabase > SQL Editor > New query > Run
-- =========================================================
-- La sección pública "Programación" fue reemplazada por "Mi turno"
-- (código de propietario + rotación automática). Esta tabla y sus
-- datos ya no se leen ni se escriben desde index.html.
--
-- "drop table" elimina la tabla, todas sus filas y sus políticas de
-- seguridad (RLS) de una sola vez, de forma segura: solo afecta a esta
-- tabla, no toca ninguna otra (noticias, mantenimientos, propietarios, etc.).
-- =========================================================

drop table if exists programacion;
