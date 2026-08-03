// Service Worker — Gestión del Agua Limonar Sector II
// Versión: 2.0 — Modo offline completo

const CACHE_ESTATICO = 'limonar-estatico-v2';
const CACHE_DINAMICO = 'limonar-dinamico-v2';

// Recursos que se cachean inmediatamente al instalar.
// Las URLs de librerías externas deben coincidir exactamente con las
// que carga index.html (jsPDF y Chart.js vienen de jsdelivr, no cdnjs).
const RECURSOS_ESENCIALES = [
  '/GestionDelAguaLinonarSector2/',
  '/GestionDelAguaLinonarSector2/index.html',
  '/GestionDelAguaLinonarSector2/manifest.json',
  '/GestionDelAguaLinonarSector2/icon-192.png',
  // Fuentes y librerías externas críticas
  'https://fonts.googleapis.com/css2?family=Poppins:wght@500;600;700;800&family=Inter:wght@400;500;600;700&display=swap',
  'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css',
  'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2',
  'https://cdn.jsdelivr.net/npm/jspdf@2.5.2/dist/jspdf.umd.min.js',
  'https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js'
];

// Instalar: cachear recursos esenciales
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_ESTATICO)
      .then(cache => {
        return Promise.allSettled(
          RECURSOS_ESENCIALES.map(url =>
            cache.add(url).catch(e =>
              console.warn('No se pudo cachear:', url, e)
            )
          )
        );
      })
      .then(() => self.skipWaiting())
  );
});

// Activar: limpiar caches viejos
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(
        keys
          .filter(key =>
            key !== CACHE_ESTATICO &&
            key !== CACHE_DINAMICO
          )
          .map(key => caches.delete(key))
      )
    ).then(() => self.clients.claim())
  );
});

// Fetch: estrategia inteligente por tipo de recurso
self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);

  // Ignorar peticiones que no son GET
  if(event.request.method !== 'GET') return;

  // Ignorar peticiones a Supabase API
  // (datos en tiempo real, no cachear)
  if(url.hostname.includes('supabase.co') &&
     url.pathname.includes('/rest/')) {
    event.respondWith(
      fetch(event.request)
        .catch(() => new Response(
          JSON.stringify([]),
          {headers: {'Content-Type': 'application/json'}}
        ))
    );
    return;
  }

  // Ignorar Auth de Supabase
  if(url.hostname.includes('supabase.co') &&
     url.pathname.includes('/auth/')) {
    return;
  }

  // Estrategia: Cache First para recursos estáticos
  // (HTML, CSS, JS, fuentes, iconos)
  if(
    url.pathname.endsWith('.html') ||
    url.pathname.endsWith('.js') ||
    url.pathname.endsWith('.css') ||
    url.pathname.endsWith('.png') ||
    url.pathname.endsWith('.jpg') ||
    url.pathname.endsWith('.svg') ||
    url.pathname.endsWith('.json') ||
    url.hostname === 'fonts.googleapis.com' ||
    url.hostname === 'fonts.gstatic.com' ||
    url.hostname === 'cdnjs.cloudflare.com' ||
    url.hostname === 'cdn.jsdelivr.net'
  ) {
    event.respondWith(
      caches.match(event.request)
        .then(cached => {
          if(cached) return cached;
          return fetch(event.request)
            .then(response => {
              if(response && response.status === 200) {
                const clone = response.clone();
                caches.open(CACHE_ESTATICO)
                  .then(cache => cache.put(
                    event.request, clone
                  ));
              }
              return response;
            })
            .catch(() => {
              // Si es el HTML principal,
              // devolver la versión cacheada
              if(url.pathname.endsWith('.html') ||
                 url.pathname === '/GestionDelAguaLinonarSector2/') {
                return caches.match(
                  '/GestionDelAguaLinonarSector2/index.html'
                );
              }
            });
        })
    );
    return;
  }

  // Estrategia: Network First para el resto
  // (intenta internet, si falla usa cache)
  event.respondWith(
    fetch(event.request)
      .then(response => {
        if(response && response.status === 200) {
          const clone = response.clone();
          caches.open(CACHE_DINAMICO)
            .then(cache => cache.put(
              event.request, clone
            ));
        }
        return response;
      })
      .catch(() => caches.match(event.request))
  );
});

// Notificaciones push (igual que antes)
self.addEventListener('push', event => {
  if(!event.data) return;
  const data = event.data.json();
  const options = {
    body: data.body || '',
    icon: data.icon ||
      '/GestionDelAguaLinonarSector2/icon-192.png',
    badge: data.badge ||
      '/GestionDelAguaLinonarSector2/icon-192.png',
    tag: data.tag || 'turno-agua',
    requireInteraction: true,
    vibrate: [200, 100, 200],
    data: {
      url: data.url ||
        '/GestionDelAguaLinonarSector2/'
    }
  };
  event.waitUntil(
    self.registration.showNotification(
      data.title || 'Gestión del Agua', options
    )
  );
});

self.addEventListener('notificationclick', event => {
  event.notification.close();
  event.waitUntil(
    clients.openWindow(event.notification.data.url)
  );
});
