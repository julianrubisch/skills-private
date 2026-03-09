# Testing Review Reference

Diagnostic layer — what to flag, how severe, and why. Prescriptive patterns
(how to write tests correctly) live in shared/testing.md.

## Anti-patterns

### Testing the Wrong Layer

**Problem:** Controller tests verify business logic; model tests verify HTTP behavior.

```ruby
# BAD — controller test checking domain logic
test "applies VIP discount" do
  post :create, params: { items: [...] }
  assert_equal 90, Order.last.total
end

# GOOD — domain logic in model test
test "applies VIP discount" do
  order = Order.new(customer: customers(:vip))
  order.calculate_total
  assert_equal 90, order.total
end
```

### Excessive System Tests

**Problem:** System tests are slow and brittle. A suite dominated by them
gives slow feedback and masks gaps in unit/integration coverage.

**Signal:** `test/system/` has more files than `test/integration/`. Tests that
only assert on response status or database state (no JS interaction needed).

**Fix:** See system test conversion workflow in NOTES.md — triage by churn +
recency, convert candidates to integration/controller tests.

### Factory-Dependent Tests

**Problem:** Factories create objects at runtime, slowing tests and coupling
them to factory definitions. Factory changes break unrelated tests.

**Signal:** `FactoryBot`, `create(:user)`, `build(:card)` in test files.

**Fix:** Fixtures. Loaded once, relationships explicit in YAML, ERB for
dynamic values. See shared/testing.md.

### Mocking Internal Collaborators

**Problem:** Mocking model methods or internal Rails objects creates brittle
tests that break on refactoring without catching real regressions.

**Fix:** Test observable outcomes (record counts, response codes, broadcasts).
Only mock at system boundaries (external APIs, time).

### Missing Tests for Critical Paths

**Signal:** No integration test for authentication, authorization, or payment
flows. Public methods on models with no corresponding test file.

### Slow Tests

**Signal:** Suite takes > 5 minutes; developers avoid running tests.

**Common causes:** Too many system tests (see above), unnecessary database
hits, factory cascades. Use test-prof (see NOTES.md) to diagnose.

**Audit Check**: Flag if average test takes > 100ms.

### Intermittent Failures

**Signal:** Tests pass/fail randomly, "works on my machine."

**Common causes:** Shared state between tests, time-dependent tests without
`travel`/`travel_to`, order-dependent tests, race conditions in async code.

**Audit Check**: Search for `sleep`, time manipulation without `travel_back`.

### Brittle Tests

**Signal:** Tests break when implementation changes but behavior didn't change.

**Common causes:** Testing implementation not behavior, hardcoded CSS selectors,
excessive mocking, stubs on the object under test itself.

**Audit Check**: Flag tests with hardcoded CSS selectors, deep mock chains,
or stubs on the object being tested (`object.stubs(:own_method)`).

### Mystery Guest

**Signal:** Test data defined elsewhere, hard to understand what the test depends on.

Note: fixtures are intentionally the preferred approach despite this trade-off.
Mitigate by naming fixtures descriptively and keeping fixture files small.
The real anti-pattern is factory defaults that silently change test behavior.

### False Positives

**Signal:** Test passes but code is broken — not testing the right thing.

**Audit Check**: Look for `assert_text ""` or overly broad `assert_selector`
matchers that match anything.

### Factory Misuse (when codebase uses factory_bot)

Two related smells in factory-based codebases:

- **Factories as fixtures**: Named factories for every scenario
  (`create(:admin_user_with_premium_subscription)`) — traits proliferate,
  test intent is buried in factory definitions.
- **Bloated factories**: Factories create unnecessary associations and data
  "just in case" — causes slow tests and cascading factory creation.

**Audit Check**: Flag factories with > 5 attributes, unnecessary associations,
or many trait combinations. Use `FactoryProf` (test-prof) to detect cascades.

**Fix**: Migrate to fixtures. Failing that, keep factories minimal — only
required attributes, no associations unless explicitly needed by the test.


## Coverage Requirements by File Type

| File Type | Min Coverage | Test Type |
|-----------|--------------|-----------|
| Model | 90% | Model test |
| Controller | 80% | Integration test |
| Service/PORO | 95% | Unit test |
| Helper | 100% | Helper test |
| Mailer | 100% | Mailer test |
| Job | 90% | Job test |


## Missing Test Detection

For each Ruby file in `app/`:

1. Check for corresponding test:
   - `app/models/user.rb` → `test/models/user_test.rb`
   - `app/controllers/users_controller.rb` → `test/controllers/users_controller_test.rb` or `test/integration/users_test.rb`

2. Check public methods are tested:
   - Extract public method names from source
   - Search for those names in test file

3. Report:
   - Files without any tests → **High** severity
   - Files with partial coverage → **Medium** severity


## Heuristics

- If a test doesn't need a browser, it shouldn't be a system test
- Test files should mirror `app/` — `app/models/card.rb` → `test/models/card_test.rb`
- A test relying on mock expectations rather than real assertions is testing implementation
- `assert_difference` is usually better than checking a count before and after
- Fixtures should cover the common cases; create inline only for edge cases

<!-- Add your own testing review heuristics below -->
