-- PASO 1 de 2 — Migra los movimientos históricos de la vieja tabla
-- "finanzas" (pestaña "Ingresos", ya retirada del sitio) a la nueva
-- "contabilidad_movimientos". Es seguro correr esto aunque "finanzas"
-- esté vacía. NO borra nada todavía — eso es el paso 2, aparte,
-- para que puedas revisar los datos migrados antes de borrar el original.
--
-- El mapeo de categorías es aproximado (los nombres de categoría de
-- "finanzas" eran texto libre y no coinciden 1 a 1 con las categorías
-- nuevas) — después de correr esto, revisa en la pestaña "Contabilidad"
-- que las categorías asignadas tengan sentido y corrígelas a mano si
-- algún movimiento quedó mal clasificado.
--
-- Si el concepto de un movimiento termina en "(LM045)" y ese código
-- existe en "propietarios", se enlaza automáticamente como pago
-- conciliado de ese propietario.

insert into contabilidad_movimientos (fecha, tipo, categoria_id, descripcion, valor, propietario_codigo, conciliado, comprobante_url, created_at)
select
  f.fecha,
  f.tipo,
  case
    when f.tipo = 'ingreso' and f.categoria = 'Aportes' then (select id from contabilidad_categorias where nombre = 'Mensualidad')
    when f.tipo = 'ingreso' then (select id from contabilidad_categorias where nombre = 'Otros ingresos')
    when f.tipo = 'gasto' and f.categoria in ('Compras','Mantenimiento') then (select id from contabilidad_categorias where nombre = 'Materiales y tubería')
    when f.tipo = 'gasto' and f.categoria = 'Pago a encargados' then (select id from contabilidad_categorias where nombre = 'Mano de obra')
    else (select id from contabilidad_categorias where nombre = 'Administración')
  end as categoria_id,
  f.concepto as descripcion,
  f.valor,
  p.codigo as propietario_codigo,
  (p.codigo is not null) as conciliado,
  f.comprobante as comprobante_url,
  f.created_at
from finanzas f
left join propietarios p on p.codigo = substring(f.concepto from '\(([A-Za-z0-9]+)\)\s*$');
