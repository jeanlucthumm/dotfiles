#!/usr/bin/env python3
"""ctx_check: context-window fill of every live Claude Code session, as a table.

A manual overview. Sessions notice their own crossings through the self-compact mod
(~/.claude/mods/self-compact); this script only shows the fleet at a glance.

Context % uses the status line's own formula (verified in the 2.1.321 binary):
round((input + cache_creation + cache_read) / window * 100), from the last main-thread
assistant response. Window: every current model (Opus/Sonnet/Haiku 5.x, Fable) is 1M
natively; older models are 200k unless the session asked for [1m]. Thresholds match the
mod's LIMITS (currently 45% for every role).

Read-only on transcripts and session records.
"""
import datetime as dt
import glob
import json
import os
import re
import time

CLAUDE = os.path.join(os.path.expanduser("~"), ".claude")
BLOCK = 1 << 20
LIMITS = {"planner": 45, "executor": 45}
PLANNER_RE = re.compile(r"\b(planning|planner|design)\b", re.I)
ACTIVE_SECS = 6 * 3600  # skip sessions with no response for this long
NATIVE_1M_RE = re.compile(r"claude-(opus|sonnet|haiku|fable|mythos)-(5|4-7|4-8)\b")


def load_json(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def alive(pid):
    try:
        os.kill(pid, 0)
        return True
    except (OSError, TypeError):
        return False


def live_sessions():
    """Running sessions. Never reads *.key files.

    Job state is no filter: it reads "done" after every finished turn of a live session.
    """
    jobs = {}
    for p in glob.glob(os.path.join(CLAUDE, "jobs", "*", "state.json")):
        d = load_json(p)
        if d and d.get("sessionId"):
            jobs[d["sessionId"]] = d
    out = []
    for p in glob.glob(os.path.join(CLAUDE, "sessions", "*.json")):
        d = load_json(p)
        if not d or not d.get("sessionId") or not alive(d.get("pid")):
            continue
        name = re.sub(r"\s+", " ", d.get("name") or "").strip()  # as ListAgents spells it
        out.append(dict(sid=d["sessionId"], name=name or d["sessionId"][:8],
                        path=jobs.get(d["sessionId"], {}).get("linkScanPath")))
    return out


def transcript(s):
    if s["path"] and os.path.exists(s["path"]):
        return s["path"]
    hits = glob.glob(os.path.join(CLAUDE, "projects", "*", s["sid"] + ".jsonl"))
    return max(hits, key=os.path.getmtime) if hits else None


def reverse_lines(path):
    with open(path, "rb") as f:
        f.seek(0, os.SEEK_END)
        pos, tail = f.tell(), b""
        while pos > 0:
            step = min(BLOCK, pos)
            pos -= step
            f.seek(pos)
            lines = (f.read(step) + tail).split(b"\n")
            tail = lines[0]
            for ln in reversed(lines[1:]):
                if ln.strip():
                    yield ln
        if tail.strip():
            yield tail


def window_for(model, requested):
    if os.environ.get("CLAUDE_CODE_DISABLE_1M_CONTEXT"):
        return 200_000
    if NATIVE_1M_RE.search(model or "") or "[1m]" in (requested or "").lower():
        return 1_000_000
    return 200_000


def recent(ts):
    try:
        t = dt.datetime.fromisoformat(ts.replace("Z", "+00:00")).timestamp()
    except (AttributeError, ValueError):
        return False
    return time.time() - t <= ACTIVE_SECS


def context_of(path):
    """(tokens, window) from the newest main-thread response, or after a compaction.

    (None, None) when that entry is older than ACTIVE_SECS: transcript mtimes move
    without new turns, so the entry's own timestamp decides.
    """
    for ln in reverse_lines(path):
        try:
            e = json.loads(ln)
        except ValueError:
            continue
        if e.get("type") == "system" and e.get("subtype") == "compact_boundary":
            post = (e.get("compactMetadata") or {}).get("postTokens")
            return (post, None) if post and recent(e.get("timestamp")) else (None, None)
        if e.get("type") != "assistant" or e.get("isSidechain"):
            continue
        m = e.get("message") or {}
        u = m.get("usage") or {}
        tok = sum(u.get(k) or 0 for k in
                  ("input_tokens", "cache_creation_input_tokens", "cache_read_input_tokens"))
        if tok and m.get("model") != "<synthetic>":
            if not recent(e.get("timestamp")):
                return None, None
            return tok, window_for(m.get("model"), e.get("requestedModel"))
    return None, None


def main():
    rows = []
    for s in live_sessions():
        p = transcript(s)
        tok, win = context_of(p) if p else (None, None)
        if tok is None:
            continue
        win = win or 1_000_000  # just compacted: no response yet to name the model
        role = "planner" if PLANNER_RE.search(s["name"]) else "executor"
        rows.append((round(tok / win * 100), tok, win, role, s["name"]))
    for pct, tok, win, role, name in sorted(rows, reverse=True):
        mark = "OVER" if pct >= LIMITS[role] else ""
        print(f"{pct:>3}% {tok:>9,}/{win // 1000}k {role:8} lim {LIMITS[role]}% {mark:4} {name}")


if __name__ == "__main__":
    main()
