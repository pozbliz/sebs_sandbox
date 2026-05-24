#!/usr/bin/env ruby

RETIRE_SERVICE_WORKER = <<~JS
  /*
   * Retire Chirpy's previous service worker and cached HTML.
   *
   * The blog changes often enough that offline page caching is more harmful than
   * useful: old cached copies of "/" and tag pages can hide newly published posts.
   */
  self.addEventListener('install', (event) => {
    event.waitUntil(self.skipWaiting());
  });

  self.addEventListener('activate', (event) => {
    event.waitUntil(
      caches
        .keys()
        .then((keys) => Promise.all(keys.map((key) => caches.delete(key))))
        .then(() => self.registration.unregister())
        .then(() => self.clients.matchAll({ type: 'window' }))
        .then((clients) => {
          clients.forEach((client) => client.navigate(client.url));
        })
    );
  });

  self.addEventListener('fetch', () => {
    // Intentionally empty: after activation this worker unregisters itself.
  });
JS

Jekyll::Hooks.register :site, :post_write do |site|
  File.write(File.join(site.dest, "sw.min.js"), RETIRE_SERVICE_WORKER)
end
