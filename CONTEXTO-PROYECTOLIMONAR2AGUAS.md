# Contexto del proyecto — Gestión del Agua Limonar Sector II

Pega este documento completo como primer mensaje a Claude Code para que tenga todo el contexto del proyecto sin necesidad de preguntarme nada más a mí.

## Qué es esto
Sitio web comunitario para gestionar el sistema de agua del barrio Limonar Sector II, Soacha, Cundinamarca. Es un sitio estático (un solo `index.html` con CSS y JS embebidos) conectado a Supabase como backend.

## Repositorio y hosting
- Repo GitHub: https://github.com/Mateo2888/GestionDelAguaLinonarSector2 (rama `main`, público)
- Publicado con GitHub Pages en: https://mateo2888.github.io/GestionDelAguaLinonarSector2/
- Archivo principal: `index.html` en la raíz del repo (single-file: HTML + `<style>` + `<script>`)
- Otros archivos en el repo: `supabase-setup.sql` (script de creación de tablas), `INSTRUCCIONES.md` (guía de puesta en marcha)

## Stack técnico
- HTML5 + CSS3 (variables CSS, glassmorphism, modo oscuro vía `data-theme` en `<body>`) + JavaScript vanilla (sin frameworks ni build step)
- Supabase JS v2 cargado por CDN (`https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2`) para: base de datos (Postgres), autenticación (login del panel admin), y storage (fotos de reportes de daño)
- Font Awesome 6.5.1 (CDN) para íconos, Google Fonts (Poppins + Inter)
- Sin backend propio, sin Node/build tools — todo corre en el navegador

## Backend Supabase (ya configurado y en producción)
- Proyecto: `agua-limonar-sector-2`, Project ID: `owhtiqoshemfchrsvsib`
- 8 tablas creadas con `supabase-setup.sql`: `programacion`, `noticias`, `galeria`, `mantenimientos`, `finanzas`, `documentos`, `reportes_dano`, `afiliaciones`
- RLS activado: lectura pública en las tablas de contenido; escritura solo para usuarios autenticados (`auth.role() = 'authenticated'`); `reportes_dano` y `afiliaciones` permiten `insert` público pero `select/update/delete` solo autenticado
- Bucket de Storage `fotos` creado como público (para subir fotos de reportes de daño)
- Ya existe un usuario administrador creado en Authentication > Users (el correo/contraseña los tiene el dueño del proyecto, no yo)
- Las credenciales (`SUPABASE_URL` y `SUPABASE_ANON_KEY`, la "Publishable key") **ya están puestas en `index.html`**, cerca de la línea 795, dentro del `<script>` principal — commit `1cc11ce` "Conectar sitio con Supabase". No las borres ni las regreses a los placeholders `TU_SUPABASE_URL` / `TU_SUPABASE_ANON_KEY`.

## Arquitectura del JS en index.html (para orientarte en el código)
- Bloque de config arriba del `<script>` principal: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, variable `sbClient` (cliente de Supabase) y flag `usingSupabase`.
- Objeto `DEMO` con datos de ejemplo (fallback si Supabase no está configurado) y `STATE` (estado en memoria que se renderiza).
- `loadAll()` trae datos de las 8 tablas de Supabase y llama a las funciones `render*()` de cada sección (programación, noticias, galería, mantenimientos, finanzas, documentos).
- Formularios públicos (`damageForm`, `affiliateForm`) insertan filas en `reportes_dano` y `afiliaciones` vía `insertRow()`.
- Panel administrativo (oculto tras un ícono de candado, login con `sbClient.auth.signInWithPassword`) con pestañas por tabla y funciones `add*()` / `crudDelete()` que hacen insert/delete directo en Supabase.
- Dark mode, menú móvil, contador animado de estadísticas, acordeón FAQ, lightbox de galería, botones flotantes (WhatsApp fijo, volver arriba): todo JS vanilla al final del archivo, sin dependencias externas.

## BUG ACTUAL A CORREGIR (prioridad inmediata)
✅ **Resuelto** — ver "Registro de cambios" al final del documento (commit `e357040`, 2026-07-20). Se deja el detalle abajo como referencia histórica del problema y del arreglo aplicado.

