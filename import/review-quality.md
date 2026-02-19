# Code Quality Review Reference

## Patterns
<!-- What good Rails code looks like -->

### Named Scopes Over Inline Queries

Scopes belong on the model. Controllers and services should read like English.

```ruby
# GOOD
class Invoice < ApplicationRecord
  scope :overdue, -> { where("due_date < ?", Date.today).where(paid: false) }
end

# Controller stays clean
Invoice.overdue.page(params[:page])
```

## Anti-patterns
<!-- What to flag, and why -->

### Inline Query Logic in Controllers

**Problem:** AR query conditions scattered in controllers make them hard to reuse and test, and blur the boundary between request handling and domain logic.

```ruby
# BAD
def index
  @invoices = Invoice.where("due_date < ?", Date.today)
                     .where(paid: false)
                     .order(:due_date)
end
```

**Issues:**
- Duplicated across controllers/jobs when the same set is needed elsewhere
- Query intent is not named — reader must parse SQL to understand domain meaning
- Changes to the domain rule require hunting across the codebase

**Fix:** Named scope on the model. If ordering is always implied, include it in the scope.

## Heuristics
<!-- Rules of thumb, judgment calls -->

- If you write `.where(...)` in a controller, ask: should this be a named scope?
- If a method is longer than fits on one screen, it's doing too much.

## Examples
<!-- Inline code snippets -->
