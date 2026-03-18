# Tag SemVer on Merge

Create the next Semantic Version tag from pull request labels after a merge.

This Docker-based GitHub Action is designed for repositories that want version tags to be created automatically when pull requests are merged into release branches such as `main` or `master`. The action reads PR labels, finds the latest existing SemVer tag, computes the next tag, and pushes it back to the repository.

## What it does

- Runs on merged pull requests
- Restricts tagging to configured base branches
- Reads one bump label from the pull request
- Optionally reads prerelease and build metadata labels
- Finds the latest existing SemVer tag and ignores unrelated tags
- Computes the next SemVer tag and pushes it
- Supports a `dry-run` mode for safe validation

## Prerequisites

- The workflow must run on a `pull_request` `closed` event
- The job needs these permissions:
  - `contents: write`
  - `pull-requests: read`
- The repository checkout must include tags

## Quick Start

```yaml
name: Tag on Merge

on:
  pull_request:
    types: [closed]

jobs:
  tag:
    if: github.event.pull_request.merged == true
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: read
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
          fetch-tags: true

      - name: Create SemVer tag
        uses: leo-oliveira-eng/tag-semver@v1
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
```

## Label Contract

Use exactly one bump label on each pull request:

- `version:major`
- `version:minor`
- `version:patch`

Optional labels:

- `pre-release:<channel>`
- `build:<metadata>`

Examples:

- `version:patch` -> `v1.2.4`
- `version:minor` + `pre-release:beta` -> `v1.3.0-beta.1`
- `version:patch` + `build:sha.abc123` -> `v1.2.4+sha.abc123`
- `version:minor` + `pre-release:rc` + `build:run.42` -> `v1.3.0-rc.1+run.42`

## Inputs

| Input | Required | Default | Description |
| --- | --- | --- | --- |
| `token` | Yes | - | GitHub token with `contents:write` and `pull-requests:read`. |
| `allowed-base-branches` | No | `main,master` | Comma-separated base branches allowed to create tags. |
| `tag-prefix` | No | `v` | Prefix added to generated tags. Use an empty string to disable it. |
| `major-label` | No | `version:major` | Label used for major bumps. |
| `minor-label` | No | `version:minor` | Label used for minor bumps. |
| `patch-label` | No | `version:patch` | Label used for patch bumps. |
| `prerelease-label-prefix` | No | `pre-release:` | Prefix for prerelease labels. |
| `build-label-prefix` | No | `build:` | Prefix for build metadata labels. |
| `default-bump` | No | empty | Fallback bump when no bump label is present. |
| `dry-run` | No | `false` | Compute outputs without creating or pushing a tag. |

## Outputs

| Output | Description |
| --- | --- |
| `previous-tag` | Latest SemVer tag found before the new calculation. |
| `next-tag` | Computed next tag. |
| `base-branch` | Base branch from the merged pull request. |
| `bump-type` | Selected bump type. |
| `prerelease` | Selected prerelease channel. |
| `build-metadata` | Selected build metadata value. |
| `tag-created` | `true` when the tag was created and pushed. |

## SemVer Examples

| Latest tag | Labels | Result |
| --- | --- | --- |
| `v0.0.0` | `version:patch` | `v0.0.1` |
| `v1.2.3` | `version:minor` | `v1.3.0` |
| `v1.2.3` | `version:major` | `v2.0.0` |
| `v1.2.3` | `version:patch`, `pre-release:beta` | `v1.2.4-beta.1` |
| `v1.2.3-beta.1` | `version:patch`, `pre-release:beta` | `v1.2.3-beta.2` |
| `v1.2.3` | `version:patch`, `build:sha.abc123` | `v1.2.4+sha.abc123` |
| `1.2.3` | `version:patch` and `tag-prefix: ""` | `1.2.4` |

## Usage Examples

### Default `main,master` branches

```yaml
- uses: leo-oliveira-eng/tag-semver@v1
  with:
    token: ${{ secrets.GITHUB_TOKEN }}
```

### Custom branch list

```yaml
- uses: leo-oliveira-eng/tag-semver@v1
  with:
    token: ${{ secrets.GITHUB_TOKEN }}
    allowed-base-branches: release,stable
```

### Custom label names and prefixes

```yaml
- uses: leo-oliveira-eng/tag-semver@v1
  with:
    token: ${{ secrets.GITHUB_TOKEN }}
    major-label: semver:major
    minor-label: semver:minor
    patch-label: semver:patch
    prerelease-label-prefix: prerelease/
    build-label-prefix: build/
```

### Dry-run validation

```yaml
- uses: leo-oliveira-eng/tag-semver@v1
  id: semver
  with:
    token: ${{ secrets.GITHUB_TOKEN }}
    dry-run: true

- name: Inspect computed tag
  run: echo "Next tag is ${{ steps.semver.outputs.next-tag }}"
```

## Failure Modes

The action fails with a clear error when:

- the event payload is not a pull request
- the pull request is missing a bump label and no default bump is configured
- more than one bump label is found
- more than one prerelease label is found
- more than one build metadata label is found
- prerelease or build metadata values are invalid
- the computed tag already exists
- the latest matching tag cannot be parsed as SemVer

When the pull request is closed without merge, or the base branch is not allowed, the action exits successfully and sets `tag-created=false`.

## Troubleshooting

- If no tags are found, the action starts from `v0.0.0` or `0.0.0` when `tag-prefix` is empty.
- If tags are missing in the runner, verify `actions/checkout` uses `fetch-depth: 0` and `fetch-tags: true`.
- If label lookup fails, confirm the job has `pull-requests: read`.
- If push fails, confirm the token has permission to create tags on the repository.

## Marketplace Publishing Note

GitHub Marketplace requires the published action to live in a clean public repository that contains only the action files. This repository can stay as the development repository with tests and workflows, while a separate public repository is used for Marketplace publication. A maintainer guide for that setup is available in [docs/releasing.md](docs/releasing.md).

The publishable action files now include the root `entrypoint.sh` plus the `lib/` directory that contains the runtime modules.