Al conectar Supabase apareció este error en consola del navegador:
```
Uncaught SyntaxError: Identifier 'supabase' has already been declared (at index.html:790:9)
```
**Causa:** la librería `@supabase/supabase-js` crea un global `window.supabase`, y el código del sitio también declaraba `let supabase = null;` — mismo nombre, choque de identificadores, rompe toda la página (nada de CSS/JS corre después de ese error).

**Arreglo necesario** (probablemente ya lo hice en una sesión anterior contigo, Claude Code — verifica primero si ya está aplicado revisando si existe la variable `sbClient` en el archivo; si no, aplícalo):
1. Renombrar `let supabase = null;` → `let sbClient = null;`
2. Renombrar la asignación `supabase = window.supabase.createClient(...)` → `sbClient = window.supabase.createClient(...)` (dejar `window.supabase.createClient` intacto, esa parte SÍ debe seguir diciendo `supabase` porque es la librería).
3. En todo el resto del archivo, todo uso de `supabase.from(`, `supabase.auth.`, `supabase.storage.` (como variable propia, no como `window.supabase`) → cambiar a `sbClient.from(`, `sbClient.auth.`, `sbClient.storage.`
4. Eliminar esta etiqueta duplicada/errónea si sigue en el `<head>` (carga un CSS como si fuera un script, genera un warning de MIME type):
   ```html
   <script src="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css" defer></script>
   ```
   (debe quedar solo el `<link rel="stylesheet" href="...font-awesome.../all.min.css">`, no el `<script>`).
5. No tocar `SUPABASE_URL` ni `SUPABASE_ANON_KEY` (ya tienen los valores reales).
6. Verificar sintaxis del JS embebido antes de dar por terminado (extraer el contenido entre `<script>...</script>` del bloque principal y validar, por ejemplo con `node --check`).
7. Commit + push a `main`.

Después de este fix, probar en vivo (esperar 1-2 min por el deploy de GitHub Pages, recargar con Ctrl+Shift+R, revisar la consola del navegador con F12 — no debe haber errores rojos) y confirmar que:
- La sección "Programación" carga las filas de ejemplo desde Supabase (Familia Torres, Familia Ríos, Familia Suárez).
- El candado 🔒 (abajo a la izquierda) abre el modal de login y con el usuario administrador ya creado se puede entrar al panel.
- Desde el panel se puede agregar un registro nuevo y verlo reflejado en la tabla pública tras refrescar.

## Pendientes de personalización
- ~~Número de WhatsApp~~ ✅ ya actualizado a `+57 317 042 7446` (ver Registro de cambios).
- ~~Correo~~ ✅ ya actualizado a `gestionagualimonall@gmail.com` (ver Registro de cambios).
- Nombre del encargado / contacto: sección `<!-- ============ CONTACTO ============ -->` — el usuario confirmó que "Mateo Castro" ya es el nombre real, no requiere cambio.
- Fotos: el hero usa un patrón CSS decorativo (no foto); galería y noticias usan imágenes de stock de Unsplash como placeholder — el usuario no tiene fotos reales a mano todavía, queda pendiente para cuando las tenga.
- Datos de ejemplo en Supabase (programación, finanzas, etc.) son de prueba — se pueden editar/borrar desde el panel admin sin tocar código.

## Preferencias del usuario
- El usuario no es programador, trabaja desde VS Code con Claude Code, prefiere que Claude Code haga los cambios de código + git directamente en vez de explicarle paso a paso.
- Priorizó calidad y velocidad ("rápido y excelente") sobre control manual del código.
- **Convención vigente:** cada vez que se haga un cambio importante en el proyecto (arreglar un bug, conectar algo nuevo, agregar una función), Claude Code debe agregar una entrada nueva en "Registro de cambios" (abajo) con fecha, qué se hizo y qué quedó pendiente, para que este documento siempre refleje el estado real del proyecto.

## Registro de cambios

