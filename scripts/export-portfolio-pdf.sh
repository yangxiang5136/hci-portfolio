#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
chrome_bin="${PORTFOLIO_CHROME_BIN:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
port="${PORTFOLIO_PREVIEW_PORT:-$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1]); s.close()')}"
output_pdf="$project_dir/assets/portfolio.pdf"
server_log="$(mktemp /tmp/portfolio-pdf-server.XXXXXX.log)"

test -x "$chrome_bin" || {
  printf 'Chrome executable not found: %s\n' "$chrome_bin" >&2
  exit 2
}

python3 -m http.server "$port" --bind 127.0.0.1 --directory "$project_dir" >"$server_log" 2>&1 &
server_pid=$!
cleanup(){
  kill "$server_pid" 2>/dev/null || true
  wait "$server_pid" 2>/dev/null || true
  rm -f "$server_log"
}
trap cleanup EXIT

for _ in {1..30}; do
  curl -fsS "http://127.0.0.1:$port/portfolio-pdf.html" >/dev/null 2>&1 && break
  sleep 0.1
done

curl -fsS "http://127.0.0.1:$port/portfolio-pdf.html" >/dev/null
"$chrome_bin" \
  --headless=new \
  --disable-gpu \
  --no-pdf-header-footer \
  --print-to-pdf="$output_pdf" \
  "http://127.0.0.1:$port/portfolio-pdf.html"

printf 'Exported %s\n' "$output_pdf"
