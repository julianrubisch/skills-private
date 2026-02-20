# Preferred Design Patterns

Your opinionated design toolkit. Each entry answers: what is it, when to reach for it,
and how you like it structured. Review agents use this as the "fix" vocabulary —
anti-patterns and smells point here for solutions.

## Query Objects

Encapsulate complex or reusable AR queries. Reach for this when a scope isn't enough
— multiple conditions, joins, subqueries, or shared across contexts.

```ruby
# app/queries/overdue_invoices_query.rb
class OverdueInvoicesQuery
  def initialize(relation = Invoice.all)
    @relation = relation
  end

  def call
    @relation
      .where("due_date < ?", Date.today)
      .where(paid: false)
      .order(:due_date)
  end
end

# Usage
OverdueInvoicesQuery.new.call
OverdueInvoicesQuery.new(current_user.invoices).call
```

**When:** inline `.where` chains repeated in 2+ places, or query has 3+ conditions.
**When not:** a simple named scope covers it.

## Value Objects

Represent a domain concept with no identity — equality is based on value, not id.
Reach for this when you see data clumps or primitive obsession.

```ruby
# app/value_objects/money.rb
class Money
  include Comparable

  attr_reader :amount, :currency

  def initialize(amount, currency = "USD")
    @amount = amount.to_d
    @currency = currency
  end

  def +(other)
    raise ArgumentError, "Currency mismatch" unless currency == other.currency
    Money.new(amount + other.amount, currency)
  end

  def <=>(other)
    amount <=> other.amount
  end
end
```

**When:** same 2-3 primitive values always travel together, or you find yourself
duplicating formatting/comparison logic for raw primitives.

## Form Objects

Handle multi-model forms, virtual attributes, or complex input validation outside
the model. Keeps models clean of presentation-driven concerns.

```ruby
# app/forms/registration_form.rb
class RegistrationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :email, :string
  attribute :password, :string
  attribute :plan_id, :integer

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 12 }
  validates :plan_id, presence: true

  def save
    return false unless valid?
    # orchestrate multi-model creation
    ActiveRecord::Base.transaction do
      user = User.create!(email:, password:)
      Subscription.create!(user:, plan_id:)
    end
    true
  end
end
```

**When:** form spans multiple models, has virtual fields, or validation rules are
specific to one UI flow rather than the domain model.
**When not:** single-model form with standard validations — just use the model.

## Rule Objects

Encapsulate complex conditional logic — sets of guard clauses that determine
whether something should happen. Better than a long `call` method with many
`return if` checks. Testable in isolation.

```ruby
# app/rules/continuation_rule.rb
class ContinuationRule
  CONVERSATION_LENGTH_MIN = 3
  LENGTH_CUTOFF = 250
  MAX_TOKENS = 8_000

  def initialize(message)
    @message = message
  end

  def satisfied?
    !sender_is_csm? &&
      onboarding_complete? &&
      conversation_long_enough? &&
      message_short_enough? &&
      within_token_limit?
  end

  private

  def sender_is_csm?       = @message.sender.csm?
  def onboarding_complete? = @message.account.onboarding_complete?
  def conversation_long_enough? = @message.conversation.messages.count >= CONVERSATION_LENGTH_MIN
  def message_short_enough? = @message.content.to_s.length <= LENGTH_CUTOFF
  def within_token_limit?  = @message.tokens_count.to_i <= MAX_TOKENS
end

# Usage
if ContinuationRule.new(message).satisfied?
  # proceed
end
```

**When:** a single method has 4+ guard clauses, or the conditions need to be
tested independently, or the same set of conditions appears in multiple places.

## `store_accessor` for JSON/JSONB Columns

Expose JSON column keys as first-class attributes with type coercion.
Avoids `properties["reactions"]` string-keyed access throughout the codebase.

```ruby
class Message < ApplicationRecord
  store_accessor :properties, :reactions, :responding_to, :tokens_count

  # Now accessed as:
  message.reactions        # instead of message.properties["reactions"]
  message.responding_to=   # instead of message.properties[:responding_to] =
end
```

**When:** a JSONB/JSON column has a known set of keys accessed in multiple places.
**When not:** the JSON structure is fully dynamic or schema-less.

## Presenters / Decorators

Add display logic to a model without polluting it. Keeps views and models clean.

<!-- Add your preferred approach here: Draper? Plain Ruby decorator? ViewComponent? -->

**When:** model methods start returning HTML, formatted strings, or view-specific logic.

## Policy Objects (Pundit)

Authorization rules live in policy objects, separate from models and controllers.
One policy per resource, named `<Model>Policy`.

```ruby
# app/policies/card_policy.rb
class CardPolicy < ApplicationPolicy
  def update?
    record.creator == user || user.admin?
  end

  def destroy?
    update?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(account: user.account)
    end
  end
end

# Controller
class CardsController < ApplicationController
  def update
    @card = Card.find(params[:id])
    authorize @card

    @card.update!(card_params)
  end

  def index
    @cards = policy_scope(Card)
  end
end
```

**When:** authorization logic is conditional, role-based, or duplicated across controllers.
**When not:** a simple `current_user.admin?` check in one place — inline is fine.
