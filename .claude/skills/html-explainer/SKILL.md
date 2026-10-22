---
name: html-explainer
description: Use when building an HTML explainer — an interactive, single-file HTML document explaining a system, design, decision, or investigation. Trigger BEFORE writing any explainer HTML, including when the user says "explainer", "HTML explainer", or asks to visualize/present findings as a shareable HTML page.
argument-hint: "[--split] [--live]"
---

# HTML explainers

Hard requirements — everything else is your call:

- Diagrams first, prose second.
- Interactive by default, not static — clicking/toggling should reveal something (details, outcomes, animation). Static boxes are the fallback, not the norm.
- Light theme, "paper & ink" look from `assets/base.css`, linked by reference in `<head>`:
  `<link rel="stylesheet" href="../../../.claude/skills/html-explainer/assets/base.css">` (same `../` depth as the comment layer).
  Skim its header and class list before writing. Rules:
  - Use its tokens (`var(--accent)` etc.), never raw hex in markup or SVG.
  - Serif for h1/h2 only. Prose stays in the ~68ch column; only figures break out (`.wide`).
  - Color means state: blue active, sage ok, ochre caveat/inferred, rust risk. Decoration stays neutral.
  - Diagrams go in a `.figure` card, styled by class (`.node.on`, `.edge.on`) so interactions just toggle classes.
  - Motion ≤200ms ease-out; loops (`.edge.flow`) only for things actually moving.
- Single self-contained file: inline CSS/JS/SVG, no external deps. One exception: the comment layer is referenced, not inlined (next bullets).
- No `html-widget` / branding skills; design directly for the subject.
- Code blocks: syntax-highlight with the vendored Prism in `assets/prism/`, by reference like the
  comment layer (script order core → clike → javascript → typescript → json/bash → diff →
  diff-highlight, plus both CSS files). `language-typescript` for code; `class="diff-highlight"` +
  `language-diff-typescript` for diffs with syntax inside. Escape `<` as `&lt;`. Annotations must be
  code comments; Prism discards embedded spans when tokenizing. Override the theme's font
  (`code[class*="language-"], pre[class*="language-"] { font-size:12px !important;
  font-family:var(--mono) !important; }`); its Consolas-at-1em renders oversized.
- Verify in a real browser before sharing: screenshot the layout, check console errors, exercise every interaction. Fix what you see. Caveat: clipboard writes fail under synthetic (eval-dispatched) clicks; use a real CDP click before concluding a copy button is broken.
- Include the reader comment layer by REFERENCE (do not read or inline the asset): add exactly this before `</body>`:
  `<script src="../../../.claude/skills/html-explainer/assets/comment-layer.js"></script>`
  (relative path is correct for files in `~/memory/projects/explainers/`; adjust the `../` depth if the explainer lives elsewhere). The script injects its own styles; `file://` pages load sibling `file://` scripts fine. It lets the reader select text or (rarely) drop pins, leave comments, then hit "Copy all" to produce a `[C1] … / Section: … / Comment: …` payload they paste back to the agent. When the page has stateful widgets (simulators, toggles), define `window.zcExtraContext = (clickTarget) => string | null` in a page script so pins capture that state (e.g. `diagram: <mode> · <scenario> · step 3/10`). When the page swaps content per route or step (hash routing, slides re-rendered via `innerHTML`), also define `window.zcView = () => <current route id>`; comments are stored per file, so without it they re-anchor on matching text in other routes. Comments persist in localStorage until copied; anchors are quote+context for text, doc coordinates for pins.
- Both references break if the file leaves this machine. Share copies come from `scripts/share-copy.py <in> <out> [--no-comments]`, which inlines them (see `sharing.md`).
- Save the file in `~/memory/projects/explainers/` (durable), then display it where the
  user actually is:
  - Desktop app (the `mcp__Claude_Browser__*` tools are in the session): `navigate` the
    built-in browser to the `file://` URL. Verify there too.
  - Terminal otherwise: new kitty tab, `kitten @ launch --type=tab --tab-title "<title>"
    terminal-browser open <path>` (`<title>` is a 2-3 word subject, e.g. `Deploy Pipeline`);
    with `--split`, `terminal-browser open <path> --split right --size 0.4` instead. See the
    terminal-browser skill for driving the pane and gotchas.
  Either way, also output the direct file URL
  (`file:///Users/jeanlucthumm/memory/projects/explainers/<file>.html`) as a Chrome fallback,
  copy the absolute path to the clipboard (`printf %s "$path" | pbcopy`), and say it is there.
- `--live` (experimental): comments go to this session as they're written and you answer inline on the page. Read `live.md`.
- If the user wants to share the explainer, make it public, or send a link to someone: read `sharing.md` (in this skill's directory).
