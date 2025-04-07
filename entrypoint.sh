#!/bin/sh
set -e

git config --global --add safe.directory /github/workspace

echo "🔧 Setting up Git config"
git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"

echo "🔍 Getting PR number from event payload"
PR_NUMBER=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")

echo "🔍 Fetching PR labels..."
LABELS=$(gh pr view "$PR_NUMBER" --json labels --jq '.labels[].name')

echo "🏷️ PR Labels: $LABELS"

if echo "$LABELS" | grep -q "semver:major"; then
  BUMP="major"
elif echo "$LABELS" | grep -q "semver:minor"; then
  BUMP="minor"
else
  BUMP="patch"
fi

echo "📦 Bump type: $BUMP"

echo "📥 Fetching tags..."
git fetch --tags

LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
echo "🏷️ Latest tag: $LATEST_TAG"

VERSION=$(echo "$LATEST_TAG" | sed 's/^v//')
MAJOR=$(echo "$VERSION" | cut -d. -f1)
MINOR=$(echo "$VERSION" | cut -d. -f2)
PATCH=$(echo "$VERSION" | cut -d. -f3)

MAJOR=${MAJOR:-0}
MINOR=${MINOR:-0}
PATCH=${PATCH:-0}

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

NEW_TAG="v$MAJOR.$MINOR.$PATCH"
echo "🚀 New tag: $NEW_TAG"

git tag "$NEW_TAG"
git push origin "$NEW_TAG"
