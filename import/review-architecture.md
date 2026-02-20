# Architecture Review Reference

## Patterns

### Domain Logic in Models

Models own their domain rules. The test: does this method answer a question
or enforce a rule about the model itself? If yes, it belongs here.

```ruby
# GOOD — model knows its own rules
class Order < ApplicationRecord
  def total
    items.sum(&:subtotal).tap { |t| apply_vip_discount(t) if customer.vip? }
  end
end
```

### DCI (Data, Context, Interaction) for Complex Behavioral Contexts

When the same model needs different behavior in different use cases, DCI
injects role modules at runtime via a Context object. Avoids fat models
without resorting to service objects. Best suited to genuinely use-case-specific
behavior, not reusable logic.

```ruby
# Role: behavior injected at runtime
module TransferRole
  def transfer(amount, to:)
    self.balance -= amount
    to.balance += amount
  end
end

# Context: assembles objects + roles, runs the interaction
class Transfer
  def initialize(source, destination, amount)
    source.extend(TransferRole)
    @source = source
    @destination = destination
    @amount = amount
  end

  def call
    @source.transfer(@amount, to: @destination)
  end
end
```

**When to reach for DCI:** the same model needs different collaborators and
behaviors in 2+ distinct use cases.

## Routing

Everything maps to CRUD. Nested resources for related actions:

```ruby
Rails.application.routes.draw do
  resources :boards do
    resources :cards do
      resource :closure
      resource :goldness
      resource :not_now
      resources :assignments
      resources :comments
    end
  end
end
```

**Verb-to-noun conversion:**
| Action | Resource |
|--------|----------|
| close a card | `card.closure` |
| watch a board | `board.watching` |
| mark as golden | `card.goldness` |
| archive a card | `card.archival` |

**Shallow nesting** - avoid deep URLs:
```ruby
resources :boards do
  resources :cards, shallow: true  # /boards/:id/cards, but /cards/:id
end
```

**Singular resources** for one-per-parent:
```ruby
resource :closure   # not resources
resource :goldness
```

**Resolve for URL generation:**
```ruby
# config/routes.rb
resolve("Comment") { |comment| [comment.card, anchor: dom_id(comment)] }

# Now url_for(@comment) works correctly
```

### Collection Fragment Caching

Pass `cached: true` to collection renders for automatic multi-fetch caching.
Works with any cache store that supports `read_multi`.

```erb
<%# Automatically cache-key per record, fetched in one round trip %>
<%= render partial: "conversations/conversation",
           collection: @conversations,
           cached: true %>

<%# Custom cache key (e.g. scope to current user) %>
<%= render partial: "conversations/conversation",
           collection: @conversations,
           cached: ->(c) { [c, current_user] } %>
```

### Double Dispatch via Jobs for Cross-model Operations

When a model needs to trigger creation/mutation of unrelated records, dispatch
to a job rather than doing it inline. Decouples the models, makes the side
effect explicit and async-safe.

```ruby
# Instead of model orchestrating directly:
class Bot < ApplicationRecord
  def observed!(conversation, observations)
    observations.each { |o| Observation.create!(o.merge(bot: self)) }
  end
end

# Double dispatch — model hands off to a job
class Bot < ApplicationRecord
  def observed!(conversation, observations)
    CreateObservationsJob.perform_later(bot: self, conversation:, observations:)
  end
end

class CreateObservationsJob < ApplicationJob
  def perform(bot:, conversation:, observations:)
    observations.each { |o| bot.observations.create!(o.merge(conversation:)) }
  end
end
```

## Anti-patterns

### Service Objects

**Problem:** Service objects don't communicate intent — `CreateUser`,
`ProcessPayment` are procedures dressed up as classes. They accumulate like
fat models did, with no design pressure on what belongs inside. The name
tells you *what happens*, not *what domain concept this represents*.

<!-- Add more detail here on what to use instead — DCI, rich models, named domain objects -->

### Business Logic in Jobs

**Problem:** Jobs accumulate domain logic because they're "close" to the
models they operate on. Makes logic hard to test without a queue, and creates
idempotency challenges (Sidekiq doesn't guarantee exactly-once execution).

**Signal:** Job `perform` is more than ~5 lines, contains conditionals or
multi-step domain operations.

**Fix:** Job calls a model method or DCI context; logic lives there.

### Authorization Inline in Controllers

**Problem:** Role/permission checks scattered in controller actions or
`before_action` callbacks. Logic duplicated, untestable in isolation.

```ruby
# BAD — authorization logic in controller
def show
  @conversation =
    if current_user.superadmin?
      Conversation.unscoped.find(params[:id])
    elsif current_user.admin?
      current_account.conversations.find(params[:id])
    else
      current_user.conversations.find(params[:id])
    end
end

# GOOD — scoping logic in Pundit policy scope
def show
  @conversation = policy_scope(Conversation).find(params[:id])
  authorize @conversation
end
```

**Fix:** Pundit policy + scope. All authorization logic in one testable class.

### Fat Models

**Problem:** All logic pulled into the model because "skinny controller, fat model"
was taken too literally. The model ends up with dozens of unrelated responsibilities.

**Signal:** Model over ~200 lines, methods that reference other models
extensively (feature envy), callbacks that trigger side effects outside the
model's own state.

**Fix:** Extract to value objects, query objects, or DCI contexts. Keep
orchestration (mailers, jobs, external calls) out of models entirely.

## Heuristics

- If you can't name a class without "and" or "Manager", it has too many responsibilities
- Jobs should be thin dispatchers — logic belongs in the domain layer
- Ask of every callback: own state change, or side effect? Side effects belong in the caller
- Prefer named domain objects (nouns) over procedural service objects (verb + "Service")
- A model reaching out to create/destroy records in unrelated models is a SRP violation
- All authorization scoping belongs in a Pundit policy scope, not in controller actions
- `Current.*` *inside* a model method body is a hidden dependency — flag it. Default arguments and `belongs_to` defaults are fine.
- Collection renders with `cached: true` cost almost nothing and compound fast

<!-- Add your own architectural rules below -->
