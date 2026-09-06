#!/usr/bin/env python3
"""Alert on new Odyssey IMAX showtimes at AMC Metreon 16, via Telegram.

Source is cinemaclock, not AMC or Fandango, and that is deliberate:

  - amctheatres.com sits behind Queue-it (a virtual waiting room), and its
    API needs a vendor key that only grants catalog access anyway.
  - fandango.com renders showtimes client-side from /napi/*, which its
    robots.txt disallows.
  - cinemaclock serves showtimes in static HTML and its robots.txt only
    disallows /aw/*.

Two limits this cannot work around, both inherent to the source:

  - cinemaclock labels the auditorium "IMAX Screen" and never tags 70mm, so
    this watches Metreon's IMAX screen. Metreon is one of the 41 IMAX 70mm
    film sites and Odyssey is the 70mm booking there, so these are almost
    certainly the 70mm shows -- but that is inference, not a tagged fact.
  - There is no seat availability in the source at all. This fires when a
    *new showtime appears*, not when a seat frees up on an existing one.
    Since AMC's queue equalises purchase speed, the new-batch drop is the
    signal that actually matters; seat-level would need the AMC vendor key.
"""

import argparse
import json
import os
import re
import sys
import urllib.parse
import urllib.request
from pathlib import Path

URL = "https://www.cinemaclock.com/movie-theaters/amc-metreon-16"
MOVIE_ID = "257847"  # The Odyssey (2026) on cinemaclock
UA = "odyssey-watch/1.0 (personal showtime notifier)"

TELEGRAM_API = "https://api.telegram.org"


def fetch(url=URL):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=30) as r:
        return r.read().decode("utf-8", "replace")


def parse(html):
    """Return {"Mon DD": [times]} for the Odyssey IMAX block at this theatre."""
    blocks = re.findall(
        r'<div data-earliest-date="(\d{8})"[^>]*class="([^"]*fie%s[^"]*)"(.*?)(?=<div data-earliest-date=|\Z)'
        % MOVIE_ID,
        html,
        re.S,
    )
    out = {}
    for _earliest, classes, body in blocks:
        auditorium = ""
        m = re.search(r'<p class="timesalso">(.*?)</p>', body, re.S)
        if m:
            auditorium = re.sub(r"<[^>]*>|<!--.*?-->", "", m.group(1))
            auditorium = auditorium.replace("&nbsp;", " ").strip()
        if "imax" not in classes.lower() and "imax" not in auditorium.lower():
            continue
        for _label, date, times_html in re.findall(
            r"<u>([^<]*)<span class=\"timesdate\">([^<]*)</span></u>\s*<i>(.*?)</i>",
            body,
            re.S,
        ):
            times = [
                t.replace("&nbsp;", " ").strip()
                for t in re.findall(
                    r'<span class="tix[^"]*"[^>]*>([^<]*)</span>', times_html
                )
            ]
            # Key on the calendar date only. The day label is relative
            # ("Tonight", "Fri") and rolls over daily, which would otherwise
            # fire every tracked showtime as new at midnight.
            key = date.replace("&nbsp;", " ").strip()
            if times:
                out.setdefault(key, []).extend(times)
    return out


def flat(showings):
    return {f"{d} @ {t}" for d, times in showings.items() for t in times}


def telegram(text):
    token = os.environ.get("TELEGRAM_BOT_TOKEN")
    chat = os.environ.get("TELEGRAM_CHAT_ID")
    if not token or not chat:
        print(
            "ERROR: TELEGRAM_BOT_TOKEN / TELEGRAM_CHAT_ID unset -- "
            "run 'deposit-secrets odyssey-telegram' from a hardware-key host",
            file=sys.stderr,
        )
        return False
    data = urllib.parse.urlencode(
        {"chat_id": chat, "text": text, "disable_web_page_preview": "true"}
    ).encode()
    req = urllib.request.Request(
        f"{TELEGRAM_API}/bot{token}/sendMessage",
        data=data,
        headers={"User-Agent": UA},
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            body = json.loads(r.read().decode())
        if not body.get("ok"):
            print(f"ERROR: telegram rejected: {body}", file=sys.stderr)
            return False
        return True
    except Exception as e:  # noqa: BLE001 -- a failed alert must not kill the timer
        print(f"ERROR: telegram send failed: {e}", file=sys.stderr)
        return False


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--state",
        default=os.environ.get("ODYSSEY_STATE", "/var/lib/odyssey-watch/state.json"),
    )
    ap.add_argument("--show", action="store_true", help="print showtimes and exit")
    ap.add_argument(
        "--dry-run", action="store_true", help="diff but do not send or persist"
    )
    ap.add_argument(
        "--test-telegram", action="store_true", help="send a test message and exit"
    )
    ap.add_argument("--from-file", help="parse a local HTML file instead of fetching")
    args = ap.parse_args()

    if args.test_telegram:
        ok = telegram("odyssey-watch: test message, wiring is good.")
        print("sent" if ok else "failed")
        return 0 if ok else 1

    html = (
        Path(args.from_file).read_text(errors="replace")
        if args.from_file
        else fetch()
    )
    showings = parse(html)

    if not showings:
        # Exit non-zero so a silently-broken scraper shows up as a failed unit
        # rather than as an eternally quiet bot.
        print(
            "ERROR: no Odyssey IMAX showings parsed -- page structure changed, "
            "or the run has ended",
            file=sys.stderr,
        )
        return 2

    if args.show:
        for d, times in showings.items():
            print(f"{d:10} {'  '.join(times)}")
        return 0

    state = Path(args.state)
    now = flat(showings)
    prev = set(json.loads(state.read_text())) if state.exists() else None

    if prev is None:
        if not args.dry_run:
            state.parent.mkdir(parents=True, exist_ok=True)
            state.write_text(json.dumps(sorted(now), indent=1))
        print(f"seeded state with {len(now)} showtimes")
        return 0

    new = sorted(now - prev)
    gone = sorted(prev - now)

    if new:
        msg = "\n".join(
            [f"{len(new)} new Odyssey IMAX showtime(s) at AMC Metreon 16:", ""]
            + [f"  {s}" for s in new]
            + ["", "https://www.amctheatres.com/movies/the-odyssey-80679/showtimes"]
        )
        print(msg)
        if not args.dry_run:
            telegram(msg)
    else:
        print(f"no new showtimes ({len(now)} tracked)")
    if gone:
        print(f"  ({len(gone)} dropped off: {'; '.join(gone[:4])})")

    if not args.dry_run:
        state.parent.mkdir(parents=True, exist_ok=True)
        state.write_text(json.dumps(sorted(now), indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
