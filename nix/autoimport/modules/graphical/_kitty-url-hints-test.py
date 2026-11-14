#!/usr/bin/env python3
"""Tests for _kitty-url-hints.py.

Default (offline): runs the kitten's text rewrite on the cases below and checks
which hints the hints kitten would show and where each opens, using a port of
its OSC 8 parser (process_escape_codes in kitty's kittens/hints/marks.go).

--e2e [DUMP...]: also renders every case, plus any `kitty @ get-text --ansi`
dumps given, in a background kitty tab (it never takes focus), runs stock
`hints --type url` and the kitten on that screen, and diffs the exact spans
each one marks. Also checks that real kitty agrees with the offline model.
Needs kitty remote control.

    python3 _kitty-url-hints-test.py [--e2e [DUMP...]]
"""
import glob
import json
import os
import re
import subprocess
import sys
import tempfile
import time
import types
from pathlib import Path

KITTEN = Path(__file__).resolve().parent / '_kitty-url-hints.py'
# kitty's default url_prefixes
URL_PREFIXES = tuple('file ftp ftps gemini git gopher http https irc ircs kitty mailto news sftp ssh'.split())
ESCAPE = re.compile(r'\x1b(?:\[[0-9;:]*?m|\].*?\x1b\\)')


def load_kitten():
    """The kitten's link_plain_urls, with kitty's modules stubbed out."""
    def stub(name: str, **attrs) -> None:
        sys.modules[name] = types.ModuleType(name)
        sys.modules[name].__dict__.update(attrs)
    opts = types.SimpleNamespace(url_prefixes=URL_PREFIXES, url_excluded_characters='')
    stub('kittens')
    stub('kittens.tui')
    stub('kittens.tui.handler', result_handler=lambda **kw: (lambda f: f))
    stub('kitty')
    stub('kitty.boss', Boss=object)
    stub('kitty.fast_data_types', get_options=lambda: opts)
    g = {'__name__': 'kitten'}
    exec(compile(KITTEN.read_text(), str(KITTEN), 'exec'), g)
    return g['link_plain_urls']


def hint_marks(text: str) -> list[tuple[str, str]]:
    """(visible text, target) of each hint `hints --type hyperlink` shows for text."""
    out: list[str] = []
    marks = []
    active, start, pos = '', 0, 0
    for m in ESCAPE.finditer(text):
        out.append(text[pos:m.start()])
        pos = m.end()
        code = m.group()
        if not code.startswith('\x1b]8'):
            continue
        here = sum(map(len, out))
        if active:
            marks.append((start, here, active))
            active = ''
        _, sep, url = code[4:-2].partition(';')
        if sep and url:
            active, start = url, here
    out.append(text[pos:])
    s = ''.join(out)
    if active:
        marks.append((start, len(s), active))
    return [(s[a:b], url) for a, b, url in marks]


def link(target: str, text: str, id: str = '') -> str:
    return f'\x1b]8;{"id=" + id if id else ""};{target}\x1b\\{text}\x1b]8;;\x1b\\'


def same(url: str) -> tuple[str, str]:
    return (url, url)


# Synthetic URLs, long enough to wrap. Keep real work URLs out of this public repo.
H = ('https://ci.example.com/ng/account/acct0000000000/all/orgs/default/projects/demoproject'
     '/pipelines/deploy_service_region/executions/exec00000000000000/pipeline')
G = ('https://auth.example.com/o/oauth2/auth?response_type=code&client_id=0000000000.apps.example.com'
     '&redirect_uri=https%3A%2F%2Fexample.com%2Fauthcode.html&scope=openid&state=state000000&prompt=consent'
     '&code_challenge=challenge0000000&code_challenge_method=S256')
G_WRAPPED = G[:120] + '\r' + G[120:]  # \r marks a soft wrap in kitty's screen text

