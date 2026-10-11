#!/usr/bin/env bash
# Runs every tests/test_*.gd headless. Fails if a test fails or Godot logs any error.
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
status=0

for test in tests/test_*.gd; do
	echo "== $test"
	output=$("$GODOT" --headless --script "res://$test" 2>&1)
	code=$?
	echo "$output" | grep -v '^Godot Engine'
	if [ $code -ne 0 ]; then
		status=1
	elif echo "$output" | grep -qE '^(SCRIPT )?ERROR'; then
		echo "  FAIL Godot logged errors"
		status=1
	fi
done

exit $status
