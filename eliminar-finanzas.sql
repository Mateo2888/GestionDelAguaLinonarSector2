-- PASO 2 de 2 — Ejecutar SOLO después de correr
-- "migrar-finanzas-a-contabilidad.sql" y de revisar en la pestaña
-- "Contabilidad" que los movimientos migrados se ven bien.
--
-- Borra por completo la vieja tabla "finanzas" (pestaña "Ingresos",
-- ya retirada del sitio — reemplazada por el módulo de Contabilidad).
-- Esto es IRREVERSIBLE: una vez corrido, los datos originales de
-- "finanzas" ya no se pueden recuperar (aunque ya deberían estar
-- copiados en "contabilidad_movimientos" por el paso 1).

drop table if exists finanzas;
