---
name: jr-rails-review
description: >-
  Review Rails code across 5 dimensions: architecture, quality, performance,
  testing, security. Run all or target one. Use for audits and PR reviews.
---

# Rails Code Review

Systematic review of Rails applications across five dimensions. Can run a full
audit (all dimensions) or target a single dimension.

## Invocation

- `/jr-rails-review` — full audit, all 5 dimensions
- `/jr-rails-review architecture` — architecture only
- `/jr-rails-review quality` — code quality only
- `/jr-rails-review performance` — performance only
- `/jr-rails-review testing` — testing only
- `/jr-rails-review security` — security only

## Workflow

### 1. Scope

Determine scope from user input:

- **Full audit** (no argument): run all 5 dimensions sequentially
- **Targeted** (one argument): run only that dimension
- **PR review**: if given a PR number or diff, review only changed files

### 2. Gather Context

Before reviewing, read these files to understand the app:

```
Gemfile
config/routes.rb
db/schema.rb (first 200 lines)
app/models/application_record.rb
app/controllers/application_controller.rb
```

### 3. Run Dimensions

For each dimension in scope, read the corresponding reference file, then
systematically scan the codebase for the patterns and anti-patterns described.

### 4. Report

Group findings by dimension. For each finding:

```markdown
### [Dimension] — [Finding Title]

**Severity:** Critical / High / Medium / Low
**File:** `app/models/user.rb:42`
**Issue:** [What's wrong]
**Fix:** [How to fix it]
```

Order findings: Critical → High → Medium → Low within each dimension.

---

## Hard Rules

**NEVER suggest service objects as a solution.** Do not recommend extracting
logic into `app/services/`, classes ending in `Service`, `Manager`, `Handler`,
`Processor`, or `Creator`, or single-method `.call` objects. These are
explicitly discouraged by this project's architecture.

When logic needs extraction, suggest one of these alternatives instead:
- **Domain model** (`ActiveModel::Model` PORO in `app/models/`) — name it after
  the noun, not the verb (`Registration`, not `UserRegistrationService`)
- **Form object** — for multi-model validation and persistence
- **Query object** — for complex query composition
- **Concern** — for shared behavior across models
- **DCI context** — for multi-model orchestration
- **Callback extraction** — replace callbacks with explicit method calls

See `reference/patterns.md` and
`reference/refactorings/010-refactor-service-object-into-poro.md` for details.

---

## Dimensions

### Architecture

**Focus:** Layer violations, REST adherence, domain modeling, authorization placement.

**Scan for:**
- Service objects that should be domain models (`app/services/` directory)
- Custom controller actions beyond CRUD (non-RESTful routes)
- Business logic in jobs (job `perform` > 5 lines)
- Authorization inline in controllers (bare `find(params[:id])` without scope)
- Fat models (> 200 lines without concerns)
- `Current.*` in model method bodies (hidden dependency)
- Controllers with > 7 public actions

**Reference:** [reference/review-architecture.md](reference/review-architecture.md)

**Cross-references:**
- [reference/anti-patterns.md](reference/anti-patterns.md)
- [reference/smells.md](reference/smells.md)
- [reference/shared/architecture.md](reference/shared/architecture.md)
- [reference/shared/callbacks.md](reference/shared/callbacks.md)
- [reference/refactorings/extraction-signals.md](reference/refactorings/extraction-signals.md)

### Code Quality

**Focus:** Ruby idioms, naming, memoization, scope hygiene, control coupling.

**Scan for:**
- Inline query logic in controllers (`.where(...)` chains)
- Unmemoized expensive accessors (file I/O, metaprogramming without `||=`)
- `Time.now` instead of `Time.current`
- `gsub` where `tr` or `delete` suffices
- `rescue nil` instead of safe navigation (`&.`)
- Boolean flag arguments (control coupling)
- View code in models (`tag.`, `content_tag`, `link_to` in `app/models/`)
- `self.class.name` derivations without memoization

**Reference:** [reference/review-quality.md](reference/review-quality.md)

### Performance

**Focus:** N+1 queries, missing indexes, caching, eager loading, async queries.

