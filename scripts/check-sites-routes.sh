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

check_html_route(){
  local route="$1" marker="$2" body="$work_dir/body.html" code
  code="$(curl --fail-with-body --location --silent --show-error \
    --output "$body" --write-out '%{http_code}' --header 'Accept: text/html' \
    "$base_url$route")"
  test "$code" = "200"
  grep -Fq "$marker" "$body"
  printf 'ok  %s\n' "$route"
}

for route in "${project_routes[@]}"; do check_html_route "$route" 'id="project-root"'; done
for route in "${demo_routes[@]}"; do check_html_route "$route" 'id="root"'; done

index_body="$work_dir/index.html"
curl --fail --silent --show-error "$base_url/" --output "$index_body"
if grep -Fq 'chatgpt.site' "$index_body"; then
  printf 'The homepage still contains a chatgpt.site link\n' >&2
  exit 1
fi
for route in "${project_routes[@]}"; do grep -Fq "data-experience-url=\"$route\"" "$index_body"; done

assets=(
  /assets/project-detail.css
  /assets/project-detail.js
  /assets/portfolio.pdf
  /tools/household-care/demo/assets/iphone/Bezel.png
  /tools/taskflow/demo/assets/index-DoaGtyQD.js
  /tools/workflow-recovery/demo/assets/index-CWfQJmqD.css
)
for asset in "${assets[@]}"; do
  curl --fail --silent --show-error --head "$base_url$asset" >/dev/null
  printf 'ok  %s\n' "$asset"
done

printf 'All portfolio routes passed at %s\n' "$base_url"
