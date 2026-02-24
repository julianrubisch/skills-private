# Build Notes

Things to remember when distilling import material into actual skills.
Not content — instructions for the skill-building phase.

## Frontend

- Review agents should defer to `hwc-*` skills for Stimulus/Turbo mechanics —
  do not duplicate that content in jr-rails agents
- Coding skills (`37signals`, `phlex`) cover the Rails-side integration only;
  the `## Frontend` section in each import file contains those notes
- When building coding skills, include a pointer: "for frontend patterns, invoke
  the relevant hwc-* skill alongside this one"
- `37signals` style pairs with: `hwc-stimulus-fundamentals`, `hwc-navigation-content`,
  `hwc-realtime-streaming`, `hwc-forms-validation`, `hwc-ux-feedback`
- `phlex` style pairs with: same hwc skills + any Phlex-specific component patterns
  from the import file

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

## Blog Posts to Fetch at Skill-Build Time

Fetch these URLs during skill construction and extract relevant content into the
target files listed. Ordered by recency — more recent = higher trust for current Rails versions.

### → patterns.md

- **Kredis UI state container** (Mar 15, 2023)
  https://blog.appsignal.com/2023/03/15/a-generalized-user-local-container-for-ui-state-in-kredis.html
  _Reusable Kredis key generation, MutationObserver + Stimulus, server-side rehydration with Nokogiri_

- **DCI in Rails** (Jun 14, 2023)
  https://blog.appsignal.com/2023/06/14/setting-up-business-logic-with-dci-in-rails.html
  _Data/Context/Interaction pattern, runtime role injection, alternative to service objects_

- **Custom ActiveStorage analyzers** (Jul 30, 2025)
  https://blog.appsignal.com/2025/07/30/build-custom-activestorage-analyzers-for-ruby-on-rails.html
  _Extending ActiveStorage with custom analyzers, metadata column, analyzer registration order_

- **Custom ActiveStorage previewers** (Aug 13, 2025)
  https://blog.appsignal.com/2025/08/13/extend-activestorage-for-ruby-on-rails-with-custom-previewers.html
  _Custom previewers, waveform/blurhash examples, previewer registration_

### → review-architecture.md

- **Organize business logic** (May 10, 2023)
  https://blog.appsignal.com/2023/05/10/organize-business-logic-in-your-ruby-on-rails-application.html
  _Fat models vs service objects vs jobs, event sourcing intro, previews DCI — good anti-pattern overview_

### → review-performance.md

- **Missing PostgreSQL indexes** (railsreviews.com)
  https://www.railsreviews.com/articles/missing-postgres-indexes
  _Two diagnostic SQL queries worth embedding directly in the agent as runnable tools:_
  _1. `pg_stat_all_tables`: seq_scan vs idx_scan delta, 80KB threshold to skip small tables_
  _2. `pg_statio_user_tables`: index efficiency as cache hit ratio, sort ASC to find worst offenders_
  _Key heuristic: only flag tables > 80,000 bytes — sequential scans beat indexes on small tables_

- **Avo performance audit** (railsreviews.com) ⚠️ more source files coming from user
  https://www.railsreviews.com/case-studies/avo
  _Real-world audit — extract into review-performance.md AND review-quality.md:_
  _Performance: N+1 on index/show routes, ActiveStorage attachments missing eager loading_
  _Quality: unmemoized metaprogramming vars (class_name etc.), file I/O in hot paths without caching_
  _Results are concrete benchmarks — useful as "what fixing this looks like" examples_
  _Frontend findings (lazy loading, hero preload, Lighthouse 81→98) → defer to hwc skills_

- **HTTP caching in Rails** (Aug 14, 2024)
  https://blog.appsignal.com/2024/08/14/an-introduction-to-http-caching-in-ruby-on-rails.html
  _Cache-Control, ETags, fresh_when, expires_in, cache leak prevention via etag { current_user&.id }_

- **PostgreSQL full-text search 300x speedup** (2024)
  https://www.rorvswild.com/blog/2024/speed-up-compound-full-text-searches-in-postgresql-by-300x
  _Materialized views, GIN indexes, scenic gem, sync via callbacks + background jobs_

- **Async pagination queries** (2025)
  https://www.rorvswild.com/blog/2025/optimize-pagination-speed-with-asynchronous-queries-in-ruby-on-rails
  _load_async, async count with Pagy, connection pool caveats with Sidekiq_

