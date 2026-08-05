#!/usr/bin/env bash
set -euo pipefail

base_url="${1:-http://127.0.0.1:4177}"
base_url="${base_url%/}"
work_dir="$(mktemp -d "${TMPDIR:-/tmp}/portfolio-route-check.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT

project_routes=(
  /projects/digital-me/
  /projects/community-hub/
  /projects/vibrotactile-platform/
  /projects/workzone-safety/
  /tools/household-care/
  /tools/taskflow/
  /tools/workflow-recovery/
  /tools/structured-voice-input/
  /concepts/synthetic-society/
)
demo_routes=(
  /tools/household-care/demo/
  /tools/taskflow/demo/
  /tools/workflow-recovery/demo/
)

fail(){
  printf 'FAIL %s\n' "$1" >&2
  exit 1
}

check_html_route(){
  local route="$1" marker="$2" body="$work_dir/body.html" code
  code="$(curl --fail-with-body --location --silent --show-error \
    --output "$body" --write-out '%{http_code}' --header 'Accept: text/html' \
    "$base_url$route")" || fail "$base_url$route could not be fetched"
  test "$code" = "200" || fail "$base_url$route returned HTTP $code, expected 200"
  grep -Fq "$marker" "$body" || fail "$base_url$route responded 200 but its body is missing the marker $marker"
  printf 'ok  %s\n' "$route"
}

for route in "${project_routes[@]}"; do check_html_route "$route" 'id="project-root"'; done
for route in "${demo_routes[@]}"; do check_html_route "$route" 'id="root"'; done

index_body="$work_dir/index.html"
curl --fail --silent --show-error "$base_url/" --output "$index_body" \
  || fail "$base_url/ could not be fetched"
if grep -Fq 'chatgpt.site' "$index_body"; then
  printf 'FAIL the homepage at %s/ still contains a chatgpt.site link\n' "$base_url" >&2
  exit 1
fi
# The portfolio PDF is not published yet: its source still points demos at the
# old chatgpt.site host, so linking it would take visitors off the custom domain.
if grep -Fq 'assets/portfolio.pdf' "$index_body"; then
  printf 'FAIL the homepage at %s/ links to the unpublished assets/portfolio.pdf\n' "$base_url" >&2
  exit 1
fi
for route in "${project_routes[@]}"; do
  grep -Fq "data-experience-url=\"$route\"" "$index_body" \
    || fail "the homepage at $base_url/ does not link to $route (missing data-experience-url=\"$route\")"
done

assets=(
  /assets/project-detail.css
  /assets/project-detail.js
  /tools/household-care/demo/assets/iphone/Bezel.png
  /tools/taskflow/demo/assets/index-DoaGtyQD.js
  /tools/workflow-recovery/demo/assets/index-CWfQJmqD.css
)
for asset in "${assets[@]}"; do
  curl --fail --silent --show-error --head "$base_url$asset" >/dev/null \
    || fail "$base_url$asset is not served"
  printf 'ok  %s\n' "$asset"
done

printf 'All portfolio routes passed at %s\n' "$base_url"
