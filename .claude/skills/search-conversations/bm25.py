#!/usr/bin/env python3
"""BM25 lexical search over Markdown files and Claude Code session transcripts.

Zero dependencies (stdlib only). Re-indexes on every run to avoid stale caches.

Markdown (.md) is chunked by H2 section, same as ~/memory/bm25.py. Claude Code
transcripts (.jsonl) are chunked per message: each user/assistant text message
becomes one document. Injected context is filtered out so it cannot pollute
rankings:
  - isMeta entries (CLAUDE.md context injection) and non-message entry types
  - <system-reminder> / <task-notification> spans inside messages
  - slash-command wrapper messages and local-command output
  - "Caveat: The messages below..." resume preambles
  - exact duplicates across files (resumed sessions rewrite history) via uuid,
    and repeated identical text via a normalized-text hash

Transcript hits are labeled with the session title (from ai-title/custom-title
entries) and the message date.

Usage:
  bm25_any.py ~/.claude/projects/-Users-jeanlucthumm-nix "agent auth" -k 5
  bm25_any.py <dir> "query" --role user --since 2026-08-01
  bm25_any.py <dir> "query" --days 30 --context 2
  bm25_any.py <dir> "query" --stats
"""
import argparse
import datetime
import json
import math
import re
from pathlib import Path

TOKEN_RE = re.compile(r"[a-z0-9_]+")
H2_RE = re.compile(r"(?m)^(##\s+.*)$")
# Injected spans stripped from message text before indexing.
STRIP_SPAN_RE = re.compile(
    r"<system-reminder>.*?</system-reminder>"
    r"|<task-notification>.*?</task-notification>"
    r"|<local-command-stdout>.*?</local-command-stdout>",
    re.S,
)
# Messages that are entirely harness plumbing, not conversation.
SKIP_MSG_RE = re.compile(
    r"^\s*(Caveat: The messages below|<command-message>|<command-name>|<local-command-stdout>)"
)


def tokenize(text):
    return TOKEN_RE.findall(text.lower())


def clean_message_text(entry):
    """Return searchable text for a transcript entry, or None to skip it."""
    if entry.get("isMeta"):
        return None
    etype = entry.get("type")
    if etype == "summary":  # compaction summaries carry a useful one-liner
        return entry.get("summary") or None
    if etype not in ("user", "assistant"):
        return None
    msg = entry.get("message") or {}
    content = msg.get("content")
    if isinstance(content, str):
        text = content
    elif isinstance(content, list):
        text = "\n".join(
            b.get("text", "")
            for b in content
            if isinstance(b, dict) and b.get("type") == "text"
        )
    else:
        return None
    if SKIP_MSG_RE.match(text):
        return None
    text = STRIP_SPAN_RE.sub("", text).strip()
    return text or None


def load_markdown(path, name, docs):
    content = path.read_text(encoding="utf-8")
    parts = H2_RE.split(content)  # [pre, head1, body1, head2, body2, ...]
    if parts[0].strip():
        docs.append({"label": f"{name} :: (intro)", "path": path, "text": parts[0]})
    for i in range(1, len(parts), 2):
        head = parts[i].strip().lstrip("#").strip()
        body = parts[i + 1] if i + 1 < len(parts) else ""
        docs.append({"label": f"{name} :: {head}", "path": path,
                     "text": parts[i] + "\n" + body})


def load_transcript(path, name, docs, seen_uuids, seen_texts, stats, titles):
    title = None
    file_docs = []
    with path.open(encoding="utf-8") as f:
        for lineno, line in enumerate(f, 1):
            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                continue
            etype = entry.get("type")
            if etype == "custom-title":
                title = entry.get("customTitle") or title
                continue
            if etype == "ai-title":
                # custom titles win over generated ones
                title = title or entry.get("aiTitle")
                continue
            text = clean_message_text(entry)
            if not text:
                continue
            uuid = entry.get("uuid")
            if uuid and uuid in seen_uuids:
                stats["dup_uuid"] += 1
                continue
            norm = hash(re.sub(r"\s+", " ", text.lower()))
            if norm in seen_texts:
                stats["dup_text"] += 1
                continue
            if uuid:
                seen_uuids.add(uuid)
            seen_texts.add(norm)
            file_docs.append({
                "path": path,
                "text": text,
                "lineno": lineno,
                "role": "summary" if etype == "summary" else etype,
                "ts": (entry.get("timestamp") or "")[:10],
            })
    if title:
        titles[path.stem] = title
    for pos, d in enumerate(file_docs):
        d["name"] = str(name)
        d["pos"] = pos  # position among kept docs, for --context
        d["siblings"] = file_docs
        docs.append(d)


def load_docs(folder, stats):
    docs = []
    seen_uuids, seen_texts = set(), set()
    titles = {}  # session id -> title
    root = Path(folder).expanduser().resolve()
    for path in sorted(root.rglob("*")):
        if path.suffix == ".md":
            load_markdown(path, path.relative_to(root), docs)
            stats["md_files"] += 1
        elif path.suffix == ".jsonl":
            load_transcript(path, path.relative_to(root), docs,
                            seen_uuids, seen_texts, stats, titles)
            stats["jsonl_files"] += 1
    # label transcript docs; subagent files inherit the parent session's title
    for d in docs:
        if "name" not in d:
            continue
        session = d["name"].split("/", 1)[0].removesuffix(".jsonl")
        title = titles.get(session)
        head = d["name"] + (f" [{title}]" if title else "")
        d["label"] = f"{head}:{d['lineno']} ({d['role']})"
    return docs


