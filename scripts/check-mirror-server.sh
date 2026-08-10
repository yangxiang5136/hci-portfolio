#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
mirror_port=${MIRROR_TEST_PORT:-4189}
mirror_url="http://127.0.0.1:${mirror_port}"
mirror_tmp=$(mktemp -d)
mirror_pid=""

cleanup() {
  if [[ -n "$mirror_pid" ]] && kill -0 "$mirror_pid" 2>/dev/null; then
    kill "$mirror_pid"
    wait "$mirror_pid" 2>/dev/null || true
  fi
  rm -rf "$mirror_tmp"
}
trap cleanup EXIT

cd "$repo_dir"
HOST=127.0.0.1 PORT="$mirror_port" node scripts/serve-sites-preview.mjs >"$mirror_tmp/server.log" 2>&1 &
mirror_pid=$!

for _ in {1..50}; do
  if curl -fsS "$mirror_url/" >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done
curl -fsS "$mirror_url/" >/dev/null || {
  cat "$mirror_tmp/server.log" >&2
  exit 1
}

SKIP_EXTERNAL_LINKS="${SKIP_EXTERNAL_LINKS:-1}" bash scripts/check-sites-routes.sh "$mirror_url"

video_path=/assets/synthetic-observatory-18s.mp4
curl -fsSI "$mirror_url$video_path" >"$mirror_tmp/head.txt"
grep -qi '^accept-ranges: bytes' "$mirror_tmp/head.txt"
grep -qi '^cache-control: public, max-age=86400, stale-while-revalidate=604800' "$mirror_tmp/head.txt"
grep -qi '^etag: ' "$mirror_tmp/head.txt"
grep -qi '^last-modified: ' "$mirror_tmp/head.txt"

range_status=$(curl -sS -o "$mirror_tmp/range.bin" -D "$mirror_tmp/range.txt" -w '%{http_code}' -H 'Range: bytes=0-1023' "$mirror_url$video_path")
[[ "$range_status" == 206 ]]
[[ $(wc -c <"$mirror_tmp/range.bin" | tr -d ' ') == 1024 ]]
grep -qi '^content-range: bytes 0-1023/' "$mirror_tmp/range.txt"

invalid_status=$(curl -sS -o /dev/null -w '%{http_code}' -H 'Range: bytes=999999999-' "$mirror_url$video_path")
[[ "$invalid_status" == 416 ]]

video_size=$(awk 'BEGIN{IGNORECASE=1} /^content-length:/{sub(/\r$/,""); print substr($0,index($0,":")+2)}' "$mirror_tmp/head.txt" | tr -d ' \r')

# Unsupported or unparsable Range headers are ignored, not rejected with 416.
for unsupported_range in 'bytes=0-99,200-299' 'bytes=abc' 'items=0-99'; do
  unsupported_status=$(curl -sS -o "$mirror_tmp/full.bin" -w '%{http_code}' -H "Range: $unsupported_range" "$mirror_url$video_path")
  [[ "$unsupported_status" == 200 ]]
  [[ $(wc -c <"$mirror_tmp/full.bin" | tr -d ' ') == "$video_size" ]]
done

etag=$(awk 'BEGIN{IGNORECASE=1} /^etag:/{sub(/\r$/,""); print substr($0,index($0,":")+2)}' "$mirror_tmp/head.txt")
not_modified_status=$(curl -sS -o /dev/null -w '%{http_code}' -H "If-None-Match: $etag" "$mirror_url$video_path")
[[ "$not_modified_status" == 304 ]]

# A matching If-Range still slices; a stale one must return the whole file so a
# client never splices fresh bytes onto a pre-deploy prefix.
if_range_match_status=$(curl -sS -o /dev/null -w '%{http_code}' -H "If-Range: $etag" -H 'Range: bytes=0-1023' "$mirror_url$video_path")
[[ "$if_range_match_status" == 206 ]]

if_range_stale_status=$(curl -sS -o "$mirror_tmp/if-range.bin" -w '%{http_code}' -H 'If-Range: "stale-validator"' -H 'Range: bytes=0-1023' "$mirror_url$video_path")
[[ "$if_range_stale_status" == 200 ]]
[[ $(wc -c <"$mirror_tmp/if-range.bin" | tr -d ' ') == "$video_size" ]]

# Aborting a range request mid-stream must not wedge the server.
curl -sS -o /dev/null --max-time 1 --limit-rate 8k -H 'Range: bytes=0-4194303' "$mirror_url$video_path" || true
curl -fsS -o /dev/null "$mirror_url/" || {
  cat "$mirror_tmp/server.log" >&2
  exit 1
}

# Clients that vanish before the response starts must not leave a handler
# waiting on drain or hold the file stream open.
node -e '
const net = require("node:net");
const [host, port, target] = process.argv.slice(1);
let pending = 30;
const finish = () => { if (--pending === 0) process.exit(0) };
for (let i = 0; i < 30; i += 1) {
  const socket = net.connect(Number(port), host, () => {
    socket.write(`GET ${target} HTTP/1.1\r\nHost: ${host}\r\nRange: bytes=0-4194303\r\n\r\n`);
    setTimeout(() => { socket.resetAndDestroy(); finish() }, i % 6);
  });
  socket.on("error", finish);
}
' 127.0.0.1 "$mirror_port" "$video_path"

recovered_status=$(curl -sS -o "$mirror_tmp/recovered.bin" -w '%{http_code}' -H 'Range: bytes=0-1023' "$mirror_url$video_path")
[[ "$recovered_status" == 206 ]]
[[ $(wc -c <"$mirror_tmp/recovered.bin" | tr -d ' ') == 1024 ]]
! grep -q ' failed: ' "$mirror_tmp/server.log"

hashed_asset=$(cd dist/client && find tools -type f -path '*/demo/assets/*' \
  | grep -E -- '-[A-Za-z0-9_-]{8}\.[^/]+$' \
  | LC_ALL=C sort \
  | awk 'NR==1')
[[ -n "$hashed_asset" ]]
curl -fsSI "$mirror_url/$hashed_asset" >"$mirror_tmp/hashed.txt"
grep -qi '^cache-control: public, max-age=31536000, immutable' "$mirror_tmp/hashed.txt"

redirect_location=$(curl -sSI -H 'Host: cn.xiangyang.work' -H 'X-Forwarded-Proto: https' "$mirror_url/tools/taskflow" | awk 'BEGIN{IGNORECASE=1} /^location:/{sub(/\r$/,""); print substr($0,index($0,":")+2)}')
[[ "$redirect_location" == 'https://cn.xiangyang.work/tools/taskflow/demo/?lang=zh' ]]

echo "Mirror server streaming, caching, and HTTPS redirect checks passed"
