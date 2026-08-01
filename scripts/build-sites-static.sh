#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="$project_dir/dist"

rm -rf "$build_dir"
mkdir -p "$build_dir/server" "$build_dir/client"

cp "$project_dir/worker/index.mjs" "$build_dir/server/index.js"
cp "$project_dir/index.html" "$build_dir/client/index.html"

grep -Eo 'assets/[A-Za-z0-9._/-]+' "$project_dir/index.html" \
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

printf 'Built static Sites package at %s\n' "$build_dir"
