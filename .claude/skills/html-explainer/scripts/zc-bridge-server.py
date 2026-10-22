#!/usr/bin/env python3
"""Local relay for live comments in any browser.

Usage: zc-bridge-server.py [port]   (default 47321)

terminal-browser's live mode reaches the page's zcLive hooks over CDP. A plain
browser has no such door, so the page (assets/zc-bridge.js) talks to this relay
instead: it pushes drained comments here and pulls queued answers. The session
drains comments with scripts/zc-bridge-watch.sh and answers with
scripts/zc-bridge-reply.sh. Queues are in memory; nothing is written to disk.

Only file:// pages (Origin: null) and non-browser clients (no Origin) are
served, so a website open in the same browser can neither read the answers nor
plant comments for the session.
"""
import json
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 47321
LIVE_S = 8  # same window the page uses to decide it is live

lock = threading.Lock()
inbox = []   # comments from the page, waiting for the session
outbox = []  # answers and reloads from the session, waiting for the page
seen = {'session': 0.0, 'page': 0.0}


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def allowed(self):
        return self.headers.get('Origin') in (None, 'null')

    def reply(self, code, obj=None):
        body = json.dumps(obj).encode() if obj is not None else b''
        self.send_response(code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', 'null')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST')
        self.send_header('Cache-Control', 'no-store')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.reply(204 if self.allowed() else 403)

    def do_GET(self):
        if not self.allowed():
            return self.reply(403)
        now = time.time()
        with lock:
            if self.path.startswith('/page/poll'):
                seen['page'] = now
                out = outbox[:]
                outbox.clear()
                return self.reply(200, {'watching': now - seen['session'] < LIVE_S, 'out': out})
            if self.path.startswith('/session/drain'):
                seen['session'] = now
                items = inbox[:]
                inbox.clear()
                return self.reply(200, {'pageSeen': now - seen['page'] < LIVE_S, 'items': items})
        self.reply(404)

    def do_POST(self):
        if not self.allowed():
            return self.reply(403)
        try:
            n = int(self.headers.get('Content-Length') or 0)
            data = json.loads(self.rfile.read(n) or b'null')
        except ValueError:
            return self.reply(400)
        with lock:
            if self.path == '/page/comments' and isinstance(data, list):
                inbox.extend(data)
                return self.reply(200, {})
            if self.path == '/session/answer' and isinstance(data, dict) and 'n' in data:
                outbox.append({'answer': data})
                return self.reply(200, {})
            if self.path == '/session/reload':
                outbox.append({'reload': True})
                return self.reply(200, {})
        self.reply(404)


if __name__ == '__main__':
    ThreadingHTTPServer(('127.0.0.1', PORT), Handler).serve_forever()
