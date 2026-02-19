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

## Change Smells

### Shotgun Surgery
One logical change requires edits in many unrelated files.

**Signal:** Adding a new payment provider touches 6 files. The concept isn't encapsulated.

### Divergent Change
One class changes for many different reasons.

**Signal:** "I edit this file whenever we change billing logic AND whenever we change
notification logic." The class has multiple axes of change — split it.
