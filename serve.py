"""
Local server for Godot 4 HTML5 export.
Sets COOP/COEP headers required for SharedArrayBuffer (Godot threads).

Usage:
    python serve.py
Then open:  http://localhost:8080
"""
import http.server
import socketserver
import os

EXPORT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "export")
PORT = 8080

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=EXPORT_DIR, **kwargs)

    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        super().end_headers()

    def log_message(self, fmt, *args):
        pass  # silence request spam

with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print(f"Serving Godot export at http://localhost:{PORT}")
    print("Press Ctrl+C to stop.")
    httpd.serve_forever()
