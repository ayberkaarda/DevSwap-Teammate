// Add a service worker for processing Web Push notifications:
//
// self.addEventListener("push", async (event) => {
//   const { title, options } = await event.data.json()
//   event.waitUntil(self.registration.showNotification(title, options))
// })
//
// self.addEventListener("notificationclick", function(event) {
//   event.notification.close()
//   event.waitUntil(
//     clients.matchAll({ type: "window" }).then((clientList) => {
//       for (let i = 0; i < clientList.length; i++) {
//         let client = clientList[i]
//         let clientPath = (new URL(client.url)).pathname
//
//         if (clientPath == event.notification.data.path && "focus" in client) {
//           return client.focus()
//         }
//       }
//
//       if (clients.openWindow) {
//         return clients.openWindow(event.notification.data.path)
//       }
//     })
//   )
// })

// --- Minimal offline-capable service worker ---
// Amaç: uygulamayı "yüklenebilir" (installable) yapmak ve bağlantı yokken
// tamamen boş ekran yerine kısa bir mesaj göstermek. Karmaşık bir cache
// stratejisi yok — bilinçli olarak minimal.

const CACHE_NAME = "devswap-v1";
const PRECACHE_URLS = ["/", "/icon.png"];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches
      .open(CACHE_NAME)
      .then((cache) => cache.addAll(PRECACHE_URLS))
      // Asset'lerden biri 404 verirse TÜM install patlamasın diye yut.
      .catch(() => {})
  );
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key))
      )
    )
  );
  self.clients.claim();
});

self.addEventListener("fetch", (event) => {
  // Sadece sayfa navigasyonlarını ele al: network-first, olmazsa cache/fallback.
  // Diğer tüm request'leri (asset, XHR, vb.) network'e olduğu gibi bırak.
  if (event.request.mode !== "navigate") {
    return;
  }

  event.respondWith(
    fetch(event.request).catch(() =>
      caches.match(event.request).then(
        (cached) =>
          cached ||
          caches.match("/").then(
            (root) =>
              root ||
              new Response(
                "<!doctype html><meta charset=\"utf-8\"><title>DevSwap</title>" +
                  "<body style=\"font-family:monospace;background:#0a0a0a;color:#10b981;" +
                  "display:flex;align-items:center;justify-content:center;height:100vh;margin:0\">" +
                  "[SYS] Bağlantı yok — DevSwap çevrimdışı.</body>",
                { headers: { "Content-Type": "text/html; charset=utf-8" } }
              )
          )
      )
    )
  );
});