# (name, screen text, expected hints as (visible text, target))
CASES = [
    ('plain url', 'see https://example.com/a here\n', [same('https://example.com/a')]),
    ('trailing period dropped', 'go to https://example.com/a.\n', [same('https://example.com/a')]),
    ('soft wrap joins; blank line ends it (gcloud)',
     f'Go to the following link:\n\n    {G_WRAPPED}\n\nOnce finished, enter the verification code: \n',
     [(G_WRAPPED, G)]),
    ('hard newline ends a url', 'https://a.example/one\nhttps://b.example/two\n',
     [same('https://a.example/one'), same('https://b.example/two')]),
    ('claude file link is not a url',
     '⏺ Update(' + link('file:///Users/me/nix/autoimport/modules/graphical/_kitty-url-hints.py',
                        'autoimport/modules/graphical/_kitty-url-hints.py', 'v0g02y') + ')\n',
     []),
    ('visible file url keeps its hint', 'open ' + link('file:///tmp/x.txt', 'file:///tmp/x.txt') + '\n',
     [same('file:///tmp/x.txt')]),
    ('relative link is not a url', 'see ' + link('docs/readme.md', 'readme') + '\n', []),
    ('plain path is not a url', 'edit autoimport/modules/foo.py now\n', []),
    ('claude hard-wrapped link opens in full',
     '     ' + link(H, H[:100], 'jreqkh') + '\n     ' + link(H, H[100:], 'jreqkh') + '\n',
     [(H[:100], H), (H[100:], H)]),
    ('claude pr ref', 'merged ' + link('https://github.com/o/r/pull/1234', '#1234') + ' today\n',
     [('#1234', 'https://github.com/o/r/pull/1234')]),
    ('plain url next to a link', link('https://x.example/1', 'one') + ' https://y.example/2\n',
     [('one', 'https://x.example/1'), same('https://y.example/2')]),
    ('quotes and parens', '(https://example.com/b) and "https://example.com/c"\n',
     [same('https://example.com/b'), same('https://example.com/c')]),
    ('balanced parens kept', 'x (https://en.wikipedia.org/wiki/Foo_(bar)) y\n',
     [same('https://en.wikipedia.org/wiki/Foo_(bar)')]),
    ('unbalanced paren dropped', 'sheet, https://a.b/p/41). z\n', [same('https://a.b/p/41')]),
    ('markdown link', '[link](https://a.b/c)\n', [same('https://a.b/c')]),
    ('colors inside a url', 'x \x1b[34mhttps://ex\x1b[1mample.com/a\x1b[22m\x1b[39m y\n',
     [same('https://example.com/a')]),
    ('known limit: indented hard wrap without a link', '   https://example.com/aaaa\n   bbbb/cccc\n',
     [same('https://example.com/aaaa')]),
]


# Cases where the kitten deliberately differs from stock hints, which keeps a
# trailing "." or ")." and cuts "(…/Foo_(bar))" at the first ")".
BETTER_THAN_STOCK = {'trailing period dropped', 'balanced parens kept', 'unbalanced paren dropped'}


def run_offline(prepare) -> int:
    failures = 0
    for name, text, want in CASES:
        prepared = prepare(text)
        got = hint_marks(prepared)
        problems = []
        if ESCAPE.sub('', prepared) != ESCAPE.sub('', text):
            problems.append('visible text changed')
        if got != want:
            problems.append(f'hints\n      want {want}\n      got  {got}')
        failures += bool(problems)
        print(('FAIL ' if problems else 'ok   ') + name + ''.join('\n    ' + p for p in problems))
    return failures


# --- e2e against a live kitty ---------------------------------------------

LINK_OR_ESCAPE = re.compile(r'\x1b\]8;[^;]*;([^\x1b\x07]*)(?:\x1b\\|\x07)|\x1b\[[0-9;:?]*[a-zA-Z]|\x1b\][^\x07\x1b]*(?:\x1b\\|\x07)')


