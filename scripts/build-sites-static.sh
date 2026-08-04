#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="$project_dir/dist"
pages=(index.html resume.html project.html)

page_paths=()
for page in "${pages[@]}"; do
  test -f "$project_dir/$page" || {
    printf 'Missing page: %s\n' "$page" >&2
    exit 2
  }
  page_paths+=("$project_dir/$page")
done

# Project detail content is rendered from this route-aware data file. Include it
# in the asset dependency scan so every referenced gallery image ships with the
# same atomic Sites version.
page_paths+=("$project_dir/assets/project-detail.js")

for page in "${pages[@]}"; do
  while IFS= read -r linked_page; do
    case " ${pages[*]} " in
      *" $linked_page "*) ;;
      *)
        printf '%s links to %s, which is not in the packaged page list\n' \
          "$page" "$linked_page" >&2
        exit 2
        ;;
    esac
  done < <(grep -Eo '(href|src)="[A-Za-z0-9._-]+\.html([#?][^"]*)?"' "$project_dir/$page" \
    | cut -d'"' -f2 \
    | cut -d'#' -f1 \
    | cut -d'?' -f1 \
    | LC_ALL=C sort -u)
done

rm -rf "$build_dir"
mkdir -p "$build_dir/server" "$build_dir/client"

cp "$project_dir/worker/index.mjs" "$build_dir/server/index.js"

for page in "${pages[@]}"; do
  cp "$project_dir/$page" "$build_dir/client/$page"
done

grep -Eho 'assets/[A-Za-z0-9._/-]+' "${page_paths[@]}" \
  | LC_ALL=C sort -u \
  | while IFS= read -r asset; do
      source_path="$project_dir/$asset"
      target_path="$build_dir/client/$asset"
      test -f "$source_path" || {
        printf 'Missing referenced asset: %s\n' "$asset" >&2
        exit 2
      }
      mkdir -p "$(dirname "$target_path")"
      cp "$source_path" "$target_path"
done

# The three interactive demos are self-contained snapshots with route-scoped
# assets. Keeping them below /tools prevents one demo's hashed assets from
# colliding with another demo or with the portfolio shell.
cp -R "$project_dir/tools" "$build_dir/client/tools"

printf 'Built static Sites package at %s\n' "$build_dir"
