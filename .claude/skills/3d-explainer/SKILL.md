---
name: 3d-explainer
description: Build an orbit-able 3D HTML explainer of a system — services as buildings on layered platforms, animated data flows between them. Use when the user asks for a 3D explainer/visualization of an architecture or topology, or when an html-explainer subject is fundamentally spatial (layers, cells, fleets, request paths across many services). For flat/document-style subjects use html-explainer instead.
---

# 3D explainers

The 3D variant of `html-explainer` (read that skill first — its rules apply here:
diagrams-first, interactive, light theme, comment layer, real-browser verification,
save to `~/memory/projects/explainers/`, output the `file://` URL + pbcopy the path).
One sanctioned deviation: **not single-file**. Three.js is too big to inline sanely, so
the library lives next to the explainers and is referenced by *relative* path.

Why 3D at all: height is a free semantic axis. Put clients on the top platform and the
execution fleet on the floor, and "a request descends the stack" stops being a metaphor.
If the subject has no spatial structure worth showing, don't use this skill.

## Packaging (the solved problem — don't re-derive)

- `assets/three-r147.min.js` + `assets/OrbitControls-r147.js` are Three.js **r147** —
  the last release with classic UMD builds (global `THREE`, no bundler/importmap/CDN).
  Copy them into `~/memory/projects/explainers/lib/` if not already there; all 3D
  explainers share that one lib dir.
- Final page = `shell.html` (head/CSS/UI chrome) + two `<script src="lib/…">` tags +
  inline `<script>` data + inline `<script>` engine + the html-explainer comment layer
  + `</body></html>`. Concatenate with `cat`; keep the pieces in the job tmp dir while
  iterating so you never hand-edit the assembled file.

## The engine (assets/engine.js)

Data-driven: it renders whatever `window.EXPLAINER_DATA` describes. You should rarely
touch the engine — spend your effort on the data. Fork it freely per explainer if the
subject demands something new (it's a starting point, not a framework).

```js
window.EXPLAINER_DATA = {
  edgeStyles: { grpc: {color:'#dc2626', label:'gRPC'}, ... },   // legend + edge colors
  zones:  [{ id, label, color, y, x, z, w, d }],                // floating platforms
  nodes:  [{ id, zone, kind, x, z, w, h, d, color, label, sub,  // kind: box|db|client|fleet
             kicker, body, paths: ['file.ts:123'],              // click-panel content
             antenna: true }],                                  // pulsing beacon = token minter
  edges:  [{ id, from, to, kind, particles, arc }],             // curves + ambient traffic
  flows:  [{ id, label, color, steps: [{ edge|edges, dir, nodes, caption }] }],
  ghosts: [{ x, y, z, w, h, d, color, label }],                 // translucent context props
}
```

What you get for free: orbit/pan/zoom (OrbitControls), HTML overlay labels (crisp text,
clickable), click-to-inspect panel, per-protocol ambient particles with a legend, the
flow player (step captions, camera fly-to, dim-everything-else, ←/→/Esc), auto-orbit
toggle, `zcExtraContext` reporting the active flow/step to comment pins, and deep links:
`#node=<id>`, `#flow=<id>&step=<n>`, `&debug` (per-frame camera/opacity telemetry to
console).

## Authoring

- **Research before geometry.** Every node body and `paths` entry must be verifiably
  real (fan out Explore agents / check memory). A gorgeous scene of a wrong architecture
  is worse than a whiteboard photo.
- **Flows are the star.** Buildings orient; the animated scenarios teach. Write captions
  as narration of one concrete request, one hop per step, with the auth/token detail on
  the hop where it happens. 3–6 flows, ≤10 steps each.
- Keep it legible: ~15–25 nodes. Collapse internals into one building and put the detail
  in its click panel. Use a `fleet` node for "many identical things" with one `hotIndex`
  cube for "yours". Stagger node `z` within a platform so overlay labels don't collide.

## Verification (headless, no MCP needed)

Headless Chrome needs software WebGL; deep links substitute for clicking:

```bash
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
"$CHROME" --headless=new --enable-unsafe-swiftshader --use-angle=swiftshader \
  --enable-logging=stderr --window-size=1680,1050 --screenshot=out.png \
  --virtual-time-budget=30000 "file://$PAGE#flow=<id>&step=<n>" 2>&1 | grep CONSOLE
```

Screenshot the default view, at least two flow steps, and one `#node=` panel — and
actually look at them (framing, label collisions, dimming, caption readability).
Virtual-time RAF only advances a few seconds, so mid-tween captures are normal; use
`&debug` telemetry to confirm where the camera settles. Known trap already fixed in the
engine (keep the fix if you fork): the first RAF timestamp can predate the
`performance.now()` captured during script eval — clamp frame `dt` at zero or a negative
easing factor flings the camera out of the scene.
