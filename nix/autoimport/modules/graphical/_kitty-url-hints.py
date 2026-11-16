# Kitty kitten: URL hints that use OSC 8 hyperlink targets when present.
#
# Some TUIs (Claude Code, for one) hard-wrap a long URL with a newline plus
# indentation, so the stock `--type url` hints only match its first line. They
# also wrap every fragment in an OSC 8 hyperlink whose target is the full URL.
#
# This kitten wraps each plain-text URL on screen in an OSC 8 link to itself,
# then runs the hints kitten in hyperlink mode on that text. Hyperlinked URLs
# resolve to their real target, plain ones behave as before, and the screen
# looks unchanged because OSC 8 is invisible.
#
# Only links to web-style URLs keep their hint. Claude Code also links every
# file path it prints, e.g. "Update(src/foo.py)" -> file:///.../src/foo.py,
# and those are not URLs on screen. A link wrapped onto several lines gets one
# hint, on its top line.
#
# Tests: _kitty-url-hints-test.py (offline cases, plus a diff against stock
# hints in a live kitty with --e2e).
#
# Extra args pass through to the hints kitten, e.g. `kitten url_hints.py --program @`.
import re
from typing import Any

from kittens.tui.handler import result_handler
from kitty.boss import Boss
from kitty.fast_data_types import get_options

# The escape codes the hints kitten strips: SGR, and OSC terminated by ST.
ESCAPE = re.compile(r'\x1b(?:\[[0-9;:]*m|\].*?\x1b\\)')
LINK_END = '\x1b]8;;\x1b\\'
# Stands in for already-hyperlinked text so a plain URL match can't run into it.
LINKED = '\x01'
CLOSERS = {'(': ')', '[': ']', '{': '}', '<': '>', '*': '*', '"': '"', "'": "'", '“': '”', '‘': '’'}
OPENERS = {')': '(', ']': '[', '}': '{'}


def url_pattern() -> 're.Pattern[str]':
    """The hints kitten's url regex: URL code points, minus url_excluded_characters.

    A URL may span a soft wrap (\\r marker) but ends at a hard newline, like the
    stock hints in practice. Joining across \\n glued the next line onto URLs,
    e.g. gcloud's "...=S256" + blank line + "Once finished" became "S256Once".
    """
    opts = get_options()
    prefixes = '|'.join(map(re.escape, opts.url_prefixes))
    char = r"[\ra-zA-Z0-9!$&#'/:;@_~()*+,\-.=?% -\U0010ffff]"
    if opts.url_excluded_characters:
        char = f'(?![{re.escape(opts.url_excluded_characters)}]){char}'
    return re.compile(f'(?:{prefixes})://(?:{char}){{3,}}')


def trim_end(text: str, s: int, e: int) -> int:
    """End of a URL match after the hints kitten's url post-processing.

    Unlike the hints kitten, brackets are balanced: "see https://x.com/a)."
    drops the ")", and "(https://x.com/Foo_(bar))" keeps "Foo_(bar)".
    """
    while e > s + 1:
        last = text[e - 1]
        if last in ',.?!\r\n':
            e -= 1
        elif last in OPENERS and text.count(OPENERS[last], s, e) < text.count(last, s, e):
            e -= 1
        else:
            break
    # A URL right after an opening bracket or quote ends at its partner.
    opener = text[s - 1] if s > 0 else ''
    if closer := CLOSERS.get(opener):
        depth = 0
        for i in range(s, e):
            if text[i] == closer:
                if depth == 0:
                    e = i
                    break
                depth -= 1
            elif text[i] == opener:
                depth += 1
    if text[e - 2:e] == '`_':
        e -= 2
    return e


def is_url_link(target: str) -> bool:
    """Whether an OSC 8 link target is a URL worth a hint (not a file path)."""
    scheme, sep, _ = target.partition(':')
    scheme = scheme.lower()
    return bool(sep) and scheme != 'file' and scheme in get_options().url_prefixes


def unlink_non_urls(raw: str) -> str:
    """Turn OSC 8 links to non-URLs (file paths) back into plain text.

    Their opening code becomes a closing one; their own closing code is then a
    no-op. Plain URL detection still sees the text, so a visible file:// URL
    keeps its hint.
    """
    def repl(m: 're.Match[str]') -> str:
        code = m.group()
        if code.startswith('\x1b]8') and (target := code[4:-2].partition(';')[2]) and not is_url_link(target):
            return LINK_END
        return code
    return ESCAPE.sub(repl, raw)


def link_plain_urls(raw: str) -> str:
    """Wrap every URL that is not already inside an OSC 8 link in one."""
    visible: list[str] = []
    offsets: list[int] = []  # raw index of each visible char
    in_link = False
    pos = 0

    def take(end: int) -> None:
        for i in range(pos, end):
            visible.append(LINKED if in_link else raw[i])
            offsets.append(i)

    for m in ESCAPE.finditer(raw):
        take(m.start())
        pos = m.end()
        code = m.group()
        if code.startswith('\x1b]8'):
            in_link = bool(code[4:-2].partition(';')[2])
    take(len(raw))

    text = ''.join(visible)
    out: list[str] = []
    last = 0
    for m in url_pattern().finditer(text):
        s = m.start()
        e = trim_end(text, s, m.end())
        url = re.sub(r'[\r\n\x00]', '', text[s:e])
        a, b = offsets[s], offsets[e - 1] + 1
        out += [raw[last:a], f'\x1b]8;;{url}\x1b\\', raw[a:b], LINK_END]
        last = b
    out.append(raw[last:])
    return ''.join(out)


def merge_wrapped_links(raw: str) -> str:
    """Give a link a TUI wrapped onto several lines one hint, on its top line.

    Claude Code prints each line of a wrapped URL as its own OSC 8 link with the
    same id and target. A link repeating the previous link's id and target with
    only whitespace in between is a continuation: its opening code becomes a
    closing one, so it gets no hint of its own. The same URL printed again
    elsewhere keeps its hint.
    """
    current = None  # (params, target) of the link we are inside
    last = None  # the most recent link, while only whitespace follows it
    pos = 0

    def repl(m: 're.Match[str]') -> str:
        nonlocal current, last, pos
        gap, pos = raw[pos:m.start()], m.end()
        if current is None and gap.strip():
            last = None
        code = m.group()
        if not code.startswith('\x1b]8'):
            return code
        params, _, target = code[4:-2].partition(';')
        if current is not None:
            last = current
        current = (params, target) if target else None
        if current is not None and current == last and 'id=' in params:
            return LINK_END
        return code
    return ESCAPE.sub(repl, raw)


def prepare_screen(raw: str) -> str:
    """Screen text for hyperlink-mode hints: one hint per URL, none for file paths."""
    # Merging runs last so plain URL detection never looks inside a continuation.
    return merge_wrapped_links(link_plain_urls(unlink_non_urls(raw)))


def main(args: list[str]) -> None:
    pass


@result_handler(no_ui=True)
def handle_result(args: list[str], answer: Any, target_window_id: int, boss: Boss) -> None:
    w = boss.window_id_map.get(target_window_id)
    if w is None:
        return
    # The same text the hints kitten reads on its own (type_of_input 'screen-ansi').
    text = w.as_text(as_ansi=True, add_wrap_markers=True)
    boss.run_kitten_with_metadata(
        'hints', ['--type=hyperlink', *args[1:]], input_data=prepare_screen(text), window=w)
