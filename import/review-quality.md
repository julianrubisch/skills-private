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

### `Time.current` Over `Time.now`

`Time.now` ignores Rails timezone configuration. Always use `Time.current`,
`Time.zone.now`, or `n.hours.ago` / `n.days.from_now`.

```ruby
# BAD — ignores configured timezone
record.update!(published_at: Time.now)

# GOOD
record.update!(published_at: Time.current)
```

**Signal:** Any occurrence of `Time.now` in Rails code. Automated:
`Rails/TimeZone` RuboCop cop.

### Ruby Idioms Worth Enforcing

Small wins that reviewers should flag consistently:

```ruby
# gsub single character → tr (faster, more expressive)
str.gsub('"', "'")   # BAD
str.tr('"', "'")     # GOOD

# delete single character → delete (faster than gsub)
str.gsub('"', "")    # BAD
str.delete('"')      # GOOD

# filter.last → reverse.find (short-circuits)
items.filter { |i| i.active? }.last   # BAD — scans everything
items.reverse.find { |i| i.active? }  # GOOD

# Dynamic finder → find_by
User.find_by_email(email)   # BAD — metaprogramming, no IDE support
User.find_by(email:)        # GOOD

# params.merge!(key: val) → direct assignment
params.merge!(format: "json")   # BAD — allocates new hash
params[:format] = "json"        # GOOD

# create_with for conditional assignment on find_or_create
Conversation.find_or_create_by!(account:) do |c|  # BAD — verbose block
  c.title = "default"
  c.active = true
end

Conversation.create_with(title: "default", active: true)
            .find_or_create_by!(account:)           # GOOD
```

### Control Coupling — Flag Arguments

A boolean argument that changes a method's behavior means the method is doing
two things. Extract to two methods or remove the flag entirely.

```ruby
# BAD — caller must know what `true` means; method does two things
def build_directive(add_directives: false)
  content = base_content
  if add_directives
    content += tool_directives
  end
  content
end

# GOOD — guard at the call site, or two methods
def directive          = base_content
def directive_with_tools = base_content + tool_directives

# Or: extract the conditional to a private method
def build_directive
  base_content + (tools_enabled? ? tool_directives : "")
end
```

### View Code in Models

HTML construction, tag helpers, `image_tag`, `link_to`, or `content_tag`
in model methods. Breaks the layer boundary and makes testing harder.

```ruby
# BAD — model building HTML
def profile_links
  tag.div(class: "flex") do
    tag.a(email, href: "mailto:#{email}")
  end
end

# GOOD — move to helper, ViewComponent, or presenter
```

**Signal:** `tag.`, `content_tag`, `link_to`, `image_tag`, `html_safe` in
`app/models/`.

### Symbol to Proc Over Explicit Blocks

When calling an argumentless method on each element, use `&:method_name`.
More idiomatic and slightly more readable.

```ruby
# BAD
resources.min_by { |r| r.model_key }
items.map { |i| i.name }

# GOOD
resources.min_by(&:model_key)
items.map(&:name)
```

### Safe Navigation Over `rescue nil`

`rescue nil` silences all exceptions, not just `NoMethodError`. It hides bugs.

```ruby
# BAD — swallows any exception
value = object.some_method rescue nil

# GOOD — only handles nil receiver
value = object&.some_method
```

### Memoize `self.class.name` Derivations

Any method that calls `self.class.name`, `.demodulize`, `.underscore`, or
similar string operations on the class is a candidate for memoization —
class names don't change at runtime.

```ruby
# BAD — allocates strings on every call
def type
  self.class.name.demodulize.underscore.gsub("_field", "")
end

# GOOD — ~7-15x faster, ~10-14x less memory (benchmarked)
def type
  @type ||= self.class.name.demodulize.underscore.gsub("_field", "")
end
```

**Signal:** Any method body containing `self.class.name` without `||=`.
These are especially impactful in classes instantiated per-row on index pages.

## Heuristics
<!-- Rules of thumb, judgment calls -->

- If you write `.where(...)` in a controller, ask: should this be a named scope?
- If a method is longer than fits on one screen, it's doing too much.
- Any method reading from disk or doing metaprogramming that isn't memoized is a bug waiting to matter.
- Check index actions first — N+1s and unmemoized accessors multiply with record count.

## Examples
<!-- Inline code snippets -->