### → devops.md

- **Feature flags with AppSignal** (Oct 2, 2024)
  https://blog.appsignal.com/2024/10/02/measuring-the-impact-of-feature-flags-in-ruby-on-rails-with-appsignal.html
  _Flipper + AppSignal, percentage rollouts, measuring latency/conversion impact_

- **Dev containers for Rails** (2025)
  https://www.rorvswild.com/blog/2025/dev-containers-rails
  _devcontainer.json, compose.yaml, Features/Templates, VS Code + CLI + Codespaces, MCP integration_

- **Feature flags comprehensive guide** (undated, cloud66)
  https://blog.cloud66.com/how-to-add-feature-flags-to-your-ruby-on-rails-applications
  _Flipper deep-dive, actors/groups/percentage strategies, Prometheus/Grafana measurement_

- **Native vs containerized deployment** (~2024, cloud66)
  https://blog.cloud66.com/pros-and-cons-of-deploying-rails-applications-natively-vs-containerized-in-2024
  _Kamal/Docker/PaaS/Kubernetes tradeoffs, team size considerations, monorepo vs multi-repo_

### → defer to hwc-* skills (do not duplicate)

- **Hotwire/Turbo guide** (undated, cloud66)
  https://blog.cloud66.com/the-ultimate-guide-to-implementing-hotwired-and-turbo-in-a-rails-application
  _Turbo Drive/Frames/Streams, morphing, modal validation, caching — well covered by hwc skills already_

## Ruby Science Principles — Priority Order

Principles are the *why* behind smells and refactorings. At skill-build time,
create `import/shared/principles.md` with each principle described concisely.
Review agents load this file and **cite the violated principle** when flagging
a smell — highest priority principle cited first when multiple apply.

| Priority | Principle | Ruby Science | Coverage in import files |
|----------|-----------|--------------|--------------------------|
| 1 | Tell, Don't Ask | https://thoughtbot.com/ruby-science/tell-dont-ask.html | ⚠️ implicit in Feature Envy smell and CQS smell — not named explicitly |
| 2 | Composition over Inheritance | https://thoughtbot.com/ruby-science/composition-over-inheritance.html | ⚠️ implicit in DCI + concerns patterns — not named explicitly |
| 3 | Single Responsibility Principle | https://thoughtbot.com/ruby-science/single-responsibility-principle.html | ⚠️ implicit throughout review-architecture.md (fat models, model SRP) — not named explicitly |
| 4 | Dependency Inversion Principle | https://thoughtbot.com/ruby-science/dependency-inversion-principle.html | ❌ missing |
| 5 | Open/Closed Principle | https://thoughtbot.com/ruby-science/openclosed-principle.html | ❌ missing |
| 6 | Law of Demeter | https://thoughtbot.com/ruby-science/law-of-demeter.html | ⚠️ smells.md has Inappropriate Intimacy (related) — not named explicitly |
| 7 | DRY | https://thoughtbot.com/ruby-science/dry.html | ⚠️ implicit in Shotgun Surgery, Divergent Change, named scopes — not named explicitly |

**Build instructions:**
- Fetch each URL and distill into `import/shared/principles.md` — one section
  per principle with a 2–3 sentence description and the Ruby Science link.
- For ⚠️ entries: name the principle explicitly and link to the existing smell
  or pattern that embodies it.
- Wire each principle to the smells it governs (see mapping below) so the
  review agent can say: "This violates SRP — see Large Class smell."
- `shared/principles.md` is loaded by all review agents, not just one.

**Principle → smell mapping** (for review agent wiring):
- Tell, Don't Ask → Feature Envy, CQS Violation
- Composition over Inheritance → Large Class, Callback, Long Case Statement
- Single Responsibility Principle → Divergent Change, Large Class, Callback
- Dependency Inversion Principle → Feature Envy, Inappropriate Intimacy
- Open/Closed Principle → Case Statement, Long Case Statement
- Law of Demeter → Inappropriate Intimacy, Feature Envy
- DRY → Shotgun Surgery, Divergent Change

---

## Ruby Science Smells — Priority Order

At skill-build time, ensure every smell below exists in `smells.md` with a
Ruby Science link. The review agent should surface findings **in this priority
order** — highest priority first.

