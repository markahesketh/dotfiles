#!/usr/bin/env bash

if [[ -f .rspec || -d spec ]]; then
  bundle exec rspec --fail-fast
elif [[ -d test ]]; then
  if [[ -f bin/rails ]]; then
    ./bin/rails test --fail-fast
  else
    bundle exec ruby -Itest -e 'Dir["test/**/*_test.rb"].each { |f| require_relative f }'
  fi
else
  echo "No test suite detected (no spec/ or test/ directory found)"
fi

echo ""
read -rp "Press enter to close..."