**Scan for:**
- N+1 queries (associations in loops without `includes`)
- ActiveStorage N+1 (missing `with_attached_*` or `includes(x_attachment: :blob)`)
- Missing HTTP caching (`fresh_when`, `expires_in`) — check for `Cache-Control` leaks on user-specific pages served with `public: true`
- `.count` on loaded relations (should be `.size`)
- Ruby filtering/sorting that should be SQL (`Model.all.select`, `.all.map`)
- Foreign key columns without indexes
- Polymorphic columns without composite indexes
- `validates :uniqueness` without database unique index
- Synchronous Pagy count on large tables — should use `async_count` + `Pagy.new(count:)`
- Unmemoized methods called multiple times per request that hit the DB or do non-trivial computation
- Cross-table full-text search using JOINs — candidate for materialized view + GIN index (scenic gem)
- Unused indexes wasting disk and slowing writes — audit with `pg_stat_user_indexes`

**If database access is available**, run the 4 diagnostic SQL queries from the
reference file: missing indexes, index efficiency, unused indexes, and duplicate indexes.

**Reference:** [reference/review-performance.md](reference/review-performance.md)

### Testing

**Focus:** Test pyramid balance, fixture usage, coverage gaps, slow tests.

**Scan for:**
- System tests that don't need a browser (should be integration tests)
- Factory usage (`FactoryBot`, `create(:*)`) — should be fixtures
- Mocking internal collaborators (only mock at system boundaries)
- Missing test files for models/controllers
- Tests checking implementation instead of behavior
- `sleep` in tests (time-dependent without `travel`)

**Coverage requirements:**
| Type | Min | Test Type |
|------|-----|-----------|
| Model | 90% | Model test |
| Controller | 80% | Integration test |
| PORO | 95% | Unit test |
| Helper/Mailer | 100% | Helper/Mailer test |
| Job | 90% | Job test |

**Reference:** [reference/review-testing.md](reference/review-testing.md)

**Cross-references:**
- [reference/shared/testing.md](reference/shared/testing.md)

### Security

**Focus:** OWASP top 10, Rails-specific vulnerabilities, authorization gaps.

**Scan for (by severity):**

**Critical:**
- SQL injection (string interpolation in `.where`, `.order`, `find_by_sql`)
- Mass assignment (`params.permit!`, missing strong parameters)
- Command injection (`system()`, backticks with interpolation)
- Path traversal (`send_file`, `File.read` with user-controlled paths)
- Missing authentication on destructive actions

**High:**
- XSS (`.html_safe`, `raw` with user input)
- IDOR (bare `Model.find(params[:id])` without authorization)
- SSRF (HTTP calls with user-supplied URLs)
- Sensitive data in logs/JSON responses
- Weak cryptography (MD5/SHA1 for passwords)

**Medium:**
- Missing CSP or overly permissive CSP
- Insecure session configuration
- CSRF protection disabled on non-API controllers
- Open redirects (`redirect_to params[:return_to]`)

**Reference:** [reference/review-security.md](reference/review-security.md)

**Cross-references:**
- [reference/shared/security.md](reference/shared/security.md)

---

## Smells & Refactorings

When findings map to known code smells, cite the smell and suggest the
appropriate refactoring:

| Smell | Priority | Refactoring |
|-------|----------|-------------|
| God Class | 0 | Form Object, Mixin→Composition, Strategies |
| Divergent Change | 1 | Polymorphism, Strategies |
| Shotgun Surgery | 2 | Polymorphism, Parameter Object |
| Feature Envy | 3 | Extract Validator, Form Object |
| Case Statement | 4 | Polymorphism, Null Object |
| Long Parameter List | 5 | Parameter Object |
| Large Class | 6 | Form Object, Mixin→Composition |
| Callback | 7 | Replace Callback with Method |

**References:**
- [reference/smells.md](reference/smells.md)
- [reference/refactorings/](reference/refactorings/)

---

## Report Formats

### Full Audit

```markdown
# Rails Code Review — [App Name]

## Summary
- **Critical:** N findings
- **High:** N findings
- **Medium:** N findings
- **Low:** N findings

## Architecture
[findings...]

## Code Quality
[findings...]

## Performance
[findings...]

## Testing
[findings...]

## Security
[findings...]

## Recommended Next Steps
1. [highest-impact fix]
2. [second-highest]
3. ...
```

### Targeted Review

```markdown
# [Dimension] Review — [App Name]

## Summary
[1-2 sentence overview]

## Findings
[findings ordered by severity...]

## Recommended Next Steps
1. ...
```

### PR Review

For PR reviews, comment inline on specific lines where possible.
Provide a summary comment with overall assessment and severity counts.