| Priority | Smell | Ruby Science | Status in smells.md |
|----------|-------|--------------|----------------------|
| 1 | Divergent Change | https://thoughtbot.com/ruby-science/divergent-change.html | ✅ exists — add link |
| 2 | Shotgun Surgery | https://thoughtbot.com/ruby-science/shotgun-surgery.html | ✅ exists — add link |
| 3 | Feature Envy | https://thoughtbot.com/ruby-science/feature-envy.html | ✅ exists — add link |
| 4 | Case Statement | https://thoughtbot.com/ruby-science/case-statement.html | ✅ exists as "Long Case Statement" — align name, add link |
| 5 | Long Parameter List | https://thoughtbot.com/ruby-science/long-parameter-list.html | ✅ exists as "Too Many Parameters" — align name, add link |
| 6 | Large Class | https://thoughtbot.com/ruby-science/large-class.html | ✅ exists — add link |
| 7 | Callback | https://thoughtbot.com/ruby-science/callback.html | ❌ missing — add entry |

**Build instructions:**
- Fetch each URL and merge any Ruby Science content that extends what's already
  in smells.md. Don't replace existing entries — augment them.
- Add `_[Ruby Science →](url)_` link at the end of each smell's description.
- The Callback smell needs a full new entry. Ruby Science covers callbacks as a
  smell when they increase complexity or introduce hidden side effects — fetch
  the page and distill into smells.md.
- When the review agent reports findings, order them by this priority table.
  If only one smell is present, still cite its priority level.

---

## Ruby Science Refactorings — Priority Order

At skill-build time, ensure every refactoring below has an entry in
`import/refactorings/`. The review agent should recommend fixes **in this
priority order** when multiple apply.

| Priority | Refactoring | Ruby Science | Status |
|----------|-------------|--------------|--------|
| 1 | Replace Conditional with Polymorphism | https://thoughtbot.com/ruby-science/replace-conditional-with-polymorphism.html | ❌ missing |
| 2 | Replace Conditional with Null Object | https://thoughtbot.com/ruby-science/replace-conditional-with-null-object.html | ❌ missing |
| 3 | Introduce Form Object | https://thoughtbot.com/ruby-science/introduce-form-object.html | ⚠️ patterns.md has Form Objects — create refactoring file cross-referencing it |
| 4 | Replace Subclasses with Strategies | https://thoughtbot.com/ruby-science/replace-subclasses-with-strategies.html | ❌ missing |
| 5 | Replace Mixin with Composition | https://thoughtbot.com/ruby-science/replace-mixin-with-composition.html | ❌ missing |
| 6 | Extract Validator | https://thoughtbot.com/ruby-science/extract-validator.html | ⚠️ patterns.md has Rule Objects (related but distinct) — create refactoring file, note the overlap |
| 7 | Introduce Parameter Object | https://thoughtbot.com/ruby-science/introduce-parameter-object.html | ⚠️ patterns.md has Value Objects (related but distinct) — create refactoring file, clarify difference |
| 8 | Replace Callback with Method | https://thoughtbot.com/ruby-science/replace-callback-with-method.html | ⚠️ coding-classic.md and review-architecture.md cover callbacks — create refactoring file cross-referencing both |

**Build instructions:**
- Fetch each URL and create a numbered file in `import/refactorings/`
  following the template in `000-template.md`.
- For ⚠️ entries: link to the existing pattern/section rather than duplicating.
  The refactoring file answers "how to get from bad to good"; patterns.md
  answers "what good looks like."
- Add `_[Ruby Science →](url)_` to each refactoring file.
- When the review agent proposes a fix, prefer refactorings higher in this list
  when more than one applies to a given smell.

**Smell → refactoring mapping** (for review agent wiring):
- Divergent Change → Replace Conditional with Polymorphism, Replace Subclasses with Strategies
- Shotgun Surgery → Replace Conditional with Polymorphism, Introduce Parameter Object
- Feature Envy → Extract Validator, Introduce Form Object
- Case Statement → Replace Conditional with Polymorphism, Replace Conditional with Null Object
- Long Parameter List → Introduce Parameter Object
- Large Class → Introduce Form Object, Replace Mixin with Composition
- Callback → Replace Callback with Method

---

## Symlink Reminder

Skills are not yet symlinked into `~/.claude/skills/`. Do this after the first
skill is built and functional, not before.
