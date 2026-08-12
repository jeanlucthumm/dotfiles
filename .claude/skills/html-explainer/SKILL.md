---
name: html-explainer
description: Use when building an HTML explainer — an interactive, single-file HTML document explaining a system, design, decision, or investigation. Trigger BEFORE writing any explainer HTML, including when the user says "explainer", "HTML explainer", or asks to visualize/present findings as a shareable HTML page.
---

# HTML explainers

Hard requirements — everything else is your call:

- Diagrams first, prose second.
- Interactive by default, not static — clicking/toggling should reveal something (details, outcomes, animation). Static boxes are the fallback, not the norm.
- Light theme.
- Single self-contained file: inline CSS/JS/SVG, no external deps. One exception: the comment layer is referenced, not inlined (next bullets).
- No `html-widget` / branding skills; design directly for the subject.
- Verify in a real browser before sharing: screenshot the layout, check console errors, exercise every interaction. Fix what you see. Caveat: clipboard writes fail under synthetic (eval-dispatched) clicks; use a real CDP click before concluding a copy button is broken.
- Include the reader comment layer by REFERENCE (do not read or inline the asset): add exactly this before `</body>`:
  `<script src="../../../.claude/skills/html-explainer/assets/comment-layer.js"></script>`
  (relative path is correct for files in `~/memory/projects/explainers/`; adjust the `../` depth if the explainer lives elsewhere). The script injects its own styles; `file://` pages load sibling `file://` scripts fine. It lets the reader select text or drop pins, leave comments, then hit "Copy & clear" to produce a `[C1] … / Section: … / Comment: …` payload they paste back to the agent. When the page has stateful widgets (simulators, toggles), define `window.zcExtraContext = (clickTarget) => string | null` in a page script so pins capture that state (e.g. `diagram: <mode> · <scenario> · step 3/10`). Comments persist in localStorage until copied; anchors are quote+context for text, doc coordinates for pins.
- The reference breaks if the file leaves this machine. When sharing/publishing an explainer (see `sharing.md`), replace the script tag by inlining `assets/comment-layer.html` (self-contained equivalent of the same layer), or drop the layer entirely if the recipient won't round-trip comments.
- Save the file in `~/memory/projects/explainers/` (durable), then show it in a new kitty tab: `kitten @ launch --type=tab --tab-title "<slug>" terminal-browser open <path>`, where `<slug>` is a short kebab-case subject slug (2-3 words, e.g. `deploy-pipeline`). See the terminal-browser skill for driving the pane and gotchas. Also output the direct file URL (`file:///Users/jeanlucthumm/memory/projects/explainers/<file>.html`) as a Chrome fallback, and copy the absolute path to the clipboard (`printf %s "$path" | pbcopy`) and tell the user it's there.
- If the user wants to share the explainer, make it public, or send a link to someone: read `sharing.md` (in this skill's directory).
