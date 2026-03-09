# jr-rails-skills

Personal Rails coding and review skills for Claude Code.

## Status

Import phase complete. Reference library in `reference/` is finished and ready
for skill building.

## Structure

```
reference/
  coding-classic.md          # 37signals-style Rails coding guide
  coding-phlex.md            # Phlex component/view coding guide
  coding/
    api.md                   # REST API patterns
  patterns.md                # Design patterns (7 types)
  anti-patterns.md           # Code smells and anti-patterns
  smells.md                  # Ruby Science smells (prioritized)
  review-architecture.md     # Architecture review dimension
  review-quality.md          # Code quality review dimension
  review-performance.md      # Performance review dimension
  review-testing.md          # Testing review dimension
  review-security.md         # Security review dimension
  devops.md                  # Deployment, dev containers, production
  toolbelt.md                # Categorized gem recommendations
  shared/                    # Cross-cutting references (loaded by multiple skills)
    architecture.md          # Layered architecture
    authorization.md         # Pundit policies
    callbacks.md             # Callback scoring, extraction
    components.md            # Phlex components
    concerns.md              # Concern design heuristics
    configuration.md         # Anyway Config (edge case)
    current_attributes.md    # Current usage rules
    graphql.md               # GraphQL (non-preferred, reference only)
    hotwire.md               # Turbo + Stimulus overview
    instrumentation.md       # Rails.event (8.1+) event pipeline
    jobs.md                  # ActiveJob + Solid Queue + Continuations
    notifications.md         # Noticed gem
    security.md              # Security reference
    serializers.md           # SimpleDelegator + AMS
    state_machines.md        # AASM
    testing.md               # Minitest, fixtures, test pyramid
  refactorings/              # 9 refactoring recipes (002-010) + signals
    extraction-signals.md    # Signal → refactoring mapping
    000-template.md
    001-010-*.md
```

## Workflow

1. ~~Fill in the `reference/` files~~ ✅ Done
2. Build skills from reference material ← **in progress**
3. Symlink skill directories into `~/.claude/skills/`

## Installation (Local)

Each skill lives in `skills/<name>/` and contains a `SKILL.md` plus a
`reference` symlink pointing to `../../reference/`. To install a skill:

```bash
ln -s /path/to/jr-rails-skills/skills/jr-rails-classic ~/.claude/skills/jr-rails-classic
```

The `reference/` symlink resolves through the filesystem — Claude's Read
tool follows symlinks transparently.

## Publishing to the Public Marketplace

Public skills are published to [`julianrubisch/skills`](https://github.com/julianrubisch/skills).

### Automated (on push to main)

The GitHub Action `.github/workflows/sync-public.yml` automatically syncs
public skills on every push to `main`.

### Manual

1. Build the public distribution:
   ```bash
   ./scripts/publish.sh --public dist-public/
   ```
2. Verify output (no review-*.md, no jr-rails-review):
   ```bash
   ls dist-public/
   find dist-public -name "review-*.md"  # should return nothing
   ```
3. Push to public repo:
   ```bash
   ./scripts/sync-public.sh
   ```

### Adding a New Public Skill

1. Create the skill in `skills/<name>/SKILL.md`
2. Add the skill name to `PUBLIC_SKILLS` in `scripts/publish.sh`
3. Add an entry to `.claude-plugin/marketplace.json`
4. Push to main — the sync action handles the rest

### Keeping a Skill Private

Simply don't add it to `PUBLIC_SKILLS` in `scripts/publish.sh`.
Private reference files are listed in `PRIVATE_REFERENCE_PATTERNS`.

### Full Distribution (all skills, private)

For local/private distribution with all skills including jr-rails-review:

```bash
./scripts/publish.sh           # outputs to dist/
./scripts/publish.sh /tmp/out  # custom output dir
```

This uses `cp -rL` to follow symlinks and produce self-contained skill
directories that work without the repo.

## Conventions

- **Minitest** with fixtures (not RSpec, not factory_bot)
- **Pundit** for authorization
- **AASM** for state machines
- **Noticed** for notifications
- **Phlex** for components
- **Solid Queue** for background jobs
- **Rails.event** (8.1+) as primary event pipeline
- Hotwire frontend defers to `hwc-*` skills
