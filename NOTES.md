# Build Notes

Things to remember when building actual skills from import material.
Not content — instructions for the skill-building phase.

## Import Status: ✅ COMPLETE

All import material has been processed. The `reference/` directory is the
finished reference library. No further import processing needed.

### What was done

**Top-level files** (all written/reviewed):
- `coding-classic.md` — 37signals-style Rails coding guide
- `coding-phlex.md` — Phlex component/view coding guide
- `coding/api.md` — REST API patterns (distilled from agent)
- `patterns.md` — design patterns (7 pattern types merged from shared/)
- `anti-patterns.md` — code smells and anti-patterns
- `smells.md` — Ruby Science smells with priority order
- `review-architecture.md`, `review-quality.md`, `review-performance.md`,
  `review-testing.md`, `review-security.md` — review dimension references
- `devops.md` — deployment, dev containers, production hardening
- `toolbelt.md` — categorized gem recommendations

**Shared references** (`shared/` — cross-cutting, loaded by multiple skills):
- `architecture.md` — layered architecture (4 layers, rules, violations)
- `authorization.md` — Pundit policies (rewritten from Action Policy)
- `callbacks.md` — callback scoring, extraction signals
- `components.md` — Phlex components (rewritten from ViewComponent)
- `concerns.md` — concern design heuristics
- `configuration.md` — Anyway Config for edge cases (10+ settings)
- `current_attributes.md` — Current usage rules and testing
- `graphql.md` — GraphQL reference (marked as non-preferred)
- `hotwire.md` — Turbo + Stimulus overview, links to hwc-* skills
- `instrumentation.md` — Rails.event (8.1+) as primary event pipeline
- `jobs.md` — ActiveJob + Solid Queue + Continuations (8.1+)
- `notifications.md` — Noticed gem for multi-channel delivery
- `security.md` — not yet rewritten (pre-existing, needs review at build time)
- `serializers.md` — SimpleDelegator + AMS alternative
- `state_machines.md` — AASM (rewritten from Workflow)
- `testing.md` — Minitest, fixtures, test pyramid, per-layer focus

**Refactorings** (`refactorings/` — all complete):
- `000-template.md` through `010-*.md` (9 refactorings + template)
- `extraction-signals.md` — signal → refactoring mapping

**Deleted** (merged or redundant):
- Agent files: `api_specialist.md`, `architect.md`, `controllers.md`,
  `devops.md` (agent), `models.md`, `views.md`, `testing_2.md`
- Pattern files merged into `patterns.md`: `filter_objects.md`,
  `form_objects.md`, `policy_objects.md`, `presenters.md`,
  `query_objects.md`, `repositories.md`, `value_objects.md`

### Conventions applied everywhere

- **Minitest** with fixtures (no RSpec, no factory_bot)
- **Pundit** for authorization (no Action Policy)
- **AASM** for state machines (no Workflow gem)
- **Noticed** for notifications (no Active Delivery)
- **Phlex** for components (no ViewComponent)
- **Solid Queue** for jobs (no Sidekiq as default)
- **Rails.event / EventReporter** (8.1+) as primary event pipeline
- All files cross-referenced where relevant

---

## General Development Workflow

- Always prefer Rails generators over writing boilerplate by hand.
- Prefer a **dev container** setup. See `devops.md § Development Environment`.
- **Implementation order**: models → controllers → views/services → tests.

---

## Bootstrap Skill (`/jr-rails-new`)

A dedicated interactive skill for scaffolding new Rails applications. Interviews
the user for preferences, then runs `rails new` with the right flags and
performs post-scaffold configuration.

### Interview Questions

1. **App name** — free text
2. **Database** — `postgresql` (default) / `mysql2` / `sqlite3`
3. **Frontend bundling** — `importmap` (default) / `esbuild` / `vite_rails`
4. **CSS** — `tailwind` / `sass` / `none`
5. **View layer** — Classic ERB (default) / Phlex
6. **Dev container** — yes (default) / no
7. **Authentication** — `rails g authentication` (Rails 8+) / Devise / none
8. **Testing** — Minitest (default, non-negotiable for jr-rails skills)
9. **Authorization** — Pundit / none
10. **Background jobs** — Solid Queue (default) / Sidekiq
11. **Git worktree workflow** — yes / no (configures `.claude/` worktree helpers)

### Post-scaffold Steps