### 2026-07-20 — Conectar sitio con Supabase
**Qué se hizo:** se reemplazaron los placeholders `TU_SUPABASE_URL` / `TU_SUPABASE_ANON_KEY` en `index.html` (~línea 795) por las credenciales reales del proyecto Supabase (`owhtiqoshemfchrsvsib`). Commit `1cc11ce`, push a `main`.
**Qué quedó pendiente:** justo después de este cambio apareció un error en consola por choque de nombres entre la variable propia `supabase` y el global `window.supabase` de la librería (ver entrada siguiente).

### 2026-07-20 — Corregir conflicto de variable `supabase`
**Qué se hizo:** se renombró la variable propia `let supabase` → `let sbClient` en todo `index.html` (declaración, asignación con `window.supabase.createClient(...)`, y todos los usos `.from(`, `.auth.`, `.storage.`), sin tocar `window.supabase.createClient` ni el CDN de `@supabase/supabase-js`. También se eliminó una etiqueta `<script>` duplicada e incorrecta del CDN de Font Awesome en el `<head>` (dejando solo el `<link rel="stylesheet">`). Commit `e357040`, push a `main`.
**Qué quedó pendiente:** probar en vivo tras el deploy de GitHub Pages (Ctrl+Shift+R, revisar consola con F12) para confirmar que ya no aparece el error de `Identifier 'supabase' has already been declared` y que la sección "Programación", el login del panel admin y el alta de registros funcionan correctamente. También siguen pendientes las personalizaciones listadas en "Pendientes de personalización" (WhatsApp, correo, nombre de contacto, fotos reales).

### 2026-07-20 — Personalizar WhatsApp y correo de contacto
**Qué se hizo:** en `index.html` se reemplazó el número de WhatsApp placeholder (`573000000000`) por el real `+57 317 042 7446` en las 4 apariciones (ícono flotante `fab-whats`, enlace `tel:`, texto visible en "Contacto", y la función JS que abre `wa.me` con el mensaje del formulario de reporte de daño). También se reemplazó el correo placeholder `contacto@limonarsector2.org` por el real `gestionagualimonall@gmail.com` en la sección de contacto.
**Qué quedó pendiente:** faltan las fotos reales del sector (hero, galería, noticias siguen con imágenes de stock/patrón CSS) — el usuario las agregará cuando las tenga. El nombre del encargado ("Mateo Castro") y los datos de ejemplo en Supabase no requieren cambio por ahora.

### 2026-07-20 — Manejo de errores de Supabase (red y datos)
**Qué se hizo:** en `index.html` se mejoró el manejo de errores en las llamadas a Supabase, que antes solo registraban fallos en consola (`console.warn`) sin avisar al usuario:
- `loadAll()`: ahora distingue si fallan todas las tablas (aviso "No se pudo conectar con la base de datos, mostrando datos de ejemplo") o solo algunas (aviso "Algunas secciones no cargaron datos actualizados, recarga la página"), en vez de fallar en silencio.
- `insertRow()`, `crudInsert()`, `crudDelete()`, login (`signInWithPassword`): se les agregó `try/catch` para capturar fallos de red (antes solo se manejaba el `error` que devuelve Supabase, no una excepción por falta de conexión), mostrando un toast claro pidiendo revisar la conexión a internet.
- Subida de foto en el formulario de reporte de daño: si falla la subida a Supabase Storage, ahora se avisa con un toast ("No se pudo subir la foto, se enviará el reporte sin ella") en vez de continuar en silencio sin la foto.
Se validó la sintaxis del bloque `<script>` con `node --check` antes de confirmar. Commit pendiente de push en este mismo mensaje de registro.
**Qué quedó pendiente:** no se agregó un indicador visual de "cargando" (spinner/skeleton) mientras `loadAll()` trae los datos la primera vez — por ahora solo se avisa si algo falla, no mientras carga. Seguir pendientes: fotos reales del sector, y las demás mejoras no elegidas en esta ronda (SEO/redes sociales, revisión de datos de ejemplo en Supabase, accesibilidad/mobile).

