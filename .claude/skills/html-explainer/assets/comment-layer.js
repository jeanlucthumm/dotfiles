/* ============================================================
  zc comment layer — external-script build of assets/comment-layer.html.

  Local explainers (viewed via file://) load this with ONE tag instead of
  inlining the whole layer:

    <script src="../../../.claude/skills/html-explainer/assets/comment-layer.js"></script>

  (relative path from ~/memory/projects/explainers/<file>.html; adjust if
  the explainer lives elsewhere). The styles are injected by this script,
  so no separate <style> block is needed.

  If an explainer must be SHARED (uploaded, emailed, made public), this
  reference breaks silently — inline assets/comment-layer.html instead,
  or paste this file's contents into a <script> tag at share time.

  Behavior is identical to comment-layer.html:
    - select text -> "Comment" bubble -> anchored note (yellow highlight)
    - Pin mode -> click anywhere (e.g. SVG diagrams) -> anchored note
    - floating widget -> "Copy & clear" builds an agent-readable payload
    - optional page hook: window.zcExtraContext = (clickTarget) => string|null
    - test API: window.zergComments = { list, payload }
============================================================= */
(function () {
  'use strict';

  /* --- inject styles (kept in sync with comment-layer.html) ----------- */
  const css = `
  ::highlight(zc) { background: #ffe58a; }
  .zc-ui { font: 13px/1.45 -apple-system, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; }
  .zc-widget { position: fixed; right: 18px; bottom: 18px; z-index: 9999; display: flex; gap: 8px; align-items: center;
    background: #fff; border: 1px solid #d8dde6; border-radius: 999px; padding: 8px 12px; box-shadow: 0 4px 16px rgba(15,23,42,.14); }
  .zc-widget button { border: 1px solid #d8dde6; background: #fff; border-radius: 999px; padding: 5px 12px; font: inherit; cursor: pointer; }
  .zc-widget button:disabled { opacity: .4; cursor: default; }
  .zc-widget button.zc-on { background: #2563eb; border-color: #2563eb; color: #fff; }
  #zc-copy { background: #16803c; border-color: #16803c; color: #fff; }
  #zc-copy:disabled { background: #fff; color: inherit; border-color: #d8dde6; }
  body.zc-pinmode, body.zc-pinmode * { cursor: crosshair !important; }
  .zc-mark { position: absolute; z-index: 9998; width: 20px; height: 20px; border-radius: 50%; border: 0; cursor: pointer;
    background: #b45309; color: #fff; font-size: 11px; font-weight: 700; line-height: 20px; text-align: center; padding: 0;
    box-shadow: 0 1px 4px rgba(15,23,42,.3); }
  .zc-mark.zc-pinm { background: #b42318; border-radius: 50% 50% 50% 0; transform: rotate(-45deg); }
  .zc-mark.zc-pinm span { display: inline-block; transform: rotate(45deg); }
  .zc-bubble { position: absolute; z-index: 9999; border: 0; border-radius: 999px; background: #1a2233; color: #fff;
    padding: 6px 13px; font-size: 12.5px; cursor: pointer; box-shadow: 0 2px 10px rgba(15,23,42,.3); }
  .zc-pop { position: absolute; z-index: 10000; width: 300px; background: #fff; border: 1px solid #d8dde6; border-radius: 10px;
    box-shadow: 0 8px 28px rgba(15,23,42,.2); padding: 12px; }
  .zc-pop .zc-anchor { font-size: 11.5px; color: #5b6472; margin: 0 0 8px; max-height: 54px; overflow: hidden; }
  .zc-pop textarea { width: 100%; box-sizing: border-box; min-height: 64px; border: 1px solid #d8dde6; border-radius: 8px;
    padding: 8px; font: inherit; resize: vertical; }
  .zc-pop .zc-row { display: flex; gap: 8px; justify-content: flex-end; margin-top: 8px; }
  .zc-pop .zc-row button { border: 1px solid #d8dde6; background: #fff; border-radius: 8px; padding: 6px 12px; font: inherit; cursor: pointer; }
  .zc-pop .zc-row button.zc-primary { background: #2563eb; border-color: #2563eb; color: #fff; }
  .zc-pop .zc-row button.zc-danger { color: #b42318; border-color: #e8a49c; }
  .zc-pop .zc-body { white-space: pre-wrap; margin: 0 0 4px; }
  .zc-toast { position: fixed; left: 50%; bottom: 74px; transform: translateX(-50%); z-index: 10001; background: #1a2233;
    color: #fff; padding: 9px 16px; border-radius: 8px; font-size: 13px; opacity: 0; transition: opacity .25s; pointer-events: none; }
  .zc-toast.zc-show { opacity: 1; }`;
  const styleEl = document.createElement('style');
  styleEl.textContent = css;
  document.head.appendChild(styleEl);

  function init() {
    const KEY = 'zc:' + location.pathname;
    let items = [];
    try { items = JSON.parse(localStorage.getItem(KEY)) || []; } catch (e) { /* fresh */ }
    let nextN = items.reduce((m, i) => Math.max(m, i.n), 0) + 1;
    const save = () => localStorage.setItem(KEY, JSON.stringify(items));

    const hl = (typeof Highlight !== 'undefined' && CSS.highlights) ? new Highlight() : null;
    if (hl) CSS.highlights.set('zc', hl);

    // --- UI scaffolding -------------------------------------------------
    const widget = document.createElement('div');
    widget.className = 'zc-ui zc-widget';
    widget.innerHTML = '<span id="zc-count">💬 0</span>' +
      '<button id="zc-pin" title="Click, then click anywhere to drop a pin">📍 Pin</button>' +
      '<button id="zc-copy" title="Copy all comments for the agent, then clear them">Copy &amp; clear</button>';
    document.body.appendChild(widget);
    const countEl = widget.querySelector('#zc-count');
    const pinBtn = widget.querySelector('#zc-pin');
    const copyBtn = widget.querySelector('#zc-copy');

    const marks = document.createElement('div');
    marks.className = 'zc-ui';
    document.body.appendChild(marks);

    const toast = document.createElement('div');
    toast.className = 'zc-ui zc-toast';
    document.body.appendChild(toast);
    let toastT;
    function showToast(msg) {
      toast.textContent = msg;
      toast.classList.add('zc-show');
      clearTimeout(toastT);
      toastT = setTimeout(() => toast.classList.remove('zc-show'), 2600);
    }

    let bubble = null, pop = null, pending = null;
    function killFloaters() {
      if (bubble) { bubble.remove(); bubble = null; }
      if (pop) { pop.remove(); pop = null; }
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
      if (hl) hl.clear();
      for (const it of items) {
        let x, y;
        if (it.type === 'text') {
          const r = findRange(it);
          if (!r) continue;
          if (hl) hl.add(r);
          const rects = r.getClientRects();
          const last = rects[rects.length - 1];
          if (!last) continue;
          x = last.right + window.scrollX + 2;
          y = last.top + window.scrollY - 10;
        } else {
          x = it.x; y = it.y;
        }
        const m = document.createElement('button');
        m.className = 'zc-ui zc-mark' + (it.type === 'pin' ? ' zc-pinm' : '');
        m.innerHTML = '<span>' + it.n + '</span>';
        m.style.left = x + 'px';
        m.style.top = y + 'px';
        m.dataset.n = it.n;
        m.addEventListener('click', (e) => { e.stopPropagation(); viewItem(it, x, y); });
        marks.appendChild(m);
      }
      countEl.textContent = '💬 ' + items.length;
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
      pop.innerHTML = '<p class="zc-anchor"></p><textarea placeholder="Your comment…"></textarea>' +
        '<div class="zc-row"><button class="zc-cancel">Cancel</button><button class="zc-primary zc-save">Save</button></div>';
      pop.querySelector('.zc-anchor').textContent = anchorLabel;
      place(pop, x, y);
      const ta = pop.querySelector('textarea');
      ta.focus();
      pop.querySelector('.zc-cancel').addEventListener('click', () => { pending = null; killFloaters(); });
      pop.querySelector('.zc-save').addEventListener('click', () => {
        const body = ta.value.trim();
        if (!body || !pending) return;
        items.push(Object.assign({ n: nextN++, comment: body, created: new Date().toISOString() }, pending));
        pending = null;
        save();
        killFloaters();
        renderAll();
      });
    }

    function viewItem(it, x, y) {
      killFloaters();
      pop = document.createElement('div');
      pop.className = 'zc-ui zc-pop';
      pop.innerHTML = '<p class="zc-anchor"></p><p class="zc-body"></p>' +
        '<div class="zc-row"><button class="zc-danger zc-del">Delete</button><button class="zc-cancel">Close</button></div>';
      pop.querySelector('.zc-anchor').textContent = '[C' + it.n + '] ' + anchorText(it);
      pop.querySelector('.zc-body').textContent = it.comment;
      place(pop, x, y);
      pop.querySelector('.zc-cancel').addEventListener('click', killFloaters);
      pop.querySelector('.zc-del').addEventListener('click', () => {
        items = items.filter((o) => o !== it);
        save();
        killFloaters();
        renderAll();
      });
    }

    function place(node, x, y) {
      document.body.appendChild(node);
      const w = node.offsetWidth || 300;
      const maxX = window.scrollX + document.documentElement.clientWidth - w - 12;
      node.style.left = Math.max(8, Math.min(x, maxX)) + 'px';
      node.style.top = (y + 22) + 'px';
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
        bubble.textContent = '💬 Comment';
        bubble.style.left = (rect.left + window.scrollX + rect.width / 2 - 44) + 'px';
        bubble.style.top = (rect.bottom + window.scrollY + 6) + 'px';
        const anchorLabel = 'On: “' + raw.trim().replace(/\s+/g, ' ').slice(0, 120) + '”';
        const bx = rect.left + window.scrollX, by = rect.bottom + window.scrollY;
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
      openEditor(e.pageX, e.pageY, 'Pin near: “' + pending.near + '”' + (pending.extra ? ' — ' + pending.extra : ''));
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
        lines.push('     Comment: ' + it.comment, '');
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

    document.addEventListener('keydown', (e) => { if (e.key === 'Escape') { pending = null; killFloaters(); } });

    window.zergComments = { list: () => items.slice(), payload: buildPayload };
    renderAll();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
