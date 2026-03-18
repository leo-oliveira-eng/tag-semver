#!/usr/bin/env bats

setup() {
  export INPUT_TOKEN="test-token"
  export INPUT_ALLOWED_BASE_BRANCHES="main,master"
  export INPUT_TAG_PREFIX="v"
  export INPUT_MAJOR_LABEL="version:major"
  export INPUT_MINOR_LABEL="version:minor"
  export INPUT_PATCH_LABEL="version:patch"
  export INPUT_PRERELEASE_LABEL_PREFIX="pre-release:"
  export INPUT_BUILD_LABEL_PREFIX="build:"
  export INPUT_DEFAULT_BUMP=""
  export INPUT_DRY_RUN="true"

  export GITHUB_OUTPUT="$BATS_TEST_TMPDIR/github-output.txt"
  : >"$GITHUB_OUTPUT"

  mock_bin="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$mock_bin"
  export PATH="$mock_bin:$PATH"

  cat >"$mock_bin/gh" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "pr" && "$2" == "view" ]]; then
  printf '%s\n' "$MOCK_PR_LABELS"
else
  echo "unexpected gh invocation: $*" >&2
  exit 1
fi
EOF
  chmod +x "$mock_bin/gh"

  repo_dir="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$repo_dir"
  git -C "$repo_dir" init >/dev/null
  git -C "$repo_dir" config user.name "test"
  git -C "$repo_dir" config user.email "test@example.com"
  git -C "$repo_dir" commit --allow-empty -m "init" >/dev/null
  git -C "$repo_dir" tag "v1.2.3"
}

@test "computes the next tag in dry run mode for an allowed branch" {
  export MOCK_PR_LABELS=$'version:minor\npre-release:beta\nbuild:run.42'
  export GITHUB_EVENT_PATH="$BATS_TEST_TMPDIR/event-main.json"

  cat >"$GITHUB_EVENT_PATH" <<'EOF'
{"pull_request":{"number":12,"merged":true,"base":{"ref":"main"}}}
EOF

  run bash -c "cd '$repo_dir' && bash '$BATS_TEST_DIRNAME/../entrypoint.sh'"

  [ "$status" -eq 0 ]
  grep -q '^next-tag=v1.3.0-beta.1+run.42$' "$GITHUB_OUTPUT"
  grep -q '^tag-created=false$' "$GITHUB_OUTPUT"
}

@test "skips tag creation when the base branch is not allowed" {
  export MOCK_PR_LABELS='version:patch'
  export GITHUB_EVENT_PATH="$BATS_TEST_TMPDIR/event-feature.json"

  cat >"$GITHUB_EVENT_PATH" <<'EOF'
{"pull_request":{"number":13,"merged":true,"base":{"ref":"feature"}}}
EOF

  run bash -c "cd '$repo_dir' && bash '$BATS_TEST_DIRNAME/../entrypoint.sh'"

  [ "$status" -eq 0 ]
  grep -q '^base-branch=feature$' "$GITHUB_OUTPUT"
  grep -q '^tag-created=false$' "$GITHUB_OUTPUT"
}

@test "fails for invalid build metadata labels" {
  export MOCK_PR_LABELS=$'version:patch\nbuild:bad+value'
  export GITHUB_EVENT_PATH="$BATS_TEST_TMPDIR/event-invalid-build.json"

  cat >"$GITHUB_EVENT_PATH" <<'EOF'
{"pull_request":{"number":14,"merged":true,"base":{"ref":"main"}}}
EOF

  run bash -c "cd '$repo_dir' && bash '$BATS_TEST_DIRNAME/../entrypoint.sh'"

  [ "$status" -eq 1 ]
  [[ "$output" == *"Invalid build metadata label value"* ]]
}