### 2026-07-21 — Eliminar datos de prueba y vaciar respaldo local
**Qué se hizo:** se verificó con una consulta de solo lectura a la API de Supabase (usando la llave pública) qué tablas tenían datos de prueba reales en producción: `programacion` (3 filas: Familia Torres, Familia Ríos, Familia Suárez) y `finanzas` (2 filas: Aportes mensuales, Compra de manguera) — ambas sembradas por `supabase-setup.sql`. `noticias`, `galeria`, `mantenimientos` y `documentos` ya estaban vacías. `reportes_dano` y `afiliaciones` no se pudieron revisar (RLS bloquea lectura sin sesión de admin) pero el usuario confirmó que no hizo pruebas ahí.
En `index.html` se vació por completo el objeto `DEMO` (el respaldo local que se usa solo si el sitio no logra conectarse a Supabase) — antes tenía datos falsos (Familia Torres, noticias de ejemplo, fotos de stock de Unsplash, etc.), ahora son arreglos vacíos, así el sitio nunca muestra información inventada a un visitante real. Se corrigió también el texto del aviso de error de conexión total, que antes decía "mostrando datos de ejemplo" (ya no aplica) y ahora dice "recarga la página o intenta más tarde".
En `supabase-setup.sql` se eliminó la sección final `-- DATOS DE EJEMPLO` (los `insert` de prueba para `programacion` y `finanzas`), para que si el script se vuelve a ejecutar en otro proyecto no siembre datos falsos.
**Qué quedó pendiente:** las 5 filas de prueba que siguen en la base de datos EN VIVO (`programacion` x3, `finanzas` x2) no se pudieron borrar desde aquí — Supabase las protege con RLS y solo un administrador autenticado puede borrarlas. El usuario las borrará manualmente entrando al candado 🔒 del sitio, iniciando sesión como admin, y usando el botón de basura en cada fila de las pestañas "Programación" y "Transparencia". También se detectó (resuelto en la siguiente entrada) que el panel admin no tenía pestaña para ver/gestionar `reportes_dano` ni `afiliaciones`.

### 2026-07-21 — Agregar pestañas "Reportes de daño" y "Afiliaciones" al panel admin
**Qué se hizo:** en `index.html` se agregaron dos pestañas nuevas al panel administrativo (antes solo existían para Programación, Noticias, Galería, Mantenimientos, Transparencia y Documentos):
- **Reportes de daño**: lista los reportes enviados por el formulario público (nombre, sector, dirección, descripción, foto si tiene), con un selector de estado (Nuevo / En proceso / Resuelto) y botón para borrar.
- **Afiliaciones**: lista las solicitudes enviadas por el formulario público (nombre, sector, dirección, teléfono), con un selector de estado (Pendiente / Aprobada / Rechazada) y botón para borrar.
Estas dos tablas solo se cargan (`loadAdminExtras()`) después de iniciar sesión como admin —no antes, porque la política RLS de Supabase bloquea la lectura pública de esas tablas a propósito (contienen datos personales de vecinos)— y se limpian de `STATE` al cerrar sesión, para no dejar datos sensibles en memoria. Se agregó `crudUpdateEstado()` para cambiar el estado desde el selector, usando las políticas de `update` que ya existían en `supabase-setup.sql`.
Durante la implementación se encontró y corrigió un bug antes de publicarlo: `localName()` no reconocía las tablas `reportes_dano` ni `afiliaciones`, lo que habría roto el botón de borrar (el registro se habría borrado en Supabase pero el código habría fallado justo después, sin refrescar la lista ni avisar del error). Se agregó el mapeo faltante.
Se validó sintaxis JS (`node --check`) y balance de `<div>` (197/197) antes de confirmar.
**Qué quedó pendiente:** no se agregó paginación ni filtro/búsqueda en estas dos listas nuevas (no debería ser un problema mientras el volumen de reportes/afiliaciones sea bajo). Seguir pendientes de rondas anteriores: fotos reales del sector, indicador de "cargando", SEO/redes sociales, accesibilidad/mobile.

