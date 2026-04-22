# jr-rails-skills

Private repo for Rails development and review skills, published to
julianrubisch/skills (public marketplace).

## Versioning and Changelog

**When changing any public skill or reference doc, update `CHANGELOG.md`.**

- Add a bullet under `## Unreleased` describing the change
- When cutting a release, rename `## Unreleased` to `## vX.Y.Z`, bump the
  `version` field in `.claude-plugin/marketplace.json`, and add a fresh
  `## Unreleased` section above it
- `scripts/sync-public.sh` extracts the current version's section from
  `CHANGELOG.md` and uses it as the GitHub release body
- Private-only changes (e.g. jr-rails-review, NOTES.md) do not need
  changelog entries

## Publishing

```bash
# Sync to public repo (creates a GitHub release if version bumped)
./scripts/sync-public.sh

# Build dist locally without pushing
./scripts/publish.sh --public dist/
```

## Repo Structure

- `skills/` — skill definitions (SKILL.md + symlinked reference/)
- `reference/` — shared reference docs (symlinked into each skill)
- `.claude-plugin/marketplace.json` — marketplace manifest (source of truth)
- `scripts/publish.sh` — build public distribution
- `scripts/sync-public.sh` — sync to julianrubisch/skills + create releases
