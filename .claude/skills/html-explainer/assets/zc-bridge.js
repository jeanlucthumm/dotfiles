/*
  Live comments in any browser. Load after comment-layer.js. Dormant unless the
  page URL carries ?live, so pages without a relay make no requests.

  Relays the comment layer's session hooks (window.zcLive.drain / answer)
  through a local relay, scripts/zc-bridge-server.py, instead of the CDP door
  terminal-browser uses. While the relay reports a watching session, each poll
  drains new comments and pushes them; answers and reloads come back on the
  same poll. Port: window.zcBridgePort or 47321.
*/
(function () {
  if (!/[?&]live\b/.test(location.search)) return;
  const base = 'http://127.0.0.1:' + (window.zcBridgePort || 47321);
  let unsent = [];  // drained but not yet delivered; retried next poll
  let misses = 0;

  async function tick() {
    try {
      if (!window.zcLive) return;
      const s = await (await fetch(base + '/page/poll', { cache: 'no-store' })).json();
      for (const o of s.out) {
        if (o.reload) { location.reload(); return; }
        if (o.answer) window.zcLive.answer(o.answer.n, o.answer.md);
      }
      if (s.watching) unsent = unsent.concat(window.zcLive.drain());
      if (unsent.length) {
        // text/plain keeps the POST a simple request, so no CORS preflight.
        await fetch(base + '/page/comments', { method: 'POST', headers: { 'Content-Type': 'text/plain' }, body: JSON.stringify(unsent) });
        unsent = [];
      }
      misses = 0;
    } catch (e) {
      misses = Math.min(misses + 1, 10);  // relay not running: back off
    } finally {
      setTimeout(tick, 1500 * (1 + misses));
    }
  }
  if (document.readyState === 'complete') tick(); else window.addEventListener('load', tick, { once: true });
})();
