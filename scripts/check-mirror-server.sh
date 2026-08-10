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
PORT="$mirror_port" node scripts/serve-sites-preview.mjs >"$mirror_tmp/server.log" 2>&1 &
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

bash scripts/check-sites-routes.sh "$mirror_url"

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

etag=$(awk 'BEGIN{IGNORECASE=1} /^etag:/{sub(/\r$/,""); print substr($0,index($0,":")+2)}' "$mirror_tmp/head.txt")
not_modified_status=$(curl -sS -o /dev/null -w '%{http_code}' -H "If-None-Match: $etag" "$mirror_url$video_path")
[[ "$not_modified_status" == 304 ]]

redirect_location=$(curl -sSI -H 'Host: cn.xiangyang.work' -H 'X-Forwarded-Proto: https' "$mirror_url/tools/taskflow" | awk 'BEGIN{IGNORECASE=1} /^location:/{sub(/\r$/,""); print substr($0,index($0,":")+2)}')
[[ "$redirect_location" == 'https://cn.xiangyang.work/tools/taskflow/demo/?lang=zh' ]]

echo "Mirror server streaming, caching, and HTTPS redirect checks passed"
