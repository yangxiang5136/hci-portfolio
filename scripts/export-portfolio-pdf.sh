#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
chrome_bin="${PORTFOLIO_CHROME_BIN:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
port="${PORTFOLIO_PREVIEW_PORT:-$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1]); s.close()')}"
output_pdf="$project_dir/assets/portfolio.pdf"
server_log="$(mktemp /tmp/portfolio-pdf-server.XXXXXX.log)"
work_dir="$(mktemp -d /tmp/portfolio-pdf-work.XXXXXX)"
staged_pdf="$work_dir/portfolio.pdf"
render_timeout="${PORTFOLIO_RENDER_TIMEOUT:-180}"
chrome_pid=""

test -x "$chrome_bin" || {
  printf 'Chrome executable not found: %s\n' "$chrome_bin" >&2
  exit 2
}

python3 -m http.server "$port" --bind 127.0.0.1 --directory "$project_dir" >"$server_log" 2>&1 &
server_pid=$!
cleanup(){
  if [ -n "$chrome_pid" ]; then
    kill "$chrome_pid" 2>/dev/null || true
    wait "$chrome_pid" 2>/dev/null || true
  fi
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
  --no-first-run \
  --no-default-browser-check \
  --user-data-dir="$work_dir/chrome-profile" \
  --no-pdf-header-footer \
  --print-to-pdf="$staged_pdf" \
  "http://127.0.0.1:$port/portfolio-pdf.html" &
chrome_pid=$!

staged_size=0
stable_ticks=0
for _ in $(seq 1 "$render_timeout"); do
  if [ -f "$staged_pdf" ]; then
    current_size="$(wc -c <"$staged_pdf" | tr -d '[:space:]')"
    if [ "$current_size" -gt 0 ] && [ "$current_size" = "$staged_size" ]; then
      stable_ticks=$((stable_ticks + 1))
      [ "$stable_ticks" -ge 3 ] && break
    else
      stable_ticks=0
    fi
    staged_size="$current_size"
  fi
  kill -0 "$chrome_pid" 2>/dev/null || break
  sleep 1
done

kill "$chrome_pid" 2>/dev/null || true
wait "$chrome_pid" 2>/dev/null || true
chrome_pid=""

test -s "$staged_pdf" || {
  printf 'Chrome wrote no PDF within %ss: %s\n' "$render_timeout" "$staged_pdf" >&2
  exit 3
}

head -c 5 "$staged_pdf" | grep -q '^%PDF-' || {
  printf 'Chrome produced a file that is not a PDF: %s\n' "$staged_pdf" >&2
  exit 3
}

expected_pages="$({ grep -oE 'class="page( [^"]*)?"' "$project_dir/portfolio-pdf.html" || true; } | wc -l | tr -d '[:space:]')"

test "$expected_pages" -ge 1 || {
  printf 'Found no page sections in %s; the page markup or class naming changed\n' \
    "$project_dir/portfolio-pdf.html" >&2
  exit 3
}

actual_pages="$(python3 - "$staged_pdf" <<'PY'
import re, sys, zlib

data = open(sys.argv[1], "rb").read()
pattern = re.compile(rb"/Type\s*/Page(?![a-zA-Z])")
count = len(pattern.findall(data))

if count == 0:
    for match in re.finditer(rb"stream\r?\n", data):
        start = match.end()
        end = data.find(b"endstream", start)
        if end == -1:
            continue
        try:
            count += len(pattern.findall(zlib.decompress(data[start:end])))
        except zlib.error:
            continue

print(count)
PY
)"

test "$actual_pages" -eq "$expected_pages" || {
  printf 'Rendered PDF has %s page(s) but portfolio-pdf.html declares %s; refusing to replace %s\n' \
    "$actual_pages" "$expected_pages" "$output_pdf" >&2
  exit 3
}

mv "$staged_pdf" "$output_pdf"

printf 'Exported %s (%s pages, %s bytes)\n' \
  "$output_pdf" "$actual_pages" "$(wc -c <"$output_pdf" | tr -d ' ')"