def build_index(docs, k1=1.5, b=0.75):
    toks = [tokenize(d["text"]) for d in docs]
    n = len(toks) or 1
    lengths = [len(t) for t in toks]
    avgdl = (sum(lengths) / n) if lengths else 0.0
    df = {}
    for t in toks:
        for w in set(t):
            df[w] = df.get(w, 0) + 1
    idf = {w: math.log(1 + (n - c + 0.5) / (c + 0.5)) for w, c in df.items()}
    tf = []
    for t in toks:
        d = {}
        for w in t:
            d[w] = d.get(w, 0) + 1
        tf.append(d)
    return tf, lengths, avgdl, idf, k1, b


def score_all(query, index):
    tf, lengths, avgdl, idf, k1, b = index
    q = tokenize(query)
    scores = []
    for i, freqs in enumerate(tf):
        s = 0.0
        for w in q:
            f = freqs.get(w)
            if f:
                denom = f + k1 * (1 - b + b * (lengths[i] / avgdl if avgdl else 0))
                s += idf.get(w, 0.0) * (f * (k1 + 1)) / denom
        scores.append(s)
    return scores


def snippet(text, query, width=260):
    """Window around the densest cluster of query-term matches."""
    qset = set(tokenize(query))
    positions = [m.start() for m in re.finditer(r"\w+", text)
                 if m.group().lower() in qset]
    if not positions:
        start = 0
    else:
        best_start, best_count = positions[0], 1
        for i, p in enumerate(positions):
            count = sum(1 for q2 in positions[i:] if q2 < p + width)
            if count > best_count:
                best_start, best_count = p, count
        start = max(0, best_start - 50)
    return re.sub(r"\s+", " ", text[start:start + width]).strip()


def print_context(doc, n):
    sibs = doc.get("siblings")
    if not sibs:
        return
    pos = doc["pos"]
    for d in sibs[max(0, pos - n):pos + n + 1]:
        marker = ">>" if d["pos"] == pos else "  "
        body = re.sub(r"\s+", " ", d["text"])[:200]
        print(f"      {marker} [{d['role']}] {body}")


def main():
    ap = argparse.ArgumentParser(
        description="BM25 search over Markdown files and Claude Code transcripts")
    ap.add_argument("directory", type=Path, help="directory to search recursively")
    ap.add_argument("query")
    ap.add_argument("-k", type=int, default=8, help="number of results")
    ap.add_argument("--full", action="store_true",
                    help="print full section/message text, not a snippet")
    ap.add_argument("--role", choices=["user", "assistant", "summary"],
                    help="only match transcript messages with this role")
    ap.add_argument("--since", help="only messages on/after this date (YYYY-MM-DD)")
    ap.add_argument("--days", type=int, help="only messages from the last N days")
    ap.add_argument("--context", type=int, default=0, metavar="N",
                    help="print N surrounding messages for each transcript hit")
    ap.add_argument("--max-per-file", type=int, default=3, metavar="N",
                    help="max results per file for diversity (0 = unlimited)")
    ap.add_argument("--stats", action="store_true",
                    help="print corpus statistics after the results")
    args = ap.parse_args()

    if not args.directory.is_dir():
        ap.error(f"not a directory: {args.directory}")
    since = args.since
    if args.days is not None:
        cutoff = datetime.date.today() - datetime.timedelta(days=args.days)
        since = max(since or "", cutoff.isoformat())

    stats = {"md_files": 0, "jsonl_files": 0, "dup_uuid": 0, "dup_text": 0}
    docs = load_docs(args.directory, stats)
    if not docs:
        print(f"no .md or .jsonl content under {args.directory}")
        return
    if args.role:
        docs = [d for d in docs if d.get("role") == args.role]
    if since:
        docs = [d for d in docs if d.get("ts", "") >= since]
    if not docs:
        print("no documents left after filters")
        return

    index = build_index(docs)
    scores = score_all(args.query, index)
    # ties broken by recency (markdown docs have no ts and sort last on ties)
    ranked = sorted(range(len(docs)),
                    key=lambda i: (scores[i], docs[i].get("ts", "")), reverse=True)

    shown = 0
    per_file = {}
    for i in ranked:
        if scores[i] <= 0:
            break
        d = docs[i]
        if args.max_per_file:
            hits = per_file.get(d["path"], 0)
            if hits >= args.max_per_file:
                continue
            per_file[d["path"]] = hits + 1
        date = f"  {d['ts']}" if d.get("ts") else ""
        print(f"{scores[i]:6.2f}{date}  {d['label']}")
        if args.full:
            print(d["text"].strip())
            print("-" * 80)
        elif args.context:
            print_context(d, args.context)
        else:
            print(f"        {snippet(d['text'], args.query)}")
        shown += 1
        if shown >= args.k:
            break
    if shown == 0:
        print("no matches")

    if args.stats:
        print(f"\n[{stats['md_files']} md files, {stats['jsonl_files']} transcripts, "
              f"{len(docs)} docs indexed, {stats['dup_uuid']} uuid dups + "
              f"{stats['dup_text']} text dups skipped]")


if __name__ == "__main__":
    main()
