#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
chrome_bin="${PORTFOLIO_CHROME_BIN:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
port="${PORTFOLIO_PREVIEW_PORT:-$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1]); s.close()')}"
output_pdf="$project_dir/assets/portfolio.pdf"
server_log="$(mktemp /tmp/portfolio-pdf-server.XXXXXX.log)"
work_dir="$(mktemp -d /tmp/portfolio-pdf-work.XXXXXX)"
staged_pdf="$work_dir/portfolio.pdf"

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
  rm -rf "$work_dir"
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
  --print-to-pdf="$staged_pdf" \
  "http://127.0.0.1:$port/portfolio-pdf.html"

test -s "$staged_pdf" || {
  printf 'Chrome exited without writing a PDF: %s\n' "$staged_pdf" >&2
  exit 3
}

head -c 5 "$staged_pdf" | grep -q '^%PDF-' || {
  printf 'Chrome produced a file that is not a PDF: %s\n' "$staged_pdf" >&2
  exit 3
}

expected_pages="$(grep -coE 'class="page( [^"]*)?"' "$project_dir/portfolio-pdf.html")"
actual_pages="$(python3 -c '
import re, sys
data = open(sys.argv[1], "rb").read()
print(len(re.findall(rb"/Type\s*/Page[^s]", data)))
' "$staged_pdf")"

test "$actual_pages" = "$expected_pages" || {
  printf 'Rendered PDF has %s page(s) but portfolio-pdf.html declares %s; refusing to replace %s\n' \
    "$actual_pages" "$expected_pages" "$output_pdf" >&2
  exit 3
}

mv "$staged_pdf" "$output_pdf"

printf 'Exported %s (%s pages, %s bytes)\n' \
  "$output_pdf" "$actual_pages" "$(wc -c <"$output_pdf" | tr -d ' ')"
