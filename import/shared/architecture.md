# Layered Architecture

## The Four Layers

Rails applications are organized into four architecture layers with unidirectional data flow:

| Layer | Responsibility | Rails Examples |
|-------|----------------|----------------|
| **Presentation** | Handle user interactions, present information | Controllers, Views, Channels, Mailers |
| **Application** | Organize domain objects for use cases | Service objects, Form objects, Policy objects |
| **Domain** | Entities, rules, invariants, application state | Models, Value objects, Domain events |
| **Infrastructure** | Supporting technologies | Active Record, API clients, File storage |

```
Presentation → Application → Domain → Infrastructure
```

## Rules

### Rule 1: Unidirectional Data Flow

Data flows from top to bottom only. Arrows in the architecture always point downward.

### Rule 2: No Reverse Dependencies

Lower layers must not depend on higher layers. A domain object should never depend on a controller or request object.

**Violations:**

```ruby
# BAD: Model (Domain) depends on Current (Presentation context)
class Post < ApplicationRecord
  def destroy
    self.deleted_by = Current.user  # Hidden dependency!
    super
  end
end
```

**Correct:**

```ruby
# GOOD: Model method accepts explicit parameters
class Post < ApplicationRecord
  def destroy_by(user:)
    self.deleted_by = user
    destroy
  end
end
```

**Exception:** Default arguments and `belongs_to` defaults are acceptable —
the caller can always override them, and they keep the API ergonomic:

```ruby
def close(creator: Current.user)            # Fine — overridable
belongs_to :creator, default: -> { Current.user }  # Fine — convention
```

See `smells.md § Current in Models` for the full signal definition.

### Rule 3: Abstraction Boundaries

Every abstraction layer must belong to a single architecture layer. An abstraction cannot span multiple architecture layers.

**Evaluating abstractions:**
- Does this object depend on objects from a higher layer? → Extract or refactor
- Does this object's responsibility match its architecture layer? → Move if not


## Layer Mapping

### Presentation Layer

**Purpose:** Handle user interactions, present information

**Includes:**
- Controllers (HTTP request/response)
- Views (HTML rendering)
- Channels (WebSocket connections)
- Mailers (email composition)
- API serializers
- Form objects (user input handling — straddle presentation/application boundary)
- Filter objects (request parameter transformation)
- Presenters (view-specific logic — see `patterns.md § Presenters`)

**Primary concerns:**
- Request parsing and validation
- Authentication
- Response formatting
- User interface logic

### Application Layer

**Purpose:** Organize domain objects for specific use cases

**Includes:**
- Policy objects (authorization)
- DCI contexts (use-case orchestration)

**Primary concerns:**
- Orchestrating domain objects
- Transaction boundaries
- Use-case specific logic

**Warning:** This layer is often overused. Prefer named domain models over
generic service objects — see `patterns.md § Domain Models over Service Objects`.
Don't strip all logic from models into services (anemic models anti-pattern).

### Domain Layer

**Purpose:** Entities, rules, invariants, application state

**Includes:**
- Models (business entities)
- Value objects (immutable concepts)
- Domain events
- Query objects (data retrieval logic)
- Concerns (shared behaviors)

**Primary concerns:**
- Business rules and invariants
- Entity relationships
- Data transformations
- Domain-specific calculations

### Infrastructure Layer

**Purpose:** Supporting technologies

**Includes:**
- Active Record (database access)
- API clients (external services)
- File storage adapters
- Message queue adapters
- Cache implementations
- Active Storage (external object storage)

**Primary concerns:**
- Persistence
- External communication
- Technical implementations

## Using These Principles

When designing or refactoring code:

1. **Identify the architecture layer** the code belongs to
2. **Check dependencies** — does it depend on higher layers?
3. **Apply specification test** — do tests verify appropriate responsibilities?
4. **Extract if needed** — move code to the correct layer

## Common Mistakes

| Mistake | Problem | Solution | See also |
|---------|---------|----------|----------|
| Current in models | Hidden dependency on presentation context | Pass as explicit parameter (default args are fine) | `smells.md § Current in Models` |
| Request in services | Service depends on HTTP layer | Extract value object from request | — |
| Mailer/Notification in callbacks | Model triggers presentation-layer code | Use form object, or move to controller | `smells.md § Callback` |
| SQL in controllers | Presentation doing infrastructure work | Use model scopes or query objects | `review-architecture.md § Heuristics` |
| Business logic in views | Presentation doing domain work | Use presenters or model methods | `anti-patterns.md § Logic in Views` |
