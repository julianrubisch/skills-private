# Code Smells

Detection signals for review agents. A smell doesn't mean the code is wrong —
it means "look closer here." Use these to find candidates for deeper diagnosis.

## Method-level Smells

### Long Method
A method that does more than one thing. Hard to name precisely.

**Signal:** More than ~10 lines, or you need "and" to describe what it does.

### Too Many Parameters
Method signature with 3+ positional arguments.

**Signal:** `def create(user, plan, coupon, trial_days)` — callers must know argument order.
Keyword arguments help but don't fix the underlying problem.

### Flag Arguments
Boolean passed to change method behavior — the method is doing two things.

```ruby
# Smell: what does `true` mean at the call site?
send_notification(user, true)

# Better: two methods, or a keyword that reads clearly
send_notification(user, immediately: true)
```

## Class-level Smells

### Large Class
Class with too many responsibilities. Hard to name without "and" or "manager".

**Signal:** 200+ lines, 10+ public methods, multiple unrelated instance variables.

### Data Clumps
Same group of data always appearing together — they probably want to be an object.

```ruby
# Smell: address fields scattered everywhere
def ship(street, city, zip, country)
def validate_address(street, city, zip, country)

# Signal: extract Address value object
```

## Interaction Smells

### Command/Query Separation Violation
A method that both returns information *and* mutates state. Asking a question
should not change the answer.

```ruby
# Smell: name implies a query, but it also updates a property
def memory_lookup(user_message)
  observations_processed = []
  # ... queries memory ...
  update!(memory_property: result)  # hidden mutation!
  result
end

# Better: separate the query from the command
def memory_for(user_message)   # pure query
def store_memory!(observations) # explicit command
```

**Signal:** A method named as a query (`find_`, `get_`, `lookup_`, `for_`) that
also calls `update!`, `save`, `create`, or `increment!`.

### Model Creating/Destroying Other Models
A model method that creates, updates, or destroys records in unrelated models.
Increases coupling and violates SRP — managing its own associations is a
fringe exception, not a license to orchestrate broadly.

```ruby
# Smell: User model orchestrating Workspace and Notification creation
def onboard!
  Workspace.create!(owner: self)
  AdminNotification.create!(event: :new_user, subject: self)
end

# Better: double dispatch to a job, or DCI context
def onboard!
  OnboardingJob.perform_later(self)
end
```

**Signal:** Model methods calling `OtherModel.create!`, `other_record.update!`,
or `OtherModel.destroy_by(...)` on records outside their own association graph.

### Current in Models
Accessing `Current.user`, `Current.account` etc. *inside a method body* is a
hidden dependency on the request context. Silent failures in jobs and background
threads where Current is not set.

```ruby
# Smell — buried, non-overridable dependency
def process!
  log_action(Current.user)   # caller can't inject a different user
end

# Fine — caller can always pass an explicit value
def close(creator: Current.user)
  create_closure!(creator:)
end

# Fine — belongs_to convenience default
belongs_to :creator, class_name: "User", default: -> { Current.user }
```

**Signal:** `Current.*` used *inside* a method body with no way for the caller
to override it. Default arguments and `belongs_to` defaults are acceptable.

### Feature Envy
A method that's more interested in another object's data than its own.

```ruby
# Smell: Order method obsessed with customer data
def apply_discount
  if customer.membership.tier == :gold && customer.membership.years > 2
    self.discount = 0.2
  end
end
# Signal: this logic might belong on Customer or Membership
```

### Inappropriate Intimacy
Two classes know too much about each other's internals.

**Signal:** Class A reaches into Class B's associations or private state directly.
Often indicates a missing abstraction between them.

### Long Case Statement
A `case` with many `when` branches handling unrelated behavior. Attractive
for assembling all conditions in one place, but becomes a maintenance burden.

**Signal:** `case` with 5+ branches, or branches that call out to different
objects/concerns. Often a candidate for pattern matching, a lookup table,
or composition (e.g. strategies).

## Change Smells

### Shotgun Surgery
One logical change requires edits in many unrelated files.

**Signal:** Adding a new payment provider touches 6 files. The concept isn't encapsulated.

### Divergent Change
One class changes for many different reasons.

**Signal:** "I edit this file whenever we change billing logic AND whenever we change
notification logic." The class has multiple axes of change — split it.
