#!/bin/sh
set -e

git config --global --add safe.directory /github/workspace

# Logging helpers
info() { echo "::notice::ℹ️ $*"; }
success() { echo "::notice::✅ $*"; }
error() { echo "::error::❌ $*"; }

# Required inputs
if [ -z "$INPUT_TOKEN" ]; then
  error "Missing GitHub token. Set the 'token' input."
  exit 1
fi

info "🔧 Setting up Git config"
git config --global user.name "github-actions[bot]"
git config --global user.email "github-actions[bot]@users.noreply.github.com"

# Get PR number if event is a PR
info "🔍 Getting PR number from event payload"
PR_NUMBER=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")

if [ "$PR_NUMBER" = "null" ]; then
  error "This action must be run on pull_request events."
  exit 1
fi

# Get labels from the PR
info "🔍 Fetching PR labels..."
LABELS=$(gh pr view $PR_NUMBER --json labels --jq '.labels[].name')

info "🏷️ PR Labels: $LABELS"

BUMP=""
PRERELEASE=""
BUILD=""

# Parse labels
for LABEL in $LABELS; do
  case "$LABEL" in
    version:major) BUMP="major" ;;
    version:minor) BUMP="minor" ;;
    version:patch) BUMP="patch" ;;
    pre-release:*) PRERELEASE="${LABEL#pre-release:}" ;;
    build:*) BUILD="${LABEL#build:}" ;;
  esac
done

# Default to patch if no version label found
if [ -z "$BUMP" ]; then
  BUMP="patch"
fi

info "📦 Bump type: $BUMP"

info "📥 Fetching tags..."
git fetch --tags

# Get latest tag or fallback to 0.0.0
LATEST_TAG=$(git tag --sort=-v:refname | head -n 1)

if [ -z "$LATEST_TAG" ]; then
  LATEST_TAG="v0.0.0"
fi

info "🏷️ Latest tag: $LATEST_TAG"
VERSION=${LATEST_TAG#v}
IFS='.' read -r MAJOR MINOR PATCH <<EOF
$VERSION
EOF

case "$BUMP" in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"

# Append pre-release and build metadata if present
if [ -n "$PRERELEASE" ]; then
  NEW_VERSION="$NEW_VERSION-$PRERELEASE"
fi
if [ -n "$BUILD" ]; then
  NEW_VERSION="$NEW_VERSION+$BUILD"
fi

NEW_TAG="v$NEW_VERSION"
info "🚀 New tag: $NEW_TAG"

git tag "$NEW_TAG"
git push origin "$NEW_TAG"

success "Tag $NEW_TAG created and pushed."