### 2026-07-21 — SEO y redes sociales
**Qué se hizo:** en `index.html` se completaron las etiquetas de cabecera para compartir el link y para buscadores (ya existían título, descripción y algunas etiquetas Open Graph básicas):
- `<link rel="canonical">` y `og:url` apuntando a la URL real de GitHub Pages.
- `og:site_name` y `og:locale` (`es_CO`).
- Etiquetas Twitter Card (`twitter:card`, `twitter:title`, `twitter:description`).
- Datos estructurados JSON-LD tipo `Organization` con nombre, URL, descripción, correo (`gestionagualimonall@gmail.com`), teléfono (`+573170427446`) y dirección (Soacha, Cundinamarca, CO) — ayuda a que Google entienda de qué trata el sitio y quién es el contacto.
Se crearon dos archivos nuevos en la raíz del repo: `robots.txt` (permite indexar todo, apunta al sitemap) y `sitemap.xml` (una sola URL, la página principal).
Se validó: JSON-LD es JSON válido, sitemap es XML válido, sintaxis JS sigue OK y `<div>`/`<head>` balanceados.
**Qué quedó pendiente:** no se agregó `og:image` ni `twitter:image` (la vista previa al compartir el link en WhatsApp/Facebook seguirá sin miniatura) — este entorno no tiene herramientas para generar/rasterizar una imagen de buena calidad, y además no hay fotos reales del sector todavía (mismo pendiente de siempre). Cuando el usuario tenga un logo o foto representativa, agregar esas dos etiquetas con la URL de esa imagen.

### 2026-07-21 — Indicador de "cargando" y accesibilidad
**Qué se hizo:** dos mejoras en `index.html`, agrupadas en el mismo commit:
- **Indicador de carga:** mientras `loadAll()` trae los datos de Supabase por primera vez, las secciones (Programación, Noticias, Galería, Mantenimientos, Transparencia, Documentos) ahora muestran un spinner con "Cargando..." en vez de verse vacías sin explicación. Se agregó la función `showLoadingState()` y la clase CSS `.loading-state`.
- **Accesibilidad**, revisando el HTML real en vez de asumir problemas genéricos (se midió contraste de color con la fórmula WCAG y todos los pares texto/fondo del sitio ya pasaban AA cómodamente, así que no se tocó eso):
  - Los `<label>` de los 4 formularios (reportar daño, contacto, afiliación, login) no estaban asociados a su campo (`for`/`id` faltante) — un lector de pantalla no sabía a qué campo correspondía cada etiqueta. Se agregó `id` a cada campo y `for` a cada label (12 en total), verificado que todos coincidan.
  - El acordeón de preguntas frecuentes y las fotos de la galería eran `<div>` con `onclick`, invisibles para navegación por teclado. El acordeón ahora tiene `role="button"`, `tabindex="0"`, `aria-expanded` sincronizado, y responde a Enter/Espacio. Las fotos de la galería pasaron de `<div>` a `<button>` real con `aria-label` descriptivo.
  - Botones de solo ícono sin nombre accesible (menú hamburguesa, cerrar menú, cerrar imagen ampliada) recibieron `aria-label`; el botón de cerrar del lightbox pasó de `<span>` a `<button>`. El menú hamburguesa ahora sincroniza `aria-expanded`.
  - Imágenes sin `alt` o con `alt=""` no justificado: fotos de galería (ahora descritas por el `aria-label` del botón que las contiene, así que el `<img>` queda `alt=""` a propósito para no duplicar), foto de mantenimiento (ahora usa la actividad como alt), miniaturas del panel admin (galería y reportes de daño).
  - Se agregó un enlace "Saltar al contenido" (`.skip-link`), visible solo al enfocarlo con teclado, antes del menú de navegación.
Se validó: sintaxis JS (`node --check`), balance de `<div>`/`<button>`/`<span>`/`<form>`/`<label>`, y que cada `for=` de los labels tenga un `id=` real correspondiente (12/12 coinciden).
**Qué quedó pendiente:** no se tocó el enfoque visual (outline) de los campos de formulario al hacer foco — ya cambia de color/fondo al enfocar y cumple el mínimo de la norma, así que se dejó como estaba para no alterar el diseño sin necesidad. Tampoco se ajustó el tamaño de los botones flotantes/hamburguesa (40px, ligeramente por debajo del recomendado de 44px) por ser un desvío menor. Seguir pendientes de siempre: fotos reales del sector, `og:image`.
