/* ============================================================
  zc comment layer. Explainers load it by reference:
    <script src="../../../.claude/skills/html-explainer/assets/comment-layer.js"></script>
  scripts/share-copy.py inlines it for copies that leave this machine.

    - select text -> "Comment" bubble -> anchored note (highlight)
    - Pin (rare) -> click anywhere (e.g. SVG diagrams) -> anchored note
    - widget "Copy all" builds an agent-readable payload and clears
    - optional page hook: window.zcExtraContext = (clickTarget) => string|null
    - test API: window.zergComments = { list, payload }

  Live mode: dormant until a session polls window.zcLive.drain(). While polls
  keep arriving (<8s apart) the widget shows "live", new comments and
  follow-ups queue for the session, and window.zcLive.answer(n, markdown)
  renders the reply in the comment's thread. See the skill's live.md.
============================================================= */
(function () {
  'use strict';

  /* --- inject styles ------------------------------------------------- */
  const css = `
  /* ---- zc tokens: namespaced so they never clobber the host page ---- */
  :root {
    --zc-ink: #1f1d1a; --zc-ink-2: #4a463f; --zc-muted: #7a746a; --zc-faint: #a39d92;
    --zc-surface: #ffffff; --zc-sunken: #f5f3ee; --zc-line: #e7e3da; --zc-line-2: #d8d2c5;
    --zc-accent: #3a5bc7; --zc-accent-hover: #2f4cab; --zc-accent-soft: #e8edfa;
    --zc-plain: #c07a12;  --zc-plain-hl: #fbe6a2;    /* ochre marginalia */
    --zc-wait: #5b5bd6;   --zc-wait-hl: #e3e3fa;     /* periwinkle, in flight */
    --zc-done: #2f8a5b;   --zc-done-hl: #d8eee0;     /* sage, answered */
    --zc-danger: #b4432f;
    --zc-sans: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Segoe UI", system-ui, sans-serif;
    --zc-serif: ui-serif, "New York", "Iowan Old Style", Charter, Georgia, serif;
    --zc-mono: ui-monospace, "SF Mono", Menlo, Consolas, monospace;
    --zc-r-sm: 7px; --zc-r-md: 10px; --zc-r-lg: 14px;
    --zc-shadow-1: 0 1px 2px rgba(40,30,15,.08), 0 1px 1px rgba(40,30,15,.04);
    --zc-shadow-2: 0 2px 6px rgba(40,30,15,.06), 0 8px 24px rgba(40,30,15,.10);
    --zc-shadow-3: 0 2px 8px rgba(40,30,15,.06), 0 16px 40px -6px rgba(40,30,15,.18);
    --zc-ease: cubic-bezier(.2,.8,.2,1); --zc-pop: cubic-bezier(.34,1.45,.64,1);
  }
  ::highlight(zc) { background: var(--zc-plain-hl); }
  /* state reads from the underline too, not just tint (tint alone is close to ::selection) */
  ::highlight(zc-wait) { background: var(--zc-wait-hl); text-decoration: underline dotted var(--zc-wait); text-decoration-thickness: 2px; text-underline-offset: 3px; }
  ::highlight(zc-done) { background: var(--zc-done-hl); text-decoration: underline var(--zc-done); text-decoration-thickness: 1.5px; text-underline-offset: 3px; }
  .zc-ui { font: 13px/1.45 var(--zc-sans); color: var(--zc-ink); -webkit-font-smoothing: antialiased; }
  .zc-ui svg { width: 14px; height: 14px; flex: none; display: block; }
  .zc-ui button:focus-visible { outline: 2px solid var(--zc-accent); outline-offset: 2px; }

  /* ---- floating pill ---- */
  .zc-widget { position: fixed; right: 18px; bottom: 18px; z-index: 9999; display: flex; gap: 4px; align-items: center;
    background: rgba(255,255,255,.86); -webkit-backdrop-filter: saturate(1.4) blur(12px); backdrop-filter: saturate(1.4) blur(12px);
    border: 1px solid var(--zc-line); border-radius: 999px; padding: 5px 5px 5px 14px; box-shadow: var(--zc-shadow-2); }
  .zc-widget button { display: inline-flex; align-items: center; gap: 6px; border: 0; background: transparent; border-radius: 999px;
    padding: 6px 11px; font: 500 12.5px/1 var(--zc-sans); cursor: pointer; color: var(--zc-ink-2);
    transition: background .15s var(--zc-ease), color .15s var(--zc-ease); }
  .zc-widget button:hover:not(:disabled) { background: var(--zc-sunken); color: var(--zc-ink); }
  .zc-widget button:disabled { color: var(--zc-faint); cursor: default; }
  .zc-widget button.zc-on { background: var(--zc-ink); color: #fff; }
  /* Pin is rare: icon-only, quiet, sits last; text selection is the main path */
  .zc-widget #zc-pin { order: 3; width: 28px; height: 28px; padding: 0; justify-content: center; color: var(--zc-faint); }
  .zc-widget #zc-pin:hover { color: var(--zc-ink-2); }
  .zc-widget #zc-pin.zc-on { color: #fff; }
  .zc-widget #zc-copy { color: var(--zc-ink); }
  #zc-count { color: var(--zc-muted); font-size: 12.5px; font-variant-numeric: tabular-nums; margin-right: 6px; padding-right: 10px;
    border-right: 1px solid var(--zc-line); line-height: 18px; }
  .zc-widget .zc-live { display: none; align-items: center; gap: 6px; padding: 4px 9px 4px 8px; margin: 0 4px 0 -8px; border-radius: 999px;
    background: var(--zc-done-hl); color: var(--zc-done); font: 600 11px/1 var(--zc-sans); letter-spacing: .06em; text-transform: uppercase; }
  .zc-widget.zc-is-live .zc-live { display: inline-flex; }
  .zc-live i { width: 6px; height: 6px; border-radius: 50%; background: var(--zc-done); animation: zc-breathe 2.4s var(--zc-ease) infinite; }
  @keyframes zc-breathe { 0% { box-shadow: 0 0 0 0 rgba(47,138,91,.45); } 100% { box-shadow: 0 0 0 7px rgba(47,138,91,0); } }
  body.zc-pinmode *:not(.zc-ui):not(.zc-ui *) { cursor: crosshair !important; }

  /* ---- numbered marks: ringed so they read on any background ---- */
  .zc-mark { position: absolute; z-index: 9998; width: 20px; height: 20px; border-radius: 50%; border: 0; cursor: pointer;
    background: var(--zc-plain); color: #fff; font: 700 10.5px/20px var(--zc-sans); font-variant-numeric: tabular-nums;
    text-align: center; padding: 0; box-shadow: 0 0 0 2px #fff, 0 2px 6px rgba(40,30,15,.28);
    transition: transform .18s var(--zc-pop), filter .15s; animation: zc-mark-in .28s var(--zc-pop); }
  .zc-mark:hover { filter: brightness(1.08); transform: scale(1.12); }
  /* text marks are the main path: small superscript-style tags that clear the next word */
  .zc-mark:not(.zc-pinm) { width: 17px; height: 17px; line-height: 17px; font-size: 9.5px; margin: -4px 0 0 1px; }
  .zc-mark.zc-pinm { width: 22px; height: 22px; line-height: 22px; font-size: 11px; border-radius: 50% 50% 50% 3px; transform: rotate(-45deg); animation: none; }
  .zc-mark.zc-pinm:hover { transform: rotate(-45deg) scale(1.12); }
  .zc-mark.zc-pinm span { display: inline-block; transform: rotate(45deg); }
  .zc-mark.zc-sent { background: var(--zc-wait); animation: zc-pulse 1.8s var(--zc-ease) infinite; }
  .zc-mark.zc-answered { background: var(--zc-done); }
  .zc-mark.zc-unread { box-shadow: 0 0 0 2px #fff, 0 0 0 4px var(--zc-done), 0 2px 8px rgba(47,138,91,.35); }
  @keyframes zc-pulse { 0% { box-shadow: 0 0 0 2px #fff, 0 0 0 2px rgba(91,91,214,.45); } 100% { box-shadow: 0 0 0 2px #fff, 0 0 0 10px rgba(91,91,214,0); } }
  @keyframes zc-mark-in { from { transform: scale(.4); opacity: 0; } }
  @keyframes zc-in { from { opacity: 0; transform: translateY(4px) scale(.985); } }

  /* ---- selection bubble ---- */
  .zc-bubble { position: absolute; z-index: 9999; display: inline-flex; align-items: center; gap: 6px; border: 0; border-radius: 999px;
    background: var(--zc-ink); color: #fff; padding: 7px 13px 7px 11px; font: 500 12.5px/1 var(--zc-sans); cursor: pointer;
    box-shadow: 0 1px 2px rgba(0,0,0,.2), 0 6px 18px rgba(40,30,15,.22); transform: translateX(-50%); animation: zc-in .16s var(--zc-ease); }
  .zc-bubble:hover { background: #34312c; }

  /* ---- popovers (editor + thread) ---- */
  .zc-pop { position: absolute; z-index: 10000; width: 320px; background: var(--zc-surface); border: 1px solid var(--zc-line);
    border-radius: var(--zc-r-lg); box-shadow: var(--zc-shadow-3); padding: 14px; box-sizing: border-box; animation: zc-in .18s var(--zc-ease); }
  .zc-pop.zc-thread { width: min(450px, calc(100vw - 24px)); padding: 12px 14px 14px; }
  .zc-head { display: flex; gap: 10px; align-items: flex-start; margin: 0 28px 12px 0; padding-bottom: 12px; border-bottom: 1px solid var(--zc-line); }
  .zc-chip { flex: none; font: 600 11px/1 var(--zc-mono); padding: 4px 7px; border-radius: 999px; background: var(--zc-sunken);
    color: var(--zc-ink-2); border: 1px solid var(--zc-line); margin-top: 1px; }
  .zc-pop .zc-anchor { font-size: 12.5px; color: var(--zc-muted); margin: 0 0 10px; }
  .zc-quote { font: italic 13.5px/1.45 var(--zc-serif); color: var(--zc-ink-2); border-left: 2px solid var(--zc-plain); padding-left: 10px;
    display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
  .zc-x { position: absolute; top: 9px; right: 9px; width: 26px; height: 26px; border: 0; background: none; border-radius: 999px;
    color: var(--zc-faint); font-size: 18px; line-height: 24px; cursor: pointer; padding: 0; transition: background .15s, color .15s; }
  .zc-x:hover { background: var(--zc-sunken); color: var(--zc-ink); }
  .zc-pop textarea { width: 100%; box-sizing: border-box; min-height: 72px; border: 1px solid var(--zc-line-2); border-radius: var(--zc-r-md);
    padding: 9px 11px; font: 14px/1.5 var(--zc-sans); color: var(--zc-ink); background: var(--zc-surface); resize: vertical;
    transition: border-color .15s, box-shadow .15s; }
  .zc-pop textarea::placeholder { color: var(--zc-faint); }
  .zc-pop.zc-thread textarea { min-height: 44px; }
  .zc-pop textarea:focus { outline: none; border-color: var(--zc-accent); box-shadow: 0 0 0 3px var(--zc-accent-soft); }
  .zc-pop .zc-row { display: flex; gap: 8px; justify-content: flex-end; align-items: center; margin-top: 10px; }
  .zc-pop .zc-row button { display: inline-flex; align-items: center; border: 1px solid var(--zc-line-2); background: var(--zc-surface);
    border-radius: 999px; padding: 7px 14px; font: 500 13px/1 var(--zc-sans); cursor: pointer; color: var(--zc-ink-2);
    transition: background .15s, border-color .15s; }
  .zc-pop .zc-row button:hover { background: var(--zc-sunken); }
  .zc-pop .zc-row button.zc-primary { background: var(--zc-accent); border-color: var(--zc-accent); color: #fff; box-shadow: 0 1px 2px rgba(58,91,199,.35); }
  .zc-pop .zc-row button.zc-primary:hover { background: var(--zc-accent-hover); border-color: var(--zc-accent-hover); }
  .zc-pop .zc-row button.zc-del { margin-right: auto; border: 0; background: none; color: var(--zc-muted); padding-left: 2px; box-shadow: none; }
  .zc-pop .zc-row button.zc-del:hover { color: var(--zc-danger); background: none; }
  .zc-pop kbd { font: 500 10.5px/1 var(--zc-sans); padding: 2px 5px; border-radius: 5px; background: rgba(255,255,255,.18); margin-left: 8px; opacity: .9; }

  /* ---- thread turns ---- */
  .zc-turns { max-height: min(46vh, calc(100vh - 260px)); overflow: auto; margin: 0 0 10px; }
  .zc-turn { margin: 0 0 10px; padding: 9px 12px; border-radius: var(--zc-r-md); background: var(--zc-sunken); font-size: 14px; line-height: 1.55; color: var(--zc-ink); }
  .zc-turn.zc-agent { background: var(--zc-surface); border: 1px solid var(--zc-line); border-left: 3px solid var(--zc-done); border-radius: 4px var(--zc-r-md) var(--zc-r-md) 4px; }
  .zc-turn .zc-who { font: 600 10.5px/1 var(--zc-sans); letter-spacing: .08em; text-transform: uppercase; color: var(--zc-muted); margin: 0 0 6px; }
  .zc-turn.zc-agent .zc-who { color: var(--zc-done); }
  .zc-turn p { margin: 0 0 6px; }
  .zc-turn p:last-child { margin: 0; }
  .zc-turn ul { margin: 0 0 6px; padding-left: 18px; }
  .zc-turn li::marker { color: var(--zc-faint); }
  .zc-turn code { background: var(--zc-sunken); border: 1px solid var(--zc-line); padding: 0 4px; border-radius: 5px; font: 12.5px var(--zc-mono); }
  .zc-turn pre { background: #24221f; color: #ece7dc; padding: 10px 12px; border-radius: 8px; overflow: auto; margin: 0 0 6px;
    font: 12px/1.5 var(--zc-mono); white-space: pre; }
  .zc-turn.zc-pending { color: var(--zc-muted); font-size: 13px; border-left-color: var(--zc-wait); }
  .zc-turn.zc-pending .zc-who { color: var(--zc-wait); }
  .zc-dots i { display: inline-block; width: 5px; height: 5px; border-radius: 50%; background: var(--zc-wait); margin-right: 3px;
    animation: zc-dot 1.2s var(--zc-ease) infinite; }
  .zc-dots i:nth-child(2) { animation-delay: .15s; }
  .zc-dots i:nth-child(3) { animation-delay: .3s; margin-right: 8px; }
  @keyframes zc-dot { 0%, 80%, 100% { opacity: .25; transform: none; } 40% { opacity: 1; transform: translateY(-2px); } }

  /* ---- toast + pin hint ---- */
  .zc-toast { position: fixed; right: 18px; bottom: 74px; z-index: 10001; background: var(--zc-ink); color: #f5f2ea; padding: 10px 14px;
    border-radius: var(--zc-r-md); font-size: 13px; opacity: 0; transform: translateY(8px); transition: opacity .22s var(--zc-ease), transform .22s var(--zc-ease);
    pointer-events: none; display: flex; align-items: center; gap: 9px; box-shadow: var(--zc-shadow-3); }
  .zc-toast.zc-show { opacity: 1; transform: none; }
  .zc-toast.zc-click { pointer-events: auto; cursor: pointer; }
  .zc-toast.zc-click:hover { background: #34312c; }
  .zc-toast .zc-dot { width: 7px; height: 7px; border-radius: 50%; background: #7fd3a4; box-shadow: 0 0 0 3px rgba(127,211,164,.2); }
  .zc-toast .zc-open { font-weight: 600; color: #a7e3c1; }
  .zc-hint { position: fixed; right: 18px; bottom: 74px; z-index: 10001; background: var(--zc-ink); color: #f5f2ea; padding: 9px 14px;
    border-radius: var(--zc-r-md); font-size: 13px; display: none; box-shadow: var(--zc-shadow-3); pointer-events: none; animation: zc-in .18s var(--zc-ease); }
  body.zc-pinmode .zc-hint { display: block; }
  @media (prefers-reduced-motion: reduce) { .zc-mark, .zc-dots i, .zc-live i, .zc-pop, .zc-bubble, .zc-hint { animation: none !important; } }`;
  const ZC_ICONS = {
    pin: '<svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M8 14.5s-4.5-4.1-4.5-7.7a4.5 4.5 0 0 1 9 0c0 3.6-4.5 7.7-4.5 7.7z"/><circle cx="8" cy="6.7" r="1.6"/></svg>',
    comment: '<svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M2.5 4.5a2 2 0 0 1 2-2h7a2 2 0 0 1 2 2v4.5a2 2 0 0 1-2 2H7l-3 2.5v-2.5h0a1.5 1.5 0 0 1-1.5-1.5z"/></svg>',
    copy: '<svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="5.5" y="5.5" width="8" height="8" rx="1.8"/><path d="M10.5 3.2A1.8 1.8 0 0 0 8.7 2H4a2 2 0 0 0-2 2v4.7a1.8 1.8 0 0 0 1.2 1.8"/></svg>',
  };
  const styleEl = document.createElement('style');
  styleEl.textContent = css;
  document.head.appendChild(styleEl);

  function init() {
    const KEY = 'zc:' + location.pathname;
    let items = [];
    try { items = JSON.parse(localStorage.getItem(KEY)) || []; } catch (e) { /* fresh */ }
    let nextN = items.reduce((m, i) => Math.max(m, i.n), 0) + 1;
    const save = () => localStorage.setItem(KEY, JSON.stringify(items));

    const hlOk = typeof Highlight !== 'undefined' && CSS.highlights;
    const hls = hlOk ? { plain: new Highlight(), wait: new Highlight(), done: new Highlight() } : null;
    if (hls) { CSS.highlights.set('zc', hls.plain); CSS.highlights.set('zc-wait', hls.wait); CSS.highlights.set('zc-done', hls.done); }
    const stateOf = (it) => (it.state === 'queued' || it.state === 'sent') ? 'wait' : it.state === 'answered' ? 'done' : 'plain';

    // --- UI scaffolding -------------------------------------------------
    const widget = document.createElement('div');
    widget.className = 'zc-ui zc-widget';
    widget.innerHTML = '<span class="zc-live" title="A Claude session is answering comments on this page"><i></i>live</span>' +
      '<span id="zc-count">0 comments</span>' +
      '<button id="zc-pin" aria-label="Drop a pin" title="Drop a pin on a diagram">' + ZC_ICONS.pin + '</button>' +
      '<button id="zc-copy" title="Copy all comments for the agent, then clear them">' + ZC_ICONS.copy + 'Copy all</button>';
    document.body.appendChild(widget);
    const countEl = widget.querySelector('#zc-count');
    const pinBtn = widget.querySelector('#zc-pin');
    const copyBtn = widget.querySelector('#zc-copy');

    const marks = document.createElement('div');
    marks.className = 'zc-ui';
    document.body.appendChild(marks);

    const hint = document.createElement('div');
    hint.className = 'zc-ui zc-hint';
    hint.textContent = 'Click anywhere to pin · Esc to cancel';
    document.body.appendChild(hint);

    const toast = document.createElement('div');
    toast.className = 'zc-ui zc-toast';
    document.body.appendChild(toast);
    let toastT, toastClick = null;
    toast.addEventListener('click', () => { if (toastClick) toastClick(); toast.classList.remove('zc-show'); });
    function showToast(msg, onClick) {
      toast.textContent = msg;
      if (onClick) toast.innerHTML = '<span class="zc-dot"></span><span></span><span class="zc-open">Open →</span>';
      if (onClick) toast.children[1].textContent = msg;
      toastClick = onClick || null;
      toast.classList.toggle('zc-click', !!onClick);
      toast.classList.add('zc-show');
      clearTimeout(toastT);
      toastT = setTimeout(() => toast.classList.remove('zc-show'), onClick ? 6000 : 2600);
    }

    let bubble = null, pop = null, pending = null, openN = null;
    const markPos = {};
    function killFloaters() {
      if (bubble) { bubble.remove(); bubble = null; }
      if (pop) { pop.remove(); pop = null; }
      openN = null;
    }

    // --- live session state ------------------------------------------------
    const LIVE_MS = 8000;
    let lastSeen = 0;
    const isLive = () => Date.now() - lastSeen < LIVE_MS;
    const updateLive = () => widget.classList.toggle('zc-is-live', isLive());
    setInterval(updateLive, 2000);

    function esc(t) {
      return t.replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
    }
    function mdInline(t) {
      return esc(t).replace(/`([^`]+)`/g, '<code>$1</code>').replace(/\*\*([^*]+)\*\*/g, '<b>$1</b>');
    }
    function md(src) {
      const out = [];
      String(src).replace(/\r/g, '').split('```').forEach((chunk, i) => {
        if (i % 2) { out.push('<pre>' + esc(chunk.replace(/^\w*\n/, '')) + '</pre>'); return; }
        for (const para of chunk.split(/\n{2,}/)) {
          const t = para.trim();
          if (!t) continue;
          const lines = t.split('\n');
          if (lines.every((l) => /^\s*[-*] /.test(l))) {
            out.push('<ul>' + lines.map((l) => '<li>' + mdInline(l.replace(/^\s*[-*] /, '')) + '</li>').join('') + '</ul>');
          } else {
            out.push('<p>' + lines.map(mdInline).join('<br>') + '</p>');
          }
        }
      });
      return out.join('');
    }

    // --- anchoring helpers ----------------------------------------------
    function sectionOf(node) {
      let el = node.nodeType === 1 ? node : node.parentElement;
      if (!el) return null;
      const det = el.closest('details');
      if (det) {
        const s = det.querySelector('summary');
        if (s) return s.textContent.trim().replace(/\s+/g, ' ');
      }
      let best = null;
      for (const h of document.querySelectorAll('h1, h2, h3')) {
        if (h.compareDocumentPosition(el) & Node.DOCUMENT_POSITION_FOLLOWING) best = h;
      }
      return best ? best.textContent.trim().replace(/\s+/g, ' ') : null;
    }

    function walkText() {
      const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, {
        acceptNode: (n) => n.parentElement && n.parentElement.closest('.zc-ui')
          ? NodeFilter.FILTER_REJECT : NodeFilter.FILTER_ACCEPT,
      });
      const nodes = [];
      let text = '';
      while (walker.nextNode()) {
        nodes.push({ node: walker.currentNode, start: text.length });
        text += walker.currentNode.data;
      }
      return { nodes, text };
    }

    function findRange(it) {
      const { nodes, text } = walkText();
      let idx = -1;
      if (it.prefix || it.suffix) {
        const i = text.indexOf(it.prefix + it.quote + it.suffix);
        if (i >= 0) idx = i + it.prefix.length;
      }
      if (idx < 0) idx = text.indexOf(it.quote);
      if (idx < 0) return null;
      const end = idx + it.quote.length;
      const range = document.createRange();
      let started = false;
      for (const { node, start } of nodes) {
        const len = node.data.length;
        if (!started && idx >= start && idx <= start + len) {
          range.setStart(node, idx - start);
          started = true;
        }
        if (started && end >= start && end <= start + len) {
          range.setEnd(node, end - start);
          return range;
        }
      }
      return null;
    }

    // --- rendering --------------------------------------------------------
    function renderAll() {
      marks.textContent = '';
      if (hls) Object.values(hls).forEach((h) => h.clear());
      for (const it of items) {
        let x, y;
        if (it.type === 'text') {
          const r = findRange(it);
          if (!r) continue;
          if (hls) hls[stateOf(it)].add(r);
          const rects = r.getClientRects();
          const last = rects[rects.length - 1];
          if (!last) continue;
          x = last.right + window.scrollX + 1;
          y = last.top + window.scrollY - 9;
        } else {
          x = it.x - 10; y = it.y - 24; // put the teardrop tip on the click point
        }
        const m = document.createElement('button');
        const st = stateOf(it);
        m.className = 'zc-ui zc-mark' + (it.type === 'pin' ? ' zc-pinm' : '') +
          (st === 'wait' ? ' zc-sent' : st === 'done' ? ' zc-answered' : '') + (it.unread ? ' zc-unread' : '');
        markPos[it.n] = { x, y };
        m.innerHTML = '<span>' + it.n + '</span>';
        m.style.left = x + 'px';
        m.style.top = y + 'px';
        m.dataset.n = it.n;
        m.addEventListener('click', (e) => { e.stopPropagation(); viewItem(it, x, y); });
        marks.appendChild(m);
      }
      countEl.textContent = items.length === 1 ? '1 comment' : items.length + ' comments';
      copyBtn.disabled = items.length === 0;
    }

    const rerender = (() => {
      let raf = 0;
      return () => { cancelAnimationFrame(raf); raf = requestAnimationFrame(renderAll); };
    })();
    window.addEventListener('resize', rerender);
    new MutationObserver((muts) => {
      if (muts.some((m) => !(m.target.nodeType === 1 && m.target.closest && m.target.closest('.zc-ui')))) rerender();
    }).observe(document.body, { childList: true, subtree: true });

    // --- popovers ---------------------------------------------------------
    function openEditor(x, y, anchorLabel) {
      killFloaters();
      pop = document.createElement('div');
      pop.className = 'zc-ui zc-pop';
      pop.innerHTML = '<p class="zc-quote" style="margin:0 0 8px"></p><textarea placeholder="Your comment…"></textarea>' +
        '<div class="zc-row"><button class="zc-cancel">Cancel</button><button class="zc-primary zc-save">' +
        (isLive() ? 'Ask Claude' : 'Save') + '<kbd>⌘↵</kbd></button></div>';
      pop.querySelector('.zc-quote').textContent = anchorLabel;
      pop.querySelector('textarea').addEventListener('keydown', (e) => {
        if (e.key === 'Enter' && (e.metaKey || e.ctrlKey)) pop.querySelector('.zc-save').click();
      });
      place(pop, x, y);
      const ta = pop.querySelector('textarea');
      ta.focus();
      pop.querySelector('.zc-cancel').addEventListener('click', () => { pending = null; killFloaters(); });
      pop.querySelector('.zc-save').addEventListener('click', () => {
        const body = ta.value.trim();
        if (!body || !pending) return;
        const it = Object.assign({ n: nextN++, comment: body, created: new Date().toISOString() }, pending);
        if (isLive()) { it.thread = []; it.state = 'queued'; }
        items.push(it);
        pending = null;
        save();
        killFloaters();
        renderAll();
        if (it.state) showToast('Sent C' + it.n + ' to Claude');
      });
    }

    function clip(t, max) {
      t = String(t).trim().replace(/\s+/g, ' ');
      if (t.length <= max) return t;
      const cut = t.slice(0, max);
      return cut.slice(0, cut.lastIndexOf(' ') > max * 0.6 ? cut.lastIndexOf(' ') : max) + '…';
    }
    const quoteOf = (it) => '“' + clip(it.type === 'text' ? it.quote : it.near, 200) + '”' + (it.extra ? ' · ' + it.extra : '');

    // Fill the open thread's turns in place, so a session update never wipes
    // a half-typed follow-up or moves the popover.
    function paintTurns(it) {
      if (!pop || openN !== it.n) return;
      const el = pop.querySelector('.zc-turns');
      const turns = [{ role: 'user', text: it.comment }].concat(it.thread || []);
      const wait = it.state === 'queued' ? 'Queued…' : it.state === 'sent' ? 'Thinking…' : '';
      el.innerHTML = turns.map((t) => '<div class="zc-turn' + (t.role === 'agent' ? ' zc-agent' : '') + '"><p class="zc-who">' +
          (t.role === 'agent' ? 'Claude' : 'You') + '</p>' + md(t.text) + '</div>').join('') +
        (wait ? '<div class="zc-turn zc-agent zc-pending"><p class="zc-who">Claude</p><span class="zc-dots"><i></i><i></i><i></i></span>' +
          wait + '</div>' : '');
      el.scrollTop = el.scrollHeight;
      if (it.unread) { it.unread = false; save(); renderAll(); }
    }

    function viewItem(it, x, y) {
      killFloaters();
      openN = it.n;
      const live = isLive();
      pop = document.createElement('div');
      pop.className = 'zc-ui zc-pop zc-thread';
      pop.innerHTML = '<button class="zc-x" title="Close">×</button>' +
        '<div class="zc-head"><span class="zc-chip">C' + it.n + '</span><span class="zc-quote"></span></div>' +
        '<div class="zc-turns"></div>' +
        (live && it.thread ? '<textarea placeholder="Follow up…"></textarea>' : '') +
        '<div class="zc-row"><button class="zc-del">Delete</button>' +
        (live && !it.thread ? '<button class="zc-primary zc-ask">Ask Claude</button>' : '') +
        (live && it.thread ? '<button class="zc-primary zc-send">Send<kbd>⌘↵</kbd></button>' : '') + '</div>';
      pop.querySelector('.zc-quote').textContent = quoteOf(it);
      place(pop, x, y);
      paintTurns(it);
      place(pop, x, y); // re-place now that the turns give it its real height
      pop.querySelector('.zc-x').addEventListener('click', killFloaters);
      pop.querySelector('.zc-del').addEventListener('click', () => {
        items = items.filter((o) => o !== it);
        save();
        killFloaters();
        renderAll();
      });
      const ask = pop.querySelector('.zc-ask');
      if (ask) ask.addEventListener('click', () => { it.thread = []; it.state = 'queued'; save(); renderAll(); viewItem(it, x, y); });
      const send = pop.querySelector('.zc-send');
      if (send) {
        const ta = pop.querySelector('textarea');
        const go = () => {
          const body = ta.value.trim();
          if (!body) return;
          it.thread.push({ role: 'user', text: body, at: new Date().toISOString() });
          it.state = 'queued';
          ta.value = '';
          save();
          renderAll();
          paintTurns(it);
        };
        send.addEventListener('click', go);
        ta.addEventListener('keydown', (e) => { if (e.key === 'Enter' && (e.metaKey || e.ctrlKey)) go(); });
        ta.focus();
      }
    }

    function openItem(n) {
      const it = items.find((o) => o.n === n);
      const p = markPos[n];
      if (!it || !p) return;
      const vy = p.y - window.scrollY;
      if (vy < 60 || vy > window.innerHeight - 200) window.scrollTo({ top: Math.max(0, p.y - 160) });
      viewItem(it, p.x, p.y);
    }

    // (x, y) is the mark's top-left in page coords. Opens below; flips above
    // when it would run under the widget or off the viewport.
    function place(node, x, y) {
      document.body.appendChild(node);
      const w = node.offsetWidth || 300, h = node.offsetHeight;
      const maxX = window.scrollX + document.documentElement.clientWidth - w - 12;
      node.style.left = Math.max(window.scrollX + 8, Math.min(x, maxX)) + 'px';
      let top = y + 26;
      if (top - window.scrollY + h > window.innerHeight - 76) {
        top = Math.max(window.scrollY + 8, y - h - 8);
      }
      node.style.top = top + 'px';
    }

    // --- text selection flow ----------------------------------------------
    document.addEventListener('mouseup', (e) => {
      if (e.target.closest('.zc-ui')) return;
      if (document.body.classList.contains('zc-pinmode')) return;
      setTimeout(() => {
        const sel = getSelection();
        if (!sel.rangeCount || sel.isCollapsed) { if (bubble) { bubble.remove(); bubble = null; } return; }
        const raw = sel.toString();
        if (raw.trim().length < 3) return;
        const r = sel.getRangeAt(0);
        const pre = document.createRange();
        pre.setStart(document.body, 0);
        pre.setEnd(r.startContainer, r.startOffset);
        const post = document.createRange();
        post.selectNodeContents(document.body);
        post.setStart(r.endContainer, r.endOffset);
        pending = {
          type: 'text',
          // Range.toString() (raw source text), NOT sel.toString() (rendered,
          // whitespace-collapsed): findRange searches raw Text.data, so a
          // rendered quote fails to re-locate across source line wraps.
          quote: r.toString(),
          prefix: pre.toString().slice(-30),
          suffix: post.toString().slice(0, 30),
          section: sectionOf(r.startContainer),
        };
        const rect = r.getBoundingClientRect();
        killFloaters();
        bubble = document.createElement('button');
        bubble.className = 'zc-ui zc-bubble';
        bubble.innerHTML = ZC_ICONS.comment + 'Comment';
        bubble.style.left = (rect.left + window.scrollX + rect.width / 2) + 'px';
        bubble.style.top = (rect.top < 40 ? rect.bottom + window.scrollY + 6 : rect.top + window.scrollY - 34) + 'px';
        const anchorLabel = '“' + clip(raw, 160) + '”';
        const bx = rect.left + window.scrollX, by = rect.bottom + window.scrollY - 20;
        bubble.addEventListener('click', () => openEditor(bx, by, anchorLabel));
        document.body.appendChild(bubble);
      }, 0);
    });

    // --- pin flow -----------------------------------------------------------
    pinBtn.addEventListener('click', () => {
      document.body.classList.toggle('zc-pinmode');
      pinBtn.classList.toggle('zc-on');
      killFloaters();
    });
    document.addEventListener('click', (e) => {
      if (!document.body.classList.contains('zc-pinmode')) return;
      if (e.target.closest('.zc-ui')) return;
      e.preventDefault();
      e.stopPropagation();
      document.body.classList.remove('zc-pinmode');
      pinBtn.classList.remove('zc-on');
      const near = (e.target instanceof SVGSVGElement)
        ? '(diagram canvas)'
        : (e.target.textContent || '').trim().replace(/\s+/g, ' ').slice(0, 80);
      pending = {
        type: 'pin',
        x: e.pageX,
        y: e.pageY,
        near: near || e.target.tagName.toLowerCase(),
        section: sectionOf(e.target),
        extra: (typeof window.zcExtraContext === 'function') ? window.zcExtraContext(e.target) : null,
      };
      openEditor(e.pageX - 10, e.pageY - 24, '“' + clip(pending.near, 160) + '”' + (pending.extra ? ' · ' + pending.extra : ''));
    }, true);

    // --- payload + copy & clear ----------------------------------------------
    function anchorText(it) {
      if (it.type === 'text') return 'Text: “' + it.quote.trim().replace(/\s+/g, ' ').slice(0, 160) + '”';
      let s = 'Pin near: “' + it.near + '”';
      if (it.extra) s += ' (' + it.extra + ')';
      return s;
    }

    function buildPayload() {
      const lines = ['Explainer feedback — ' + document.title, 'Page: ' + location.pathname, ''];
      for (const it of items) {
        lines.push('[C' + it.n + '] ' + anchorText(it));
        if (it.section) lines.push('     Section: ' + it.section);
        lines.push('     Comment: ' + it.comment);
        for (const t of it.thread || []) {
          lines.push('     ' + (t.role === 'agent' ? 'Claude' : 'Follow-up') + ': ' + t.text.replace(/\s+/g, ' '));
        }
        lines.push('');
      }
      return lines.join('\n');
    }

    function copyText(t) {
      const legacy = () => {
        const ta = document.createElement('textarea');
        ta.value = t;
        ta.style.position = 'fixed';
        ta.style.opacity = '0';
        document.body.appendChild(ta);
        ta.select();
        let ok = false;
        try { ok = document.execCommand('copy'); } catch (e) { /* fall through */ }
        ta.remove();
        return ok;
      };
      if (navigator.clipboard && navigator.clipboard.writeText) {
        return navigator.clipboard.writeText(t).then(() => true, legacy);
      }
      return Promise.resolve(legacy());
    }

    function showManualCopy(t) {
      killFloaters();
      pop = document.createElement('div');
      pop.className = 'zc-ui zc-pop';
      pop.style.position = 'fixed';
      pop.style.left = '50%';
      pop.style.top = '25%';
      pop.style.transform = 'translateX(-50%)';
      pop.style.width = '440px';
      pop.innerHTML = '<p class="zc-anchor">Automatic copy failed. The payload is selected below — press Ctrl/⌘+C, then clear.</p>' +
        '<textarea style="min-height:150px"></textarea>' +
        '<div class="zc-row"><button class="zc-cancel">Keep comments</button><button class="zc-primary zc-clear">Copied — clear</button></div>';
      pop.querySelector('textarea').value = t;
      document.body.appendChild(pop);
      const ta = pop.querySelector('textarea');
      ta.focus();
      ta.select();
      pop.querySelector('.zc-cancel').addEventListener('click', killFloaters);
      pop.querySelector('.zc-clear').addEventListener('click', () => {
        items = [];
        save();
        renderAll();
        killFloaters();
        showToast('Cleared.');
      });
    }

    copyBtn.addEventListener('click', async () => {
      if (!items.length) return;
      const n = items.length;
      const payload = buildPayload();
      const ok = await copyText(payload);
      if (!ok) { showManualCopy(payload); return; }
      items = [];
      save();
      renderAll();
      killFloaters();
      showToast('Copied ' + n + ' comment' + (n === 1 ? '' : 's') + ' — paste to the agent. Cleared.');
    });

    document.addEventListener('keydown', (e) => {
      if (e.key !== 'Escape') return;
      pending = null;
      killFloaters();
      document.body.classList.remove('zc-pinmode');
      pinBtn.classList.remove('zc-on');
    });

    window.zergComments = { list: () => items.slice(), payload: buildPayload };

    // Session side. drain() doubles as the heartbeat that turns live mode on.
    window.zcLive = {
      drain() {
        lastSeen = Date.now();
        updateLive();
        const out = [];
        for (const it of items) {
          if (it.state !== 'queued') continue;
          const last = it.thread.filter((t) => t.role === 'user').pop();
          out.push({ n: it.n, anchor: anchorText(it), section: it.section || null,
            text: last ? last.text : it.comment, followUp: !!last });
          it.state = 'sent';
        }
        if (out.length) {
          save();
          renderAll();
          const open = items.find((o) => o.n === openN);
          if (open && out.some((o) => o.n === openN)) paintTurns(open);
        }
        return out;
      },
      answer(n, text) {
        const it = items.find((o) => o.n === n);
        if (!it) return false;
        (it.thread = it.thread || []).push({ role: 'agent', text: String(text), at: new Date().toISOString() });
        it.state = 'answered';
        it.unread = openN !== n;
        save();
        renderAll();
        if (openN === n) paintTurns(it);
        else showToast('Claude answered C' + n, () => openItem(n));
        return true;
      },
      status: () => ({ live: isLive(), pending: items.filter((o) => o.state === 'queued' || o.state === 'sent').map((o) => o.n) }),
    };
    renderAll();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
