const CACHE_NAME = "weblinux-xfce-v1";
const ASSETS = [
  "./",
  "./index.html",
  "./libv86.js",
  "./v86.wasm",
  "./seabios.bin",
  "./vgabios.bin",
  "./alpine-xfce-web.img"
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(ASSETS))
  );
  self.skipWaiting();
});

self.addEventListener("fetch", (event) => {
  event.respondWith(
    caches.match(event.request).then((cached) => cached || fetch(event.request))
  );
});
