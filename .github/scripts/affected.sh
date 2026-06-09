#!/usr/bin/env bash
# Emits a GitHub Actions matrix of affected {cloud,stage} combos as JSON:
#   {"include":[{"cloud":"azure","stage":"dev"}, ...]}
#
# Usage: affected.sh [BASE_SHA] [HEAD_SHA]
#   - No/empty refs  -> all existing combos (e.g. workflow_dispatch).
#   - A combo is "affected" when a changed file is under:
#       iac/live/<cloud>/<stage>/**   (that combo)
#       iac/modules/<cloud>/**        (all stages of that cloud)
#     or a global file changed (root terragrunt.hcl, .tflint.hcl, Makefile,
#     .github/**) -> all combos.
set -euo pipefail

BASE="${1:-}"
HEAD="${2:-}"

# Existing combos from the live tree: iac/live/<cloud>/<stage>
mapfile -t combos < <(find iac/live -mindepth 2 -maxdepth 2 -type d -printf '%P\n' | sort)

if [ -z "$BASE" ] || [ -z "$HEAD" ]; then
  changed="__ALL__"
else
  changed="$(git diff --name-only "$BASE" "$HEAD" 2>/dev/null || echo __ALL__)"
fi

global_re='^(iac/live/terragrunt\.hcl|iac/\.tflint\.hcl|Makefile|\.github/)'
force_all=false
if [ "$changed" = "__ALL__" ]; then
  force_all=true
elif printf '%s\n' "$changed" | grep -qE "$global_re"; then
  force_all=true
fi

inc='[]'
for combo in "${combos[@]}"; do
  cloud="${combo%%/*}"
  stage="${combo##*/}"
  hit=false
  if $force_all; then
    hit=true
  elif printf '%s\n' "$changed" | grep -qE "^iac/live/${cloud}/${stage}/"; then
    hit=true
  elif printf '%s\n' "$changed" | grep -qE "^iac/modules/${cloud}/"; then
    hit=true
  fi
  if $hit; then
    inc="$(printf '%s' "$inc" | jq -c --arg c "$cloud" --arg s "$stage" '. + [{cloud:$c,stage:$s}]')"
  fi
done

jq -cn --argjson inc "$inc" '{include:$inc}'
