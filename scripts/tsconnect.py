#!/usr/bin/env python3
"""ProxyCommand helper: CONNECT to a tailnet host:port through a proxy.

Used by ssh as its ProxyCommand for the reverse SSH from the Muse VM to
your laptop. Normal programs on this VM cannot reach the tailnet
directly; TCP traffic has to ride an HTTP CONNECT proxy (port 3130 on the
author's runtime).

Configuration, all through environment variables:
  TSCONNECT_PROXY_HOST  proxy hostname (default: taken from HTTPS_PROXY)
  TSCONNECT_PROXY_PORT  proxy port     (default: 3130)
  TSCONNECT_PROXY_URL   full proxy URL, e.g. http://user:pass@host:port
                        (default: the HTTPS_PROXY environment variable,
                        with its port replaced by TSCONNECT_PROXY_PORT)

Proxy credentials are read from the environment only. They are never
printed and never written to disk.

Usage: tsconnect.py <host> <port>

NOTE: in the author's sandbox, outbound traffic to the tailnet goes
through the runtime's egress proxy — set the variables above to whatever
proxy YOUR runtime provides. On a machine with native Tailscale routing
you do not need this helper at all; drop the ProxyCommand option instead.
"""
import base64
import os
import socket
import sys
import threading
import urllib.parse


def _proxy_settings():
    url = os.environ.get("TSCONNECT_PROXY_URL") or os.environ.get("HTTPS_PROXY", "")
    parsed = urllib.parse.urlparse(url)
    host = os.environ.get("TSCONNECT_PROXY_HOST") or parsed.hostname
    port = int(os.environ.get("TSCONNECT_PROXY_PORT") or 3130)
    user = parsed.username
    password = parsed.password or ""
    if os.environ.get("TSCONNECT_PROXY_URL"):
        # When a full URL is given, its own port wins unless overridden.
        url_port = urllib.parse.urlparse(os.environ["TSCONNECT_PROXY_URL"]).port
        if url_port and not os.environ.get("TSCONNECT_PROXY_PORT"):
            port = url_port
    return host, port, user, password


def main() -> int:
    target_host, target_port = sys.argv[1], int(sys.argv[2])
    proxy_host, proxy_port, proxy_user, proxy_pass = _proxy_settings()
    if not proxy_host:
        print("proxy host is not configured (set TSCONNECT_PROXY_HOST or HTTPS_PROXY)",
              file=sys.stderr)
        return 1

    s = socket.create_connection((proxy_host, proxy_port), timeout=30)
    headers = [
        f"CONNECT {target_host}:{target_port} HTTP/1.1",
        f"Host: {target_host}:{target_port}",
    ]
    if proxy_user:
        token = base64.b64encode(f"{proxy_user}:{proxy_pass}".encode()).decode()
        headers.append(f"Proxy-Authorization: Basic {token}")
    s.sendall(("\r\n".join(headers) + "\r\n\r\n").encode())

    buf = b""
    while b"\r\n\r\n" not in buf:
        chunk = s.recv(4096)
        if not chunk:
            print("proxy closed the connection before CONNECT finished", file=sys.stderr)
            return 1
        buf += chunk
    head, rest = buf.split(b"\r\n\r\n", 1)
    if b" 200 " not in head.split(b"\r\n")[0]:
        print("CONNECT refused by the proxy", file=sys.stderr)
        return 1

    stdin = sys.stdin.buffer
    stdout = sys.stdout.buffer
    if rest:
        stdout.write(rest)
        stdout.flush()

    def pump_stdin() -> None:
        try:
            while True:
                data = stdin.read1(65536) if hasattr(stdin, "read1") else stdin.read(65536)
                if not data:
                    break
                s.sendall(data)
        except OSError:
            pass
        try:
            s.shutdown(socket.SHUT_WR)
        except OSError:
            pass

    threading.Thread(target=pump_stdin, daemon=True).start()
    try:
        while True:
            data = s.recv(65536)
            if not data:
                break
            stdout.write(data)
            stdout.flush()
    except OSError:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
