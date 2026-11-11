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
# Extra args pass through to the hints kitten, e.g. `kitten url_hints.py --program @`.
import re
from typing import Any

from kittens.tui.handler import result_handler
from kitty.boss import Boss
from kitty.fast_data_types import get_options

# The escape codes the hints kitten strips: SGR, and OSC terminated by ST.
ESCAPE = re.compile(r'\x1b(?:\[[0-9;:]*m|\].*?\x1b\\)')
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


def link_plain_urls(raw: str) -> str:
    """Wrap every URL in `raw` that is not already inside an OSC 8 hyperlink in one."""
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
        out += [raw[last:a], f'\x1b]8;;{url}\x1b\\', raw[a:b], '\x1b]8;;\x1b\\']
        last = b
    out.append(raw[last:])
    return ''.join(out)


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
        'hints', ['--type=hyperlink', *args[1:]], input_data=link_plain_urls(text), window=w)
