#!/usr/bin/env bash
set -euo pipefail

base_url="${1:-http://127.0.0.1:4177}"
base_url="${base_url%/}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd "$script_dir/.." && pwd)"
work_dir="$(mktemp -d "${TMPDIR:-/tmp}/portfolio-route-check.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT

card_matrix=(
  'digital-me|live|https://digital-me-dashboard.vercel.app/'
  'community-hub|live|https://blacksburg-secondhand-production.up.railway.app/'
  'vibrotactile-platform|fallback|/#atlas'
  'workzone-safety|fallback|/#atlas'
  'household-care|demo|/tools/household-care/demo/'
  'taskflow|demo|/tools/taskflow/demo/'
  'workflow-recovery|demo|/tools/workflow-recovery/demo/'
  'structured-voice-input|fallback|/#atlas'
  'synthetic-society|fallback|/#atlas'
)
legacy_redirects=(
  '/projects/digital-me/|https://digital-me-dashboard.vercel.app/'
  '/projects/community-hub/|https://blacksburg-secondhand-production.up.railway.app/'
  '/projects/vibrotactile-platform/|/#atlas'
  '/projects/workzone-safety/|/#atlas'
  '/tools/household-care/|/tools/household-care/demo/?lang=zh'
  '/tools/taskflow/|/tools/taskflow/demo/?lang=zh'
  '/tools/workflow-recovery/|/tools/workflow-recovery/demo/?lang=zh'
  '/tools/structured-voice-input/|/#atlas'
  '/concepts/synthetic-society/|/#atlas'
)
demo_routes=(
  '/tools/household-care/demo/?lang=zh'
  '/tools/household-care/demo/?lang=en'
  '/tools/taskflow/demo/?lang=zh'
  '/tools/taskflow/demo/?lang=en'
  '/tools/workflow-recovery/demo/?lang=zh'
  '/tools/workflow-recovery/demo/?lang=en'
)

fail(){
  printf 'FAIL %s\n' "$1" >&2
  exit 1
}

absolute_target(){
  local target="$1"
  case "$target" in
    http://*|https://*) printf '%s' "$target" ;;
    *) printf '%s%s' "$base_url" "$target" ;;
  esac
}

check_html_route(){
  local route="$1" marker="$2" body="$work_dir/body.html" metrics code redirects effective
  metrics="$(curl --fail-with-body --silent --show-error \
    --output "$body" --write-out $'%{http_code}\t%{num_redirects}\t%{url_effective}' \
    --header 'Accept: text/html' "$base_url$route")" \
    || fail "$base_url$route could not be fetched"
  IFS=$'\t' read -r code redirects effective <<<"$metrics"
  test "$code" = "200" || fail "$base_url$route returned HTTP $code, expected 200"
  test "$redirects" = "0" || fail "$base_url$route redirected $redirects time(s), expected 0"
  test "$effective" = "$base_url$route" \
    || fail "$base_url$route ended at $effective instead of the requested URL"
  grep -Fq "$marker" "$body" \
    || fail "$base_url$route responded 200 but its body is missing the marker $marker"
  printf 'ok  %s\n' "$route"
}

check_internal_landing(){
  local route="$1" destination="$2" body="$work_dir/landing.html" code
  code="$(curl --silent --show-error --output "$body" --write-out '%{http_code}' \
    --header 'Accept: text/html' "$destination")" \
    || fail "$destination could not be fetched while verifying $route"
  test "$code" = "200" \
    || fail "$route does not land in a single hop; $destination returned HTTP $code"
  if grep -Fq 'id="project-root"' "$body"; then
    fail "$route still lands on the retained shared project detail shell"
  fi
}