class Kitty:
    def __init__(self) -> None:
        # KITTY_LISTEN_ON goes stale when kitty restarts under a long-lived shell.
        to = os.environ.get('KITTY_LISTEN_ON', '')
        if not os.path.exists(to.removeprefix('unix:')):
            socks = sorted(glob.glob('/tmp/kitty-*'), key=os.path.getmtime)
            if not socks:
                sys.exit('no kitty remote control socket found')
            to = 'unix:' + socks[-1]
        self.to = to

    def rc(self, *args: str) -> str:
        # Bytes, not text=True: universal newlines would turn soft-wrap \r into \n.
        # get-text ends hard lines with \r\n where kitty's own screen text has \n.
        r = subprocess.run(['kitty', '@', '--to', self.to, *args], capture_output=True)
        if r.returncode:
            raise RuntimeError(f'kitty @ {" ".join(args)}: {r.stderr.decode().strip()}')
        return r.stdout.decode().replace('\r\n', '\n')

    def tab_of(self, wid: int) -> list[int]:
        for osw in json.loads(self.rc('ls')):
            for tab in osw['tabs']:
                ids = [w['id'] for w in tab['windows']]
                if wid in ids:
                    return ids
        return []

    def wait(self, cond, what: str, timeout: float = 5):
        end = time.time() + timeout
        while time.time() < end:
            if (v := cond()):
                return v
            time.sleep(0.1)
        raise RuntimeError(f'timed out waiting for {what}')

    def overlay_marks(self, wid: int, kitten: list[str]) -> list[tuple[tuple[int, int], str]]:
        """Run a kitten on window wid and read back the hints overlay's marks."""
        self.rc('kitten', f'--match=id:{wid}', *kitten)
        oid = self.wait(lambda: next((i for i in self.tab_of(wid) if i != wid), None), 'hints overlay')
        prev = None
        def stable():
            nonlocal prev
            cur = self.rc('get-text', f'--match=id:{oid}', '--ansi')
            ok, prev = cur == prev and cur.strip(), cur
            return cur if ok else None
        ansi = self.wait(stable, 'overlay to render')
        self.rc('send-key', f'--match=id:{oid}', 'escape')
        self.wait(lambda: oid not in self.tab_of(wid), 'overlay to close')
        # Every mark is drawn inside an OSC 8 link to mark:<index>.
        marks: dict[str, list] = {}
        cur, row, col, pos = None, 0, 0, 0
        def feed(chunk: str) -> None:
            nonlocal row, col
            for ch in chunk:
                if ch == '\n':
                    row, col = row + 1, 0
                    continue
                if cur:
                    marks.setdefault(cur, [(row, col), ''])[1] += ch
                col += 1
        for m in LINK_OR_ESCAPE.finditer(ansi):
            feed(ansi[pos:m.start()])
            pos = m.end()
            if m.group().startswith('\x1b]8;'):
                cur = m.group(1) if m.group(1).startswith('mark:') else None
        feed(ansi[pos:])
        return sorted((start, text) for start, text in marks.values())


def tail(text: str) -> str:
    """Mark text past the hint label, which covers its first char or two."""
    return re.sub(r'[\r\n\x00]', '', text)[2:]


def run_e2e(prepare, dumps: list[str]) -> int:
    k = Kitty()
    fixtures = [(name, text.replace('\r', '')) for name, text, _ in CASES]
    for d in dumps:
        with open(d, encoding='utf-8', newline='') as f:
            fixtures.append((Path(d).name, f.read()))
    failures = 0
    with tempfile.TemporaryDirectory() as tmp:
        for name, text in fixtures:
            f = Path(tmp, 'screen.ansi')
            f.write_text(text, encoding='utf-8')
            wid = int(k.rc('launch', '--type=tab', '--keep-focus', '--tab-title=url-hints-test',
                           'sh', '-c', f'printf "\\033[H\\033[2J"; cat {f}; exec sleep 600'))
            try:
                time.sleep(0.4)
                screen = k.rc('get-text', f'--match=id:{wid}', '--ansi', '--add-wrap-markers')
                stock = k.overlay_marks(wid, ['hints', '--type=url'])
                mine = k.overlay_marks(wid, [str(KITTEN)])
            finally:
                k.rc('close-window', f'--match=id:{wid}')
            predicted = hint_marks(prepare(screen))
            problems = []
            if [tail(t) for t, _ in predicted] != [tail(t) for _, t in mine]:
                problems.append(f'real kitty disagrees with offline model\n      offline {[t for t, _ in predicted]}'
                                f'\n      kitty   {[t for _, t in mine]}')
            targets = {tail(t): u for t, u in predicted}
            stock_set = {(s, tail(t)) for s, t in stock}
            mine_set = {(s, tail(t)) for s, t in mine}
            lost = sorted(stock_set - mine_set)
            if lost and name not in BETTER_THAN_STOCK:
                problems.append('stock marks the kitten lost or changed: ' + ', '.join(f'{s} ··{t}' for s, t in lost))
            added = sorted(mine_set - stock_set)
            failures += bool(problems)
            print(('FAIL ' if problems else 'ok   ') + f'{name}: stock {len(stock)}, kitten {len(mine)}'
                  + ''.join(f'\n    + {s} ··{t} -> {targets.get(t, "?")}' for s, t in added)
                  + ''.join('\n    ' + p for p in problems))
    return failures


if __name__ == '__main__':
    prepare = load_kitten()
    print('-- offline')
    failed = run_offline(prepare)
    if sys.argv[1:2] == ['--e2e']:
        print('-- e2e: stock `hints --type url` vs kitten, + = only the kitten marks it')
        failed += run_e2e(prepare, sys.argv[2:])
    sys.exit(1 if failed else 0)
