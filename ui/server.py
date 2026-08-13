#!/usr/bin/env python3
"""Serves the static UI and exposes POST /trigger-cre to run the CRE workflow.
Bound to 127.0.0.1 only: the trigger endpoint broadcasts gas-spending txs to Sepolia."""
import json
import os
import subprocess
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

UI_DIR = os.path.dirname(os.path.abspath(__file__))
CRE_DIR = os.path.abspath(os.path.join(UI_DIR, "..", "sample-cre-pricefeeds-por", "aws-oracle-cre"))


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=UI_DIR, **kwargs)

    def do_POST(self):
        if self.path != "/trigger-cre":
            self.send_error(404)
            return
        try:
            proc = subprocess.run(
                ["bash", "run-simulation.sh"],
                cwd=CRE_DIR, capture_output=True, text=True, timeout=300,
            )
            body = {"ok": proc.returncode == 0, "output": (proc.stdout + proc.stderr)[-4000:]}
        except subprocess.TimeoutExpired:
            body = {"ok": False, "output": "CRE run timed out after 300s"}
        payload = json.dumps(body).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)


if __name__ == "__main__":
    print("Serving UI + CRE trigger at http://localhost:3000")
    ThreadingHTTPServer(("127.0.0.1", 3000), Handler).serve_forever()
