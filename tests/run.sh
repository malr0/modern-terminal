#!/bin/bash
# Runs every test_* function from tests/test_*.sh, each in its own subshell.
# Usage: tests/run.sh [name-filter]
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=tests/lib.sh
. "$REPO_DIR/tests/lib.sh"
for f in "$REPO_DIR"/tests/test_*.sh; do
  # shellcheck source=/dev/null
  . "$f"
done

filter="${1:-}"
pass=0
failed=0
for t in $(declare -F | awk '{print $3}' | grep '^test_' | grep -F -- "$filter"); do
  if ( "$t" ) >"$TMP_ROOT/$t.log" 2>&1; then
    pass=$((pass + 1))
    echo "ok   $t"
  else
    failed=$((failed + 1))
    echo "FAIL $t"
    sed 's/^/     /' "$TMP_ROOT/$t.log"
  fi
done
echo "$pass passed, $failed failed"
[ "$failed" -eq 0 ]
