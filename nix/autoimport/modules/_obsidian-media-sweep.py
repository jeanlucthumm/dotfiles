"""Move Obsidian vault attachments to the blob store; leave URLs in notes.

Stop-gap link handling: wikilinks only (``[[x.pdf]]``, ``![[x.png|300]]``),
matched on basename, case-insensitive. When unsure, leave the file alone and
say so: an anchor, a markdown-style local link, a reference inside YAML
frontmatter, a basename that is not unique in the vault, or any mention of
the filename the wikilink parser did not account for. The proper rewrite will
come from the headless vault CLI; the seam is Index.refs()/rewrite().

Order per file: copy and verify, then rewrite notes (or, when nothing
references it, leave a same-named ``<file>.md`` stub holding the link where
the file was), then delete the vault copy. A failure on one file is logged
and the run moves on; the next run retries and the store dedupes by hash.
"""
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import time
import urllib.parse
from collections import Counter, defaultdict
from pathlib import Path

IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".svg", ".bmp"}
OTHER_EXTS = {".m4a", ".mp3", ".wav", ".ogg", ".flac", ".webm", ".mp4",
              ".mov", ".mkv", ".pdf"}
MEDIA_EXTS = IMAGE_EXTS | OTHER_EXTS

# [[target#anchor|alias]] with optional leading "!". Target may carry a path.
WIKILINK = re.compile(r"(!?)\[\[([^\]|#]+)(#[^\]|]*)?(\|[^\]]*)?\]\]")
# ](target) of a markdown-style link; detected only, never rewritten.
MDLINK = re.compile(r"\]\(([^)\s]+)\)")
FRONTMATTER = re.compile(r"\A---\r?\n.*?\r?\n---\r?\n", re.S)


def log(msg):
    print(msg, flush=True)


def iter_files(vault):
    for root, dirs, files in os.walk(vault):
        dirs[:] = sorted(d for d in dirs if not d.startswith("."))
        for f in sorted(files):
            yield Path(root) / f


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def read(path):
    # newline="" keeps CRLF notes CRLF; surrogateescape round-trips odd bytes.
    with open(path, encoding="utf-8", errors="surrogateescape",
              newline="") as fh:
        return fh.read()


def write_atomic(path, text):
    # Syncthing ignores its own temp pattern (.syncthing.*.tmp); borrow it so
    # the half-written file never syncs. ".sweep" keeps us clear of its names.
    tmp = path.with_name(f".syncthing.{path.name}.sweep.tmp")
    with open(tmp, "w", encoding="utf-8", errors="surrogateescape",
              newline="") as fh:
        fh.write(text)
    if path.exists():
        shutil.copymode(path, tmp)
    os.replace(tmp, path)


def basename_key(target):
    # Obsidian escapes a pipe inside tables as "\|"; the backslash lands on
    # the target side of our split.
    target = urllib.parse.unquote(target).rstrip("\\")
    return target.split("/")[-1].strip().lower()


class Index:
    """Which notes mention which attachment basenames, and how."""

    def __init__(self, notes):
        self.wiki = defaultdict(set)   # key -> notes with rewritable refs
        self.other = defaultdict(set)  # key -> notes with refs we won't touch
        self.texts = {}                # note -> lowercased text
        for note in notes:
            text = read(note)
            self.texts[note] = text.lower()
            fm = FRONTMATTER.match(text)
            fm_end = fm.end() if fm else 0
            for m in WIKILINK.finditer(text):
                key = basename_key(m.group(2))
                unsafe = m.group(3) or m.start() < fm_end
                (self.other if unsafe else self.wiki)[key].add(note)
            for m in MDLINK.finditer(text):
                if "://" not in m.group(1):
                    self.other[basename_key(m.group(1))].add(note)

    def refs(self, key):
        return self.wiki.get(key, set())

    def unrewritable(self, key):
        """Notes that mention the name in any form we would not rewrite."""
        parsed = self.wiki.get(key, set())
        mentioned = {n for n, t in self.texts.items()
                     if key in t and n.name.lower() != key + ".md"}  # our stub
        return self.other.get(key, set()) | (mentioned - parsed)


def store_name(path, digest):
    stem = re.sub(r"[^A-Za-z0-9._-]+", "-", path.stem).strip("-") or "file"
    return f"{stem}-{digest[:8]}{path.suffix.lower()}"


def store(src, dest, digest, dry_run):
    if dest.exists():
        if sha256(dest) == digest:
            log(f"  {dest.name} already in store (earlier run?)")
            return
        raise RuntimeError(f"{dest} exists with different content")
    if dry_run:
        return
    tmp = dest.with_name(dest.name + ".part")
    shutil.copyfile(src, tmp)
    if sha256(tmp) != digest:
        tmp.unlink()
        raise RuntimeError(f"copy of {src} failed verification")
    os.chmod(tmp, 0o644)
    os.replace(tmp, dest)


