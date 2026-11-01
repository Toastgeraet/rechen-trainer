"""Serve the exported Web build for local testing.

    python tools/serve_web.py [port] [directory]

Godot's web build is fussier than a plain static site, so this adds what
`python -m http.server` gets wrong:

* `application/wasm` for `.wasm` -- browsers refuse to stream-compile without it.
* COOP/COEP headers, which cross-origin isolation (and therefore
  SharedArrayBuffer) require. Only strictly needed when the export has
  `variant/thread_support` enabled, but harmless otherwise.
* `Cache-Control: no-store`, so a re-export shows up on reload instead of
  serving a stale `.wasm` out of the browser cache.
"""
import functools
import http.server
import sys

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8060
DIRECTORY = sys.argv[2] if len(sys.argv) > 2 else "build/web"


class GodotWebHandler(http.server.SimpleHTTPRequestHandler):
	# HTTP/1.1 keeps connections alive, which matters when streaming a ~38 MB
	# .wasm. Safe only because the server below is threaded.
	protocol_version = "HTTP/1.1"

	extensions_map = {
		**http.server.SimpleHTTPRequestHandler.extensions_map,
		".wasm": "application/wasm",
	}

	def end_headers(self) -> None:
		self.send_header("Cross-Origin-Opener-Policy", "same-origin")
		self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
		self.send_header("Cache-Control", "no-store")
		super().end_headers()


class Server(http.server.ThreadingHTTPServer):
	# Threaded, or the browser's parallel + keep-alive connections deadlock a
	# single-threaded server and the page hangs on a blank canvas.
	allow_reuse_address = True
	daemon_threads = True


def main() -> None:
	handler = functools.partial(GodotWebHandler, directory=DIRECTORY)
	with Server(("127.0.0.1", PORT), handler) as httpd:
		print("Serving %s at http://127.0.0.1:%d/" % (DIRECTORY, PORT))
		try:
			httpd.serve_forever()
		except KeyboardInterrupt:
			print("\nStopped.")


if __name__ == "__main__":
	main()