After `rails new`:

1. If Phlex: add `phlex-rails` gem, generate `ApplicationLayout`, remove ERB layout
2. If Pundit: `bundle add pundit && rails g pundit:install`
3. If authentication: `rails g authentication` or add Devise + configure
4. If dev container: verify `.devcontainer/` exists (Rails 7.2+ generates it)
5. Add `CLAUDE.md` with project conventions pointing to jr-rails skills
6. Add `.claude/settings.json` with worktree config if selected
7. Run `bin/setup` to verify everything boots
8. Initial commit

### Build Notes

- This is a **skill** (interactive), not an agent (read-heavy)
- Should be invocable as `/jr-rails-new` from Claude Code
- The interview uses `AskUserQuestion` for each decision point
- Defaults should match our preferred stack: PostgreSQL, importmap, Tailwind,
  ERB, devcontainer, Minitest, Solid Queue
- After scaffolding, print a summary of what was configured

---

## Frontend

- Review agents should defer to `hwc-*` skills for Stimulus/Turbo mechanics —
  do not duplicate that content in jr-rails agents
- Coding skills (`coding-classic`, `coding-phlex`) cover the Rails-side
  integration only; `shared/hotwire.md` is the connecting reference
- When building coding skills, include a pointer: "for frontend patterns, invoke
  the relevant hwc-* skill alongside this one"
- `coding-classic` pairs with: `hwc-stimulus-fundamentals`, `hwc-navigation-content`,
  `hwc-realtime-streaming`, `hwc-forms-validation`, `hwc-ux-feedback`
- `coding-phlex` pairs with: same hwc skills + Phlex component patterns

## Review Skill: Two Scopes

The review skill should offer two invocation scopes:

1. **Full app review** — runs all review dimensions (architecture, quality,
   performance, testing, security) across the entire codebase. Produces a
   comprehensive report grouped by dimension.
2. **Targeted review** — runs a single dimension against the codebase, matching
   the axes used on RailsReviews: architecture, code quality, performance,
   testing, security. Invocable as e.g. `/jr-rails-review performance`.

Both scopes use the same underlying agents and reference material — the
difference is just which agents are dispatched and how findings are reported.

**TODO (user):** Provide report templates for the following output formats:
- App Audit — Targeted (single-dimension report)
- App Audit — Full (all dimensions, grouped)
- Pull Request review (inline comments + summary)
- GitHub Issue (findings as actionable issue body)

---

## Testing Review Skill: test-prof Integration

