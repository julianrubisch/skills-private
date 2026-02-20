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

### Memoize Expensive Accessors

Any method in a hot path that computes from file I/O, metaprogramming, or
external data should be memoized. Unmemoized accessors on frequently-instantiated
objects are silent memory and CPU drains.

```ruby
# BAD — reads file on every call
def file_hash
  Digest::MD5.file(resource_file_path).hexdigest
end

# BAD — metaprogramming allocation on every call
def class_name
  self.class.name.demodulize
end

# GOOD
def file_hash
  @file_hash ||= Digest::MD5.file(resource_file_path).hexdigest
end

def class_name
  @class_name ||= self.class.name.demodulize
end
```

**Signal:** Methods called in loops, in views, or on index pages that lack `||=`.
Real-world impact from Avo audit: memoizing `file_hash` → 1.64x less memory,
1.44x faster; memoizing metaprogramming accessors → 12.48x less memory, 7.91x faster.

## Heuristics
<!-- Rules of thumb, judgment calls -->

- If you write `.where(...)` in a controller, ask: should this be a named scope?
- If a method is longer than fits on one screen, it's doing too much.
- Any method reading from disk or doing metaprogramming that isn't memoized is a bug waiting to matter.
- Check index actions first — N+1s and unmemoized accessors multiply with record count.

## Examples
<!-- Inline code snippets -->
