#!/usr/bin/env bash

ALL=${1:-false}

tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT

run_tests() {
  if [[ -f .rspec || -d spec ]]; then
    bundle exec rspec --fail-fast
  elif [[ -d test ]]; then
    if [[ -f bin/rails ]]; then
      if [[ "$ALL" == "true" ]]; then
        ./bin/rails test:all --fail-fast
      else
        ./bin/rails test --fail-fast
      fi
    else
      bundle exec ruby -Itest -e 'Dir["test/**/*_test.rb"].each { |f| require_relative f }'
    fi
  else
    echo "No test suite detected (no spec/ or test/ directory found)"
  fi
}

run_tests 2>&1 | tee "$tmpfile"
less --mouse -R +G "$tmpfile"
