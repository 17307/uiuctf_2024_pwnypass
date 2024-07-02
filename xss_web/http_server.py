from http.server import HTTPServer, BaseHTTPRequestHandler
import urllib
from os import curdir


known = "1"


class RedirectHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        global known
        parsed = urllib.parse.urlparse(self.path)
        query = urllib.parse.parse_qs(parsed.query)
        if parsed.path == "/":
            if len(query) == 0:
                self.send_response(302)
                self.send_header("Location", f"/?known={known}")
                self.end_headers()
                return
            f = open("index.html", "rb")
            self.send_response(200)
            self.end_headers()
            self.wfile.write(f.read())
            return

        if "c" in query and len(query["c"][0]) > len(known):
            known = query["c"][0]
        self.send_response(404)
        self.end_headers()


def run(
    server_class=HTTPServer, handler_class=RedirectHandler, addr="localhost", port=9911
):
    server_address = (addr, port)
    httpd = server_class(server_address, handler_class)
    print(f"Starting HTTP server on {addr}:{port}")
    httpd.serve_forever()


if __name__ == "__main__":
    run()
