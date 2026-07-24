// Service Worker — Gestión del Agua Limonar Sector II
// Recibe notificaciones push aunque la página esté cerrada

self.addEventListener('push', function(event) {
  if (!event.data) return;
  const data = event.data.json();
  const options = {
    body: data.body || '',
    icon: data.icon || '/GestionDelAguaLinonarSector2/icon-192.png',
    badge: data.badge || '/GestionDelAguaLinonarSector2/icon-192.png',
    tag: data.tag || 'turno-agua',
    requireInteraction: true,
    vibrate: [200, 100, 200],
    data: { url: data.url || '/GestionDelAguaLinonarSector2/' }
  };
  event.waitUntil(
    self.registration.showNotification(data.title || 'Gestión del Agua', options)
  );
});

self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  event.waitUntil(
    clients.openWindow(event.notification.data.url)
  );
});

self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', () => self.clients.claim());