def rewrite(text, key, url, is_image, name):
    def sub(m):
        bang, target, anchor, alias = m.groups()
        if basename_key(target) != key:
            return m.group(0)
        alias = alias[1:] if alias else ""
        if bang and is_image:
            return f"![{alias}]({url})"  # Obsidian renders external images
        return f"[{alias or name}]({url})"  # everything else is a plain link
    return WIKILINK.sub(sub, text)


def stub_text(name, url, is_image):
    return (f"![{name}]({url})\n" if is_image else f"[{name}]({url})\n")


def default_url_prefix():
    out = subprocess.run(["tailscale", "status", "--json"],
                         capture_output=True, text=True, check=True).stdout
    dns = json.loads(out)["Self"]["DNSName"].rstrip(".")
    return f"https://{dns}/media"


def sweep_one(src, vault, store_dir, prefix, index, dry_run):
    """Returns True if the file was (or would be) moved."""
    rel = src.relative_to(vault)
    key = src.name.lower()
    bad = index.unrewritable(key)
    if bad:
        names = ", ".join(sorted(str(n.relative_to(vault)) for n in bad))
        log(f"SKIP {rel}: reference I cannot rewrite in {names}")
        return False
    refs = index.refs(key)
    digest = sha256(src)
    dest = store_dir / store_name(src, digest)
    url = f"{prefix}/{urllib.parse.quote(dest.name)}"
    is_image = src.suffix.lower() in IMAGE_EXTS
    stub = src.with_name(src.name + ".md")
    text = stub_text(src.name, url, is_image)
    if not refs and stub.exists() and read(stub) != text:
        log(f"SKIP {rel}: {stub.name} exists and is not our stub")
        return False
    where = f"rewrite {len(refs)} note(s)" if refs else f"stub {stub.name}"
    verb = "WOULD move" if dry_run else "move"
    log(f"{verb} {rel} -> {dest.name} ({where})")
    store(src, dest, digest, dry_run)
    if dry_run:
        return True
    if refs:
        for note in sorted(refs):
            write_atomic(note, rewrite(read(note), key, url, is_image,
                                       src.name))
    else:
        write_atomic(stub, text)
    os.remove(src)
    return True


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--vault", required=True)
    ap.add_argument("--store", required=True)
    ap.add_argument("--url-prefix",
                    help="default: https://<this node's MagicDNS name>/media")
    ap.add_argument("--quiet-minutes", type=float, default=10)
    ap.add_argument("--limit", type=int, default=0,
                    help="stop after moving this many files (0 = no limit)")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--allow-unmounted", action="store_true",
                    help="skip the mountpoint check (tests)")
    args = ap.parse_args()

    vault, store_dir = Path(args.vault), Path(args.store)
    if not store_dir.is_dir():
        sys.exit(f"store {store_dir} is not a directory")
    if not args.allow_unmounted and not os.path.ismount(store_dir):
        sys.exit(f"store {store_dir} is not a mountpoint; pool not unlocked?")
    prefix = (args.url_prefix or default_url_prefix()).rstrip("/")
    quiet_before = time.time() - args.quiet_minutes * 60

    files = list(iter_files(vault))
    notes = [p for p in files if p.suffix.lower() == ".md"]
    media = [p for p in files if p.suffix.lower() in MEDIA_EXTS]
    dupes = Counter(p.name.lower() for p in media)
    # An unreadable note means unknown references: refuse the whole run.
    index = Index(notes)
    # Snapshot before writing: our own rewrites are not human edits. A file
    # Syncthing removed since the walk is simply not this run's business.
    mtime = {}
    for p in notes + media:
        try:
            mtime[p] = p.stat().st_mtime
        except FileNotFoundError:
            pass

    moved = skipped = waiting = failed = 0
    for src in media:
        if src not in mtime:
            continue
        key = src.name.lower()
        if mtime[src] > quiet_before:
            waiting += 1
            continue
        if dupes[key] > 1:
            log(f"SKIP {src.relative_to(vault)}: basename not unique in vault")
            skipped += 1
            continue
        if any(mtime.get(n, time.time()) > quiet_before
               for n in index.refs(key)):
            waiting += 1
            continue
        try:
            if sweep_one(src, vault, store_dir, prefix, index, args.dry_run):
                moved += 1
            else:
                skipped += 1
        except Exception as e:  # one bad file must not block the rest
            log(f"ERROR {src.relative_to(vault)}: {e}")
            failed += 1
        if args.limit and moved >= args.limit:
            log(f"limit {args.limit} reached")
            break

    log(f"done: {moved} {'would move' if args.dry_run else 'moved'}, "
        f"{skipped} skipped, {failed} failed, {waiting} inside quiet period, "
        f"{len(media)} media files seen")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
