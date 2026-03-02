#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

write_prd() {
  local dir="$1"
  cat > "$dir/prd.json" <<'EOF'
{
  "project": "SmokeTest",
  "branchName": "ralph/smoke-test",
  "description": "Smoke test fixture",
  "userStories": [
    {
      "id": "US-001",
      "title": "Fixture story",
      "description": "Fixture",
      "acceptanceCriteria": ["Typecheck passes"],
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
EOF
}

write_codex_stub() {
  local dir="$1"
  local mode="$2"
  cat > "$dir/bin/codex" <<EOF
#!/bin/bash
set -euo pipefail
echo "\$*" >> "\${RALPH_TEST_INVOCATION_LOG}"
if [[ "\$1" != "exec" ]]; then
  echo "expected exec subcommand" >&2
  exit 2
fi
if [[ "$mode" == "complete" ]]; then
  echo "codex stub success"
  echo "<promise>COMPLETE</promise>"
elif [[ "$mode" == "mentioned-token" ]]; then
  echo "not outputting <promise>COMPLETE</promise> because stories remain"
else
  echo "codex stub still working"
fi
EOF
  chmod +x "$dir/bin/codex"
}

setup_fixture() {
  local name="$1"
  local mode="$2"
  local dir="$TMP_DIR/$name"
  mkdir -p "$dir/bin"
  cp "$ROOT_DIR/ralph.sh" "$dir/ralph.sh"
  chmod +x "$dir/ralph.sh"
  write_prd "$dir"
  write_codex_stub "$dir" "$mode"
  echo "$dir"
}

run_success_case() {
  local dir
  dir="$(setup_fixture success complete)"
  local output="$dir/output.log"
  local invocation_log="$dir/invocations.log"

  (
    cd "$dir"
    PATH="$dir/bin:$PATH" \
    RALPH_TEST_INVOCATION_LOG="$invocation_log" \
    ./ralph.sh --tool codex 3 > "$output" 2>&1
  )

  grep -q "Ralph completed all tasks!" "$output"
  grep -q "<promise>COMPLETE</promise>" "$output"
  grep -q "^exec\\b" "$invocation_log"
}

run_max_iteration_case() {
  local dir
  dir="$(setup_fixture max-iterations mentioned-token)"
  local output="$dir/output.log"
  local invocation_log="$dir/invocations.log"
  local rc=0

  set +e
  (
    cd "$dir"
    PATH="$dir/bin:$PATH" \
    RALPH_TEST_INVOCATION_LOG="$invocation_log" \
    ./ralph.sh --tool codex 2 > "$output" 2>&1
  )
  rc=$?
  set -e

  if [[ "$rc" -ne 1 ]]; then
    echo "Expected exit code 1 for max-iteration case, got $rc" >&2
    exit 1
  fi

  local invocation_count
  invocation_count="$(wc -l < "$invocation_log" | tr -d ' ')"
  if [[ "$invocation_count" -ne 2 ]]; then
    echo "Expected 2 Codex invocations, got $invocation_count" >&2
    exit 1
  fi

  grep -q "^exec\\b" "$invocation_log"
  grep -q "not outputting <promise>COMPLETE</promise> because stories remain" "$output"
  grep -q "Ralph reached max iterations (2)" "$output"
}

run_success_case
run_max_iteration_case

echo "Codex smoke tests passed."
