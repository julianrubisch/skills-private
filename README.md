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
2. Build skills from import material ← **next**
3. Symlink skill directories into `~/.claude/skills/`

## Conventions

- **Minitest** with fixtures (not RSpec, not factory_bot)
- **Pundit** for authorization
- **AASM** for state machines
- **Noticed** for notifications
- **Phlex** for components
- **Solid Queue** for background jobs
- **Rails.event** (8.1+) as primary event pipeline
- Hotwire frontend defers to `hwc-*` skills