check_redirect(){
  local route="$1" expected="$2" metrics code redirect_url
  metrics="$(curl --silent --show-error --output /dev/null \
    --write-out $'%{http_code}\t%{redirect_url}' --header 'Accept: text/html' \
    "$base_url$route")" || fail "$base_url$route could not be fetched"
  IFS=$'\t' read -r code redirect_url <<<"$metrics"
  test "$code" = "307" \
    || fail "$base_url$route returned HTTP $code, expected a temporary 307"
  test "$redirect_url" = "$expected" \
    || fail "$base_url$route redirects to $redirect_url, expected $expected"
  case "$redirect_url" in
    "$base_url"/*) check_internal_landing "$base_url$route" "$redirect_url" ;;
  esac
  printf 'ok  %s -> %s (307)\n' "$route" "$expected"
}

assert_card(){
  local id="$1" kind="$2" destination="$3" count line
  count="$(grep -Fc "data-project-id=\"$id\"" "$index_body" || true)"
  test "$count" = "1" || fail "expected one homepage card for $id, found $count"
  line="$(grep -F "data-project-id=\"$id\"" "$index_body" || true)"
  grep -Fq "data-destination-kind=\"$kind\"" <<<"$line" \
    || fail "$id does not declare destination kind $kind"
  grep -Fq "data-destination-url=\"$destination\"" <<<"$line" \
    || fail "$id does not point to $destination"
  printf 'ok  card %s -> %s (%s)\n' "$id" "$destination" "$kind"
}

# Vercel and Railway are free to add their own canonical redirects, so the
# reachability contract is: a final 200, on a host we still recognise, whose
# body identifies the intended site.
check_external_page(){
  local url="$1" allowed_hosts="$2" marker="$3" body="$work_dir/external.html"
  local metrics code redirects effective final_host host matched=0
  metrics="$(curl --fail-with-body --location --silent --show-error \
    --output "$body" --write-out $'%{http_code}\t%{num_redirects}\t%{url_effective}' "$url")" \
    || fail "$url could not be fetched"
  IFS=$'\t' read -r code redirects effective <<<"$metrics"
  test "$code" = "200" || fail "$url returned HTTP $code, expected 200"
  final_host="${effective#*://}"
  final_host="${final_host%%/*}"
  final_host="${final_host%%\?*}"
  while IFS= read -r host; do
    test -n "$host" || continue
    if test "$host" = "$final_host"; then
      matched=1
    fi
  done <<<"${allowed_hosts//,/$'\n'}"
  test "$matched" = "1" \
    || fail "$url ended on the unexpected host $final_host, expected one of $allowed_hosts"
  grep -Fqi "$marker" "$body" || fail "$url is missing page identity marker $marker"
  printf 'ok  external %s -> %s (%s redirect(s))\n' "$url" "$effective" "$redirects"
}

index_body="$work_dir/index.html"
curl --fail --silent --show-error "$base_url/" --output "$index_body" \
  || fail "$base_url/ could not be fetched"

grep -Fq 'max-height:min(820px,92vh,calc(100% - 40px))' "$index_body" \
  || fail "the project dialog is missing its overlay-relative viewport height guard"

card_count="$(grep -c 'data-project-id=' "$index_body" || true)"
test "$card_count" = "9" || fail "expected 9 typed project cards, found $card_count"
test "$(grep -c 'data-destination-kind="live"' "$index_body" || true)" = "2" \
  || fail "expected exactly 2 live destinations"
test "$(grep -c 'data-destination-kind="demo"' "$index_body" || true)" = "3" \
  || fail "expected exactly 3 demo destinations"
test "$(grep -c 'data-destination-kind="fallback"' "$index_body" || true)" = "4" \
  || fail "expected exactly 4 fallback destinations"
for row in "${card_matrix[@]}"; do
  IFS='|' read -r id kind destination <<<"$row"
  assert_card "$id" "$kind" "$destination"
done

grep -Fq 'data-github-url="https://github.com/xiangyangvt/blacksburg-secondhand"' "$index_body" \
  || fail "the community card does not point to the canonical source repository"
if grep -Eq 'data-destination-url="/(projects|concepts)/' "$index_body"; then
  fail "the homepage still points a primary action at a legacy project detail route"
fi
if grep -Eq 'data-destination-url="/tools/(household-care|taskflow|workflow-recovery|structured-voice-input)/"' "$index_body"; then
  fail "the homepage still points a primary action at a legacy tool detail route"
fi
if grep -Fq 'data-experience-url=' "$index_body"; then
  fail "the homepage still uses the ambiguous data-experience-url field"
fi
if grep -Fq 'chatgpt.site' "$index_body"; then
  fail "the homepage still contains a chatgpt.site link"
fi
if grep -Fq 'assets/portfolio.pdf' "$index_body"; then
  fail "the homepage links to the unpublished assets/portfolio.pdf"
fi

for route in "${demo_routes[@]}"; do
  check_html_route "$route" 'id="root"'
done

for row in "${legacy_redirects[@]}"; do
  IFS='|' read -r route destination <<<"$row"
  expected="$(absolute_target "$destination")"
  check_redirect "$route" "$expected"
  check_redirect "${route%/}" "$expected"
  case "$destination" in
    */demo/*)
      english_destination="${destination/lang=zh/lang=en}"
      english_expected="$(absolute_target "$english_destination")"
      check_redirect "${route}?lang=en" "$english_expected"
      check_redirect "${route%/}?lang=en" "$english_expected"
      ;;
  esac
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

detail_script="$work_dir/project-detail.js"
curl --fail --silent --show-error "$base_url/assets/project-detail.js" --output "$detail_script" \
  || fail "$base_url/assets/project-detail.js could not be fetched"
if grep -Fq 'github.com/yangxiang5136/blacksburg-secondhand' "$detail_script"; then
  fail "the retained project detail data still points to the empty community repository"
fi
grep -Fq 'github.com/xiangyangvt/blacksburg-secondhand' "$detail_script" \
  || fail "the retained project detail data is missing the canonical community repository"

# The served resolver is only ever compared, never executed: the language
# assertion runs the trusted repository copy so pointing this script at a
# deployed URL cannot run that deployment's JavaScript locally.
local_module="$project_dir/assets/portfolio-destination.js"
served_module="$work_dir/portfolio-destination.js"
test -f "$local_module" || fail "$local_module is missing from the repository"
curl --fail --silent --show-error "$base_url/assets/portfolio-destination.js" \
  --output "$served_module" \
  || fail "$base_url/assets/portfolio-destination.js could not be fetched"
cmp -s "$local_module" "$served_module" \
  || fail "$base_url/assets/portfolio-destination.js differs from the repository copy"
printf 'ok  /assets/portfolio-destination.js matches the repository copy\n'
node "$script_dir/check-demo-language.mjs" "$local_module" "$index_body" \
  || fail "the homepage demo cards do not carry the active portfolio language into their demo URL"

if test "${SKIP_EXTERNAL_LINKS:-0}" = "1"; then
  external_summary='live-site checks SKIPPED'
  printf 'SKIPPED external live-site check for %s (SKIP_EXTERNAL_LINKS=1)\n' \
    'https://digital-me-dashboard.vercel.app/' >&2
  printf 'SKIPPED external live-site check for %s (SKIP_EXTERNAL_LINKS=1)\n' \
    'https://blacksburg-secondhand-production.up.railway.app/' >&2
else
  external_summary='live sites verified'
  check_external_page 'https://digital-me-dashboard.vercel.app/' \
    'digital-me-dashboard.vercel.app' 'Digital Me'
  check_external_page 'https://blacksburg-secondhand-production.up.railway.app/' \
    'blacksburg-secondhand-production.up.railway.app' 'Blacksburg Secondhand'
fi

printf 'All portfolio destinations passed at %s (%s)\n' "$base_url" "$external_summary"