The testing review agent should use [test-prof](https://test-prof.evilmartians.io/)
to surface actionable profiling data. Key tools to invoke:

- **TagProf** — tag-based profiling (group by `type:`, custom tags) to find
  slow test categories
- **EventProf** — event-based profiling (`factory.create`, `sql.active_record`,
  `sidekiq.inline`) to find hidden costs
- **StackProf integration** — flamegraph for individual slow tests
- **FactoryProf** — factory cascade detection (factory creates triggering other
  factory creates)
- **RSpecDissect** — `before(:each)` / `let` profiling to find setup-heavy tests

Wire as a sub-workflow: the agent runs test-prof first, then uses the output
to prioritize which tests to flag or convert.

---

## Testing Review Skill: System Test Conversion Workflow

The `review-testing` agent should include a dedicated workflow for trimming excessive
system tests and converting them to faster controller/integration tests.

Two-phase approach (proven in production):

**Phase 1 — Triage**
Agent filters system tests by two signals:
- Low churn: hasn't changed much (git log, commit frequency)
- Low recency: hasn't been touched recently (last modified date)
If *both* signals are negative (high churn AND recently changed) → skip, leave as-is.
Otherwise → add to the TODO list for conversion.

**Phase 2 — Convert**
Agent works through the TODO list, converting each candidate to the appropriate type:
- Testing request/response cycle, redirects, flash → controller test
- Testing cross-controller flows, sessions → integration test
- Testing real browser behavior, JS interaction → keep as system test, remove from list

When building this skill, wire it as a sub-workflow of the review-testing agent,
invocable standalone (e.g. `/jr-rails-review testing:convert-system-tests`) or
as part of a full testing review pass.

---

## From Avo Performance Review

- `active_storage-blurhash` gem (extracted by user from Avo review) → add to
  `patterns.md` under Active Storage and to `coding-classic.md` preferred stack.
  Repo: https://github.com/avo-hq/active_storage-blurhash

- Lazy loading images, explicit width/height for layout shift, blurhash placeholders,
  `<picture>` tag / next-gen image formats → frontend concerns, defer to hwc-* skills.
  Rails-side hook: `preload_link_tag` for hero images is already in review-performance.md.

- The 4-section audit framework (Frontend / Database / Ruby / Environment) is now
  in review-performance.md and should be the scaffolding for the performance review agent.

---

## Gems Still to Add to `toolbelt.md` — ✅ DONE

- ~~`store_model` — Active Model for JSON store attributes (from value_objects.md)~~
- ~~`frozen_record` — query static YAML/JSON like Active Record (from value_objects.md)~~

---

## Blog Posts to Fetch at Skill-Build Time

Fetch these URLs during skill construction and extract relevant content into the
target files listed. Ordered by recency — more recent = higher trust for current Rails versions.

### → patterns.md (already distilled)

- **Advanced Domain Modeling Part 1: Value Objects with `composed_of`** (unpublished)
  **Status: distilled** into patterns.md § Value Objects

- **Advanced Domain Modeling Part 2: Polymorphism with Strategies** (unpublished)
  **Status: distilled** into patterns.md § Strategy Objects and review-architecture.md heuristics

- **Advanced Domain Modeling Part 3: Form Builders and Form Objects** (unpublished)
  **Status: distilled** into patterns.md § Form Objects
  **Pending:** Form builder content (StyledFormBuilder, custom form inputs) → coding-classic.md § View Helpers when expanded

### → patterns.md — ✅ DONE

- **Kredis UI state container** (Mar 15, 2023)
  https://blog.appsignal.com/2023/03/15/a-generalized-user-local-container-for-ui-state-in-kredis.html
  _Reusable Kredis key generation, MutationObserver + Stimulus, server-side rehydration with Nokogiri_
  **Status: distilled** into patterns.md § Kredis UI State Container

- **DCI in Rails** (Jun 14, 2023)
  https://blog.appsignal.com/2023/06/14/setting-up-business-logic-with-dci-in-rails.html
  _Data/Context/Interaction pattern, runtime role injection, alternative to service objects_
  **Status: distilled** into patterns.md § DCI Supplement

- **Custom ActiveStorage analyzers** (Jul 30, 2025)
  https://blog.appsignal.com/2025/07/30/build-custom-activestorage-analyzers-for-ruby-on-rails.html
  _Extending ActiveStorage with custom analyzers, metadata column, analyzer registration order_
  **Status: distilled** into patterns.md § ActiveStorage Custom Analyzers

- **Custom ActiveStorage previewers** (Aug 13, 2025)
  https://blog.appsignal.com/2025/08/13/extend-activestorage-for-ruby-on-rails-with-custom-previewers.html
  _Custom previewers, waveform/blurhash examples, previewer registration_
  **Status: distilled** into patterns.md § ActiveStorage Custom Previewers

### → review-architecture.md — ✅ DONE

- **Organize business logic** (May 10, 2023)
  https://blog.appsignal.com/2023/05/10/organize-business-logic-in-your-ruby-on-rails-application.html
  _Fat models vs service objects vs jobs, event sourcing intro, previews DCI — good anti-pattern overview_
  **Status: confirmed** — already covered in review-architecture.md, no changes needed

### → review-performance.md — ✅ DONE

- **Missing PostgreSQL indexes** (railsreviews.com)
  https://www.railsreviews.com/articles/missing-postgres-indexes
  **Status: distilled** into review-performance.md § Database Index Diagnostics

- **Avo performance audit** (railsreviews.com)
  https://www.railsreviews.com/case-studies/avo
  **Status: distilled** into review-performance.md (multiple sections)

- **HTTP caching in Rails** (Aug 14, 2024)
  https://blog.appsignal.com/2024/08/14/an-introduction-to-http-caching-in-ruby-on-rails.html
  **Status: distilled** into review-performance.md § HTTP Caching / Cache-Control Headers

- **PostgreSQL full-text search 300x speedup** (2024)
  https://www.rorvswild.com/blog/2024/speed-up-compound-full-text-searches-in-postgresql-by-300x
  **Status: distilled** into review-performance.md § Full-text Search via Materialized View

- **Async pagination queries** (2025)
  https://www.rorvswild.com/blog/2025/optimize-pagination-speed-with-asynchronous-queries-in-ruby-on-rails
  **Status: distilled** into review-performance.md § Pagy Async Count

### → devops.md — ✅ DONE

- **Feature flags with AppSignal** (Oct 2, 2024)
  https://blog.appsignal.com/2024/10/02/measuring-the-impact-of-feature-flags-in-ruby-on-rails-with-appsignal.html
  **Status: distilled** into devops.md § Feature Flags

- **Dev containers for Rails** (2025)
  https://www.rorvswild.com/blog/2025/dev-containers-rails
  **Status: distilled** into devops.md § Development Environment

- **Feature flags comprehensive guide** (undated, cloud66)
  https://blog.cloud66.com/how-to-add-feature-flags-to-your-ruby-on-rails-applications
  **Status: distilled** into devops.md § Feature Flags

- **Native vs containerized deployment** (~2024, cloud66)
  https://blog.cloud66.com/pros-and-cons-of-deploying-rails-applications-natively-vs-containerized-in-2024
  **Status: distilled** into devops.md § Deployment

### → defer to hwc-* skills (do not duplicate)

- **Hotwire/Turbo guide** (undated, cloud66) — already covered by hwc skills

---

## Ruby Science Principles — ✅ DONE

Created `reference/shared/principles.md` with all 7 principles, concise
descriptions, and principle → smell mappings for review agent wiring.

---

## Ruby Science Smells — ✅ All Done

All 8 smells (God Class + 7 Ruby Science) exist in `smells.md` with links
and Fix pointers. Review agent should order findings by priority (0–7).

## Ruby Science Refactorings — ✅ All Done

All 9 refactoring files (002–010) exist in `refactorings/`. Review agent
should prefer higher-priority refactorings when multiple apply.

**Smell → refactoring mapping** (for review agent wiring):
- Divergent Change → Replace Conditional with Polymorphism, Replace Subclasses with Strategies
- Shotgun Surgery → Replace Conditional with Polymorphism, Introduce Parameter Object
- Feature Envy → Extract Validator, Introduce Form Object
- Case Statement → Replace Conditional with Polymorphism, Replace Conditional with Null Object
- Long Parameter List → Introduce Parameter Object
- Large Class → Introduce Form Object, Replace Mixin with Composition
- Callback → Replace Callback with Method
- God Class → Introduce Form Object, Replace Mixin with Composition, Replace Subclasses with Strategies, Replace Conditional with Polymorphism, Rename Service Object to Domain Model

---

## Worktree + Devcontainer for Agentic Coding — ✅ DONE

Implemented in `reference/agentic-worktrees.md` with:
- Worktrunk config (`.config/wt.toml`) with `[post-create]`, `[pre-remove]`, `[post-remove]`, `[post-start]` hooks
- Three binstubs: `bin/agent-setup`, `bin/agent-server`, `bin/agent-cleanup`
- Port allocation via worktrunk's `hash_port` filter (10000–19999)
- Three strategies: SQLite, PostgreSQL port-based, PostgreSQL + Docker Compose
- Devcontainer variant (`.devcontainer/agent.json`)
- Database isolation via workspace-prefixed files (SQLite) or suffixed DB names (PostgreSQL)
- Cross-referenced from `devops.md` and expanded in `jr-rails-new` SKILL.md step 3g

---

## Symlink Reminder

Skills are not yet symlinked into `~/.claude/skills/`. Do this after the first
skill is built and functional, not before.

---

## Distribution — ✅ DECIDED

### Classification

| Skill | Visibility | Reason |
|-------|-----------|--------|
| jr-rails-classic | PUBLIC | Coding guide |
| jr-rails-new | PUBLIC | Scaffolder |
| jr-rails-phlex | PUBLIC | Phlex guide |
| jr-rails-review | PRIVATE | Premium review agent |

### Reference material split

All of `reference/` goes public EXCEPT `review-*.md` files (5 files).
Anti-patterns, smells, refactorings are included — needed by jr-rails-classic.

### Public repo: `julianrubisch/skills`

- Published via `scripts/publish.sh --public` (resolves symlinks, strips
  private content, generates marketplace.json)
- Synced via `scripts/sync-public.sh` and `.github/workflows/sync-public.yml`
- Install: `npx skills add julianrubisch/skills`
