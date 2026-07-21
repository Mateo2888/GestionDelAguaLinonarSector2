-- =========================================================
-- MIGRACIÓN: Hacer privada la sección de Transparencia
-- Gestión del Agua Limonar Sector II
--
-- Este script quita el permiso de lectura pública de las tablas
-- "finanzas" y "documentos", para que solo un administrador
-- autenticado pueda verlas (igual que Reportes de daño,
-- Afiliaciones y Mensualidades).
--
-- Copia y pega TODO este script en: Supabase > SQL Editor > New query > Run
-- Ejecútalo UNA SOLA VEZ.
-- =========================================================

drop policy if exists "lectura publica finanzas" on finanzas;
drop policy if exists "lectura publica documentos" on documentos;

-- Nota: la política "admin escribe finanzas" / "admin escribe documentos"
-- (creada por supabase-setup.sql) ya le da al administrador autenticado
-- acceso completo de lectura y escritura, así que no hace falta crear
-- ninguna política nueva — al quitar la lectura pública, esas tablas
-- quedan completamente privadas para cualquier visitante.
