#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
chrome_bin="${PORTFOLIO_CHROME_BIN:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
port="${PORTFOLIO_PREVIEW_PORT:-$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1]); s.close()')}"
output_pdf="$project_dir/assets/portfolio.pdf"
work_dir="$(mktemp -d /tmp/portfolio-pdf-work.XXXXXX)"
server_log="$work_dir/server.log"
staged_pdf="$work_dir/portfolio.pdf"
render_timeout="${PORTFOLIO_RENDER_TIMEOUT:-180}"
chrome_pid=""

test -x "$chrome_bin" || {
  printf 'Chrome executable not found: %s\n' "$chrome_bin" >&2
  exit 2
}

[[ "$render_timeout" =~ ^[1-9][0-9]*$ ]] || {
  printf 'PORTFOLIO_RENDER_TIMEOUT must be a positive integer of seconds (got: %s)\n' \
    "$render_timeout" >&2
  exit 2
}

expected_pages="$({ grep -oE 'class="page( [^"]*)?"' "$project_dir/portfolio-pdf.html" || true; } | wc -l | tr -d '[:space:]')"

test "$expected_pages" -ge 1 || {
  printf 'Found no page sections in %s; the page markup or class naming changed\n' \
    "$project_dir/portfolio-pdf.html" >&2
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
  rm -rf "$work_dir"
}
trap cleanup EXIT

validator="$work_dir/validate-pdf.py"
cat >"$validator" <<'PY'
import re, sys, zlib

try:
    data = open(sys.argv[1], "rb").read()
except OSError:
    sys.exit(1)

if not data:
    sys.exit(1)
if not data.startswith(b"%PDF-"):
    sys.exit(2)
if not data.rstrip(b"\r\n \t\x00").endswith(b"%%EOF"):
    sys.exit(3)

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

chrome_exited=0
chrome_status=0
for _ in $(seq 1 "$render_timeout"); do
  if staged_pages="$(python3 "$validator" "$staged_pdf" 2>/dev/null)" \
    && [ "$staged_pages" -eq "$expected_pages" ]; then
    break
  fi
  if ! kill -0 "$chrome_pid" 2>/dev/null; then
    chrome_exited=1
    wait "$chrome_pid" && chrome_status=0 || chrome_status=$?
    chrome_pid=""
    break
  fi
  sleep 1
done

if [ -n "$chrome_pid" ]; then
  kill "$chrome_pid" 2>/dev/null || true
  wait "$chrome_pid" 2>/dev/null || true
  chrome_pid=""
fi

validation_status=0
actual_pages="$(python3 "$validator" "$staged_pdf")" || validation_status=$?

case "$validation_status" in
  0) ;;
  1)
    if [ "$chrome_exited" -eq 1 ]; then
      printf 'Chrome exited with status %s before writing a PDF: %s\n' \
        "$chrome_status" "$staged_pdf" >&2
    else
      printf 'Chrome wrote no PDF within %ss: %s\n' "$render_timeout" "$staged_pdf" >&2
    fi
    exit 3
    ;;
  2)
    printf 'Chrome produced a file that is not a PDF: %s\n' "$staged_pdf" >&2
    exit 3
    ;;
  3)
    printf 'Rendered PDF is truncated (no %%%%EOF trailer); refusing to replace %s\n' \
      "$output_pdf" >&2
    exit 3
    ;;
  *)
    printf 'PDF validation failed with status %s: %s\n' "$validation_status" "$staged_pdf" >&2
    exit 3
    ;;
esac

test "$actual_pages" -eq "$expected_pages" || {
  printf 'Rendered PDF has %s page(s) but portfolio-pdf.html declares %s; refusing to replace %s\n' \
    "$actual_pages" "$expected_pages" "$output_pdf" >&2
  exit 3
}

mv "$staged_pdf" "$output_pdf"

printf 'Exported %s (%s pages, %s bytes)\n' \
  "$output_pdf" "$actual_pages" "$(wc -c <"$output_pdf" | tr -d ' ')"
