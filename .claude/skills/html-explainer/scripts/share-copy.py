#!/usr/bin/env python3
"""Usage: share-copy.py <explainer.html> <out.html> [--no-comments]
Inlines the by-reference base.css and comment-layer.js so the copy works off
this machine. --no-comments drops the comment layer instead of inlining it."""
import pathlib, re, sys

src, out = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
assets = pathlib.Path(__file__).resolve().parent.parent / "assets"
html = src.read_text()
css = (assets / "base.css").read_text()
html = re.sub(r'<link[^>]*href="[^"]*base\.css"[^>]*>', lambda _: "<style>\n" + css + "\n</style>", html)
if "--no-comments" in sys.argv:
    html = re.sub(r'<script src="[^"]*comment-layer\.js"></script>', "", html)
else:
    js = (assets / "comment-layer.js").read_text().replace("</script", "<\\/script")
    html = re.sub(r'<script src="[^"]*comment-layer\.js"></script>', lambda _: "<script>\n" + js + "\n</script>", html)
# Prism (by-reference code highlighting)
html = re.sub(r'<link[^>]*href="[^"]*assets/prism/([\w.-]+\.css)"[^>]*>',
              lambda m: "<style>\n" + (assets / "prism" / m[1]).read_text() + "\n</style>", html)
html = re.sub(r'<script src="[^"]*assets/prism/([\w.-]+\.js)"></script>',
              lambda m: "<script>\n" + (assets / "prism" / m[1]).read_text().replace("</script", "<\\/script") + "\n</script>", html)
out.write_text(html)
