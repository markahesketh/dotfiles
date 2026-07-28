#!/usr/bin/env bash

input=$(cat)
session_id=$(printf '%s' "$input" | jq -r '.session_id // "unknown"')
event=$(printf '%s' "$input" | jq -r '.hook_event_name // ""')
cwd=$(printf '%s' "$input" | jq -r '.cwd // "."')
source=$(printf '%s' "$input" | jq -r '.source // ""')
stop_hook_active=$(printf '%s' "$input" | jq -r '.stop_hook_active // false')

repo=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) || exit 0
state_root=${COMMENT_REVIEW_STATE_DIR:-${TMPDIR:-/tmp}/agent-comment-review}
state_key=$(printf '%s\0%s' "$session_id" "$repo" | git hash-object --stdin)
state_dir="$state_root/$state_key"
base_file="$state_dir/base"
baseline_file="$state_dir/baseline"
approved_file="$state_dir/approved"
pending_file="$state_dir/pending"
attempts_file="$state_dir/attempts"

detect_candidates() {
  awk '
    function comment_style(path, name) {
      name = path
      sub(/^.*\//, "", name)

      if (path ~ /\.(astro|svelte|vue)$/) return "slash markup"
      if (path ~ /\.erb$/) return "hash markup"
      if (path ~ /\.php$/) return "hash slash"
      if (path ~ /\.(hcl|tf)$/) return "hash slash"
      if (path ~ /\.(c|cc|cpp|cs|css|go|h|hpp|java|js|jsx|kt|kts|less|m|mm|rs|scss|swift|ts|tsx)$/) return "slash"
      if (path ~ /\.(heex|html|xml)$/) return "markup"
      if (path ~ /\.(conf|gitconfig|ini)$/) return "hash semicolon"
      if (path ~ /\.(ex|exs|gemspec|nix|pl|pm|ps1|py|r|rake|rb|toml|yaml|yml)$/) return "hash"
      if (path ~ /\.(hs|lua|sql)$/) return "dash"
      if (path ~ /\.(asm|clj|cljc|cljs|edn|el|lisp|scm)$/) return "semicolon"
      if (path ~ /\.(bash|sh|zsh)$/) return "hash"
      if (name ~ /^(Brewfile|Dockerfile|Gemfile|Guardfile|Makefile|Procfile|Rakefile|Vagrantfile)$/) return "hash"
      if (name == ".gitconfig") return "hash semicolon"
      if (name == ".vimrc") return "vim"
      if (name ~ /^\.(aliases|bash_profile|bashrc|env|profile|zprofile|zshenv|zshrc)$/) return "hash"
      if (path ~ /(^|\/)(bin|script|scripts)\// && name !~ /\./) return "hash"
      return ""
    }

    function has_style(styles, wanted) {
      return index(" " styles " ", " " wanted " ") > 0
    }

    function required_directive(text, lower, trimmed) {
      trimmed = text
      sub(/^[[:space:]]+/, "", trimmed)
      lower = tolower(trimmed)

      return trimmed ~ /^#!/ ||
             lower ~ /^#[[:space:]]*(frozen_string_literal:|encoding:|coding[=:]|typed:|rubocop:|shellcheck|noqa([[:space:]]|$)|pylint:|pyright:|type:[[:space:]]*ignore|pragma:)/ ||
             lower ~ /^\/\/[[:space:]]*(eslint-|prettier-ignore|@ts-ignore|@ts-expect-error|istanbul ignore|c8 ignore|#[[:space:]]*sourcemappingurl=)/ ||
             lower ~ /^\/\*[[:space:]]*(istanbul ignore|c8 ignore)/
    }

    /^\+\+\+ / {
      path = substr($0, 5)
      next
    }

    /^\+/ {
      style = comment_style(path)
      if (style == "") next
      text = substr($0, 2)
      if (required_directive(text)) next

      if ((has_style(style, "hash") && text ~ /(^|[[:space:]])#/) ||
          (has_style(style, "slash") && (text ~ /(^|[[:space:]])\/\// ||
                                         text ~ /(^|[[:space:]])\/\*/ ||
                                         text ~ /^[[:space:]]*\*/)) ||
          (has_style(style, "markup") && (text ~ /<!--/ || text ~ /<%#/ || text ~ /<%!--/)) ||
          (has_style(style, "dash") && text ~ /--/) ||
          (has_style(style, "semicolon") && text ~ /(^|[[:space:]]);/) ||
          (has_style(style, "vim") && text ~ /(^|[[:space:]])"/)) {
        trimmed = text
        sub(/^[[:space:]]+/, "", trimmed)
        print path "\t" trimmed
      }
    }
  '
}

collect_candidates() {
  base=$1
  if [ -n "$base" ] && git -C "$repo" cat-file -e "$base^{commit}" 2>/dev/null; then
    git -C "$repo" -c core.quotepath=false diff \
      --no-prefix --no-ext-diff --unified=0 --no-color "$base" --
  else
    git -C "$repo" ls-files -c -z |
      while IFS= read -r -d '' relative_path; do
        [ -f "$repo/$relative_path" ] || continue
        printf '+++ %s\n' "$relative_path"
        sed 's/^/+/' "$repo/$relative_path"
      done
  fi

  git -C "$repo" ls-files --others --exclude-standard -z |
    while IFS= read -r -d '' relative_path; do
      [ -f "$repo/$relative_path" ] || continue
      printf '+++ %s\n' "$relative_path"
      sed 's/^/+/' "$repo/$relative_path"
    done
}

candidate_snapshot() {
  collect_candidates "$1" | detect_candidates | LC_ALL=C sort
}

initialize_state() {
  mkdir -p "$state_dir"
  base=$(git -C "$repo" rev-parse HEAD 2>/dev/null || true)
  printf '%s\n' "$base" > "$base_file"
  candidate_snapshot "$base" > "$baseline_file"
  : > "$approved_file"
  : > "$pending_file"
  printf '0\n' > "$attempts_file"
}

if [ "$event" = "SessionStart" ]; then
  if [ "$source" != "startup" ] &&
     [ -f "$base_file" ] &&
     [ -f "$baseline_file" ]; then
    exit 0
  fi
  initialize_state
  exit 0
fi

[ "$event" = "Stop" ] || exit 0
mkdir -p "$state_dir"

if [ -z "$(git -C "$repo" status --porcelain --untracked-files=normal)" ]; then
  initialize_state
  exit 0
fi

if [ ! -f "$base_file" ] || [ ! -f "$baseline_file" ]; then
  initialize_state
  exit 0
fi
base=$(sed -n '1p' "$base_file")

current_file=$(mktemp "${TMPDIR:-/tmp}/comment-review-current.XXXXXX")
candidates_file=$(mktemp "${TMPDIR:-/tmp}/comment-review-candidates.XXXXXX")
trap 'rm -f "$current_file" "$candidates_file"' EXIT

candidate_snapshot "$base" > "$current_file"
comm -23 "$current_file" "${baseline_file:-/dev/null}" > "$candidates_file"
if [ ! -s "$candidates_file" ]; then
  : > "$approved_file"
  : > "$pending_file"
  printf '0\n' > "$attempts_file"
  exit 0
fi

fingerprint=$(git hash-object "$candidates_file")
approved=$(sed -n '1p' "$approved_file" 2>/dev/null || true)
pending=$(sed -n '1p' "$pending_file" 2>/dev/null || true)

if [ "$fingerprint" = "$approved" ]; then
  exit 0
fi

if [ "$fingerprint" = "$pending" ]; then
  printf '%s\n' "$fingerprint" > "$approved_file"
  : > "$pending_file"
  printf '0\n' > "$attempts_file"
  exit 0
fi

attempts=$(sed -n '1p' "$attempts_file" 2>/dev/null || printf '0')
if [ "$stop_hook_active" = "true" ] && [ "$attempts" -ge 2 ]; then
  printf '%s\n' "$fingerprint" > "$approved_file"
  : > "$pending_file"
  printf '0\n' > "$attempts_file"
  exit 0
fi

printf '%s\n' "$fingerprint" > "$pending_file"
printf '%s\n' $((attempts + 1)) > "$attempts_file"
locations=$(head -20 "$candidates_file" | sed 's/^/- /')
reason="Review comments introduced by your changes. First try to make each comment unnecessary by improving names, extracting intent, simplifying control flow, or encoding the constraint in code. Delete comments that describe what the code does or narrate this task, bug, ticket, or change history. Retain only comments needed to explain a non-obvious invariant, external constraint, or unavoidable workaround, and make them as concise as possible. Preserve required directives and documentation, keep the refactoring proportionate, and verify behaviour afterwards.

Possible added comments:
$locations"

jq -n --arg reason "$reason" '{decision: "block", reason: $reason}'
