# Releasing and Marketplace Sync

This repository is the development repository for the action. It contains workflows, tests, and maintainer automation, so it is not the repository that should be published directly to GitHub Marketplace.

## Recommended Repository Layout

- Development repository:
  - source files
  - tests
  - CI workflows
  - release automation
- Marketplace repository:
  - `action.yml`
  - `Dockerfile`
  - `entrypoint.sh`
  - `lib/`
  - `README.md`
  - `LICENSE`

## Required Secrets

Configure these repository secrets in the development repository:

- `MARKETPLACE_REPO`: target repository in `owner/name` format
- `MARKETPLACE_TOKEN`: personal access token with permission to push to the Marketplace repository

## Validation Before Publishing

The `Validate Action` workflow automatically runs:

- `shellcheck`
- `shfmt`
- `bats` unit and integration tests
- `docker build`

Only publish from a validated commit or release tag.

## Sync Process

The `Sync Marketplace Repository` workflow:

1. Checks out this development repository.
2. Checks out the target Marketplace repository.
3. Copies only the publishable action files into the target repo.
4. Commits and pushes file changes.
5. Creates and pushes the same release tag in the target repo when triggered from a release.

The file export is handled by `scripts/export-marketplace-files.sh`.

## Suggested Release Flow

1. Merge changes into `main`.
2. Wait for the validation workflow to pass.
3. Create a GitHub release in this development repository.
4. Let the sync workflow update the Marketplace repository.
5. Publish the Marketplace listing from the clean public action repository.

## Notes

- The Marketplace repository should contain only the files needed to run the action.
- Keep the action name in `action.yml` unique before publishing.
- If you want to test the action end-to-end against a real repository, use a dedicated sandbox repository rather than the Marketplace repository itself.
