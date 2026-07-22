---
name: html-explainer
description: Use when building an HTML explainer — an interactive, single-file HTML document explaining a system, design, decision, or investigation. Trigger BEFORE writing any explainer HTML, including when the user says "explainer", "HTML explainer", or asks to visualize/present findings as a shareable HTML page.
---

# HTML explainers

Hard requirements — everything else is your call:

- Diagrams first, prose second.
- Interactive by default, not static — clicking/toggling should reveal something (details, outcomes, animation). Static boxes are the fallback, not the norm.
- Light theme.
- Single self-contained file: inline CSS/JS/SVG, no external deps.
- No `html-widget` / branding skills; design directly for the subject.
- Verify in a real browser before sharing: screenshot the layout, check console errors, exercise every interaction. Fix what you see. Caveat: clipboard writes fail under synthetic (eval-dispatched) clicks; use a real CDP click before concluding a copy button is broken.
- Include the reader comment layer: inline the whole snippet from `assets/comment-layer.html` (in this skill's directory) before `</body>`. It lets the reader select text or drop pins, leave comments, then hit "Copy & clear" to produce a `[C1] … / Section: … / Comment: …` payload they paste back to the agent. When the page has stateful widgets (simulators, toggles), define `window.zcExtraContext = (clickTarget) => string | null` in a page script so pins capture that state (e.g. `diagram: <mode> · <scenario> · step 3/10`). Comments persist in localStorage until copied; anchors are quote+context for text, doc coordinates for pins.
- Save the file in `~/memory/projects/explainers/` (durable), then output the direct file URL (`file:///Users/jeanlucthumm/memory/projects/explainers/<file>.html`) so it can be opened straight in Chrome — no local server needed. Also copy the absolute path to the clipboard (`printf %s "$path" | pbcopy`) and tell the user it's in their clipboard.
- If the user wants to share the explainer, make it public, or send a link to someone: read `sharing.md` (in this skill's directory).
