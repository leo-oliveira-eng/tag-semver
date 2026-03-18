#!/usr/bin/env bats

setup() {
  source "$BATS_TEST_DIRNAME/../lib/log.sh"
  source "$BATS_TEST_DIRNAME/../lib/common.sh"
  source "$BATS_TEST_DIRNAME/../lib/semver.sh"
  source "$BATS_TEST_DIRNAME/../lib/labels.sh"
  source "$BATS_TEST_DIRNAME/../lib/git.sh"
}

@test "calculates a patch bump from the default starting point" {
  run calculate_next_tag "v0.0.0" "patch" "" "" "v"

  [ "$status" -eq 0 ]
  [ "$output" = "v0.0.1" ]
}

@test "calculates a prerelease increment for the same channel" {
  run calculate_next_tag "v1.2.3-beta.2" "patch" "beta" "" "v"

  [ "$status" -eq 0 ]
  [ "$output" = "v1.2.3-beta.3" ]
}

@test "starts a new prerelease sequence when the channel changes" {
  run calculate_next_tag "v1.2.3-beta.2" "minor" "rc" "" "v"

  [ "$status" -eq 0 ]
  [ "$output" = "v1.3.0-rc.1" ]
}

@test "appends build metadata to the computed tag" {
  run calculate_next_tag "v1.2.3" "patch" "" "sha.abc123" "v"

  [ "$status" -eq 0 ]
  [ "$output" = "v1.2.4+sha.abc123" ]
}

@test "parses labels with a default bump when no bump label is present" {
  parse_labels $'docs\nchore' "version:major" "version:minor" "version:patch" "pre-release:" "build:" "patch"
  [ "$PARSED_BUMP_TYPE" = "patch" ]
}

@test "supports tags without a prefix" {
  run calculate_next_tag "1.2.3" "patch" "" "" ""

  [ "$status" -eq 0 ]
  [ "$output" = "1.2.4" ]
}

@test "rejects multiple bump labels" {
  run parse_labels $'version:major\nversion:patch' "version:major" "version:minor" "version:patch" "pre-release:" "build:" ""

  [ "$status" -eq 1 ]
  [[ "$output" == *"Multiple bump labels were found"* ]]
}

@test "rejects invalid prerelease label values" {
  run parse_labels $'version:patch\npre-release:beta+1' "version:major" "version:minor" "version:patch" "pre-release:" "build:" ""

  [ "$status" -eq 1 ]
  [[ "$output" == *"Invalid prerelease label value"* ]]
}

@test "resolves the latest semver tag and ignores non-semver tags" {
  repo_dir="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$repo_dir"
  git -C "$repo_dir" init >/dev/null
  git -C "$repo_dir" config user.name "test"
  git -C "$repo_dir" config user.email "test@example.com"
  git -C "$repo_dir" commit --allow-empty -m "init" >/dev/null
  git -C "$repo_dir" tag "note"
  git -C "$repo_dir" tag "v1.2"
  git -C "$repo_dir" tag "v1.2.3"
  git -C "$repo_dir" tag "v1.3.0-beta.1"

  run bash -c "cd '$repo_dir' && source '$BATS_TEST_DIRNAME/../lib/log.sh' && source '$BATS_TEST_DIRNAME/../lib/common.sh' && source '$BATS_TEST_DIRNAME/../lib/semver.sh' && source '$BATS_TEST_DIRNAME/../lib/git.sh' && resolve_latest_semver_tag 'v'"

  [ "$status" -eq 0 ]
  [ "$output" = "v1.3.0-beta.1" ]
}
