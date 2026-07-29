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

# Committed content is foreign history or already reviewed, so diff HEAD only.
collect_uncommitted() {
  if git -C "$repo" rev-parse --verify -q HEAD >/dev/null 2>&1; then
    git -C "$repo" -c core.quotepath=false diff \
      --no-prefix --no-ext-diff --unified=0 --no-color HEAD --
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
  collect_uncommitted | detect_candidates | LC_ALL=C sort -u
}

initialize_state() {
  mkdir -p "$state_dir"
  candidate_snapshot > "$baseline_file"
  : > "$approved_file"
  : > "$pending_file"
  printf '0\n' > "$attempts_file"
}

if [ "$event" = "SessionStart" ]; then
  if [ "$source" != "startup" ] && [ -f "$baseline_file" ]; then
    exit 0
  fi
  initialize_state
  exit 0
fi

[ "$event" = "Stop" ] || exit 0
mkdir -p "$state_dir"

if [ ! -f "$baseline_file" ] ||
   [ -z "$(git -C "$repo" status --porcelain --untracked-files=normal)" ]; then
  initialize_state
  exit 0
fi
[ -f "$approved_file" ] || : > "$approved_file"
[ -f "$pending_file" ] || : > "$pending_file"

current_file=$(mktemp "${TMPDIR:-/tmp}/comment-review-current.XXXXXX")
excluded_file=$(mktemp "${TMPDIR:-/tmp}/comment-review-excluded.XXXXXX")
unreviewed_file=$(mktemp "${TMPDIR:-/tmp}/comment-review-unreviewed.XXXXXX")
candidates_file=$(mktemp "${TMPDIR:-/tmp}/comment-review-candidates.XXXXXX")
trap 'rm -f "$current_file" "$excluded_file" "$unreviewed_file" "$candidates_file"' EXIT

candidate_snapshot > "$current_file"
LC_ALL=C sort -u "$baseline_file" "$approved_file" > "$excluded_file"
comm -23 "$current_file" "$excluded_file" > "$unreviewed_file"

# Surviving a block means the comment was deliberately kept.
comm -12 "$unreviewed_file" "$pending_file" >> "$approved_file"
LC_ALL=C sort -u -o "$approved_file" "$approved_file"
comm -23 "$unreviewed_file" "$approved_file" > "$candidates_file"

settle() {
  LC_ALL=C sort -u -o "$approved_file" "$approved_file"
  : > "$pending_file"
  printf '%s\n' "${1:-0}" > "$attempts_file"
  exit 0
}

attempts=$(sed -n '1p' "$attempts_file" 2>/dev/null || printf '0')
case $attempts in
  '' | *[!0-9]*) attempts=0 ;;
esac
[ "$stop_hook_active" = "true" ] || attempts=0

if [ ! -s "$candidates_file" ]; then
  settle
fi

# Carry the count through so a reworded comment cannot restart the cycle.
if [ "$attempts" -ge 2 ]; then
  cat "$candidates_file" >> "$approved_file"
  settle "$attempts"
fi

cp "$candidates_file" "$pending_file"
printf '%s\n' $((attempts + 1)) > "$attempts_file"
locations=$(head -20 "$candidates_file" | sed 's/^/- /')
reason="Review comments introduced by your changes. First try to make each comment unnecessary by improving names, extracting intent, simplifying control flow, or encoding the constraint in code. Delete comments that describe what the code does or narrate this task, bug, ticket, or change history. Retain only comments needed to explain a non-obvious invariant, external constraint, or unavoidable workaround, and make them as concise as possible. Preserve required directives and documentation, keep the refactoring proportionate, and verify behaviour afterwards.

Possible added comments:
$locations"

jq -n --arg reason "$reason" '{decision: "block", reason: $reason}'
