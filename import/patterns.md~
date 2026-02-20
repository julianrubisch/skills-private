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

## Presenters / Decorators

Add display logic to a model without polluting it. Keeps views and models clean.

<!-- Add your preferred approach here: Draper? Plain Ruby decorator? ViewComponent? -->

**When:** model methods start returning HTML, formatted strings, or view-specific logic.

## Policy Objects

<!-- Add your preferred authorization approach: Pundit? Action Policy? -->

Encapsulate authorization rules separate from models and controllers.

**When:** authorization logic is conditional, role-based, or needs to be tested in isolation.
