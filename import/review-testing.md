# Testing Review Reference

## Patterns

### Minitest over RSpec

Ships with Rails, lower ceremony, sufficient for everything. No DSL overhead.

```ruby
class CardTest < ActiveSupport::TestCase
  setup do
    @card = cards(:one)
    @user = users(:david)
  end

  test "closing a card creates a closure" do
    assert_difference -> { Card::Closure.count } do
      @card.close(creator: @user)
    end

    assert @card.closed?
    assert_equal @user, @card.closure.creator
  end

  test "reopening destroys the closure" do
    @card.close(creator: @user)

    assert_difference -> { Card::Closure.count }, -1 do
      @card.reopen
    end

    refute @card.closed?
  end
end
```

### Fixtures over Factories

Loaded once, reused across tests. No runtime object creation overhead.
Explicit relationship visibility. Deterministic data.

```yaml
# test/fixtures/users.yml
david:
  identity: david
  account: basecamp
  role: admin

jason:
  identity: jason
  account: basecamp
  role: member

# test/fixtures/cards.yml
one:
  title: First Card
  board: main
  creator: david
```

Dynamic timestamps with ERB:

```yaml
recent:
  title: Recent Card
  created_at: <%= 1.hour.ago %>

old:
  title: Old Card
  created_at: <%= 1.month.ago %>
```

### Integration Tests for Controllers

Test the full request/response cycle. Not isolated controller tests.

```ruby
class CardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:david)
  end

  test "closing a card" do
    post card_closure_path(cards(:one))

    assert_response :success
    assert cards(:one).reload.closed?
  end

  test "unauthorized user cannot close card" do
    sign_in users(:guest)

    post card_closure_path(cards(:one))

    assert_response :forbidden
    refute cards(:one).reload.closed?
  end
end
```

### Test Observable Behavior, Not Implementation

```ruby
# BAD — testing implementation
test "calls notify method on each watcher" do
  card.expects(:notify).times(3)
  card.close
end

# GOOD — testing behavior
test "watchers receive notifications when card closes" do
  assert_difference -> { Notification.count }, 3 do
    card.close
  end
end
```

### Don't Mock What You Can Test for Real

```ruby
# BAD — over-mocked
test "sending message" do
  room = mock("room")
  room.expects(:messages).returns(stub(create!: mock("message")))
  MessagesController.new.create
end

# GOOD — test the real thing
test "sending message" do
  sign_in users(:david)
  post room_messages_url(rooms(:watercooler)), params: { message: { body: "Hello" } }

  assert_response :success
  assert Message.exists?(body: "Hello")
end
```

### Time Travel for Time-Dependent Tests

```ruby
test "magic link expires after 15 minutes" do
  magic_link = MagicLink.create!(user: users(:alice))

  travel 16.minutes

  assert magic_link.expired?
end

# Block form
test "card expires after 30 days" do
  travel_to 31.days.from_now do
    assert cards(:one).expired?
  end
end
```

### Background Jobs and Email Assertions

```ruby
test "closing card enqueues notification job" do
  assert_enqueued_with(job: NotifyWatchersJob, args: [cards(:one)]) do
    cards(:one).close
  end
end

test "welcome email is sent on signup" do
  assert_emails 1 do
    Identity.create!(email: "new@example.com")
  end
end
```

### Turbo Stream Assertions

```ruby
test "message creation broadcasts to room" do
  assert_turbo_stream_broadcasts [rooms(:watercooler), :messages] do
    rooms(:watercooler).messages.create!(body: "Test", creator: users(:david))
  end
end
```

### VCR for External APIs

```ruby
test "fetches user data from API" do
  VCR.use_cassette("user_api") do
    user_data = ExternalApi.fetch_user(123)
    assert_equal "John", user_data[:name]
  end
end
```

### System Tests — Use Sparingly

Reserve for genuinely browser-dependent behavior (drag-and-drop, JS interactions).
Everything else should be an integration or unit test.

```ruby
class MessagesTest < ApplicationSystemTestCase
  test "drag and drop card to new column" do
    sign_in users(:david)
    visit board_path(boards(:main))

    card   = find("#card_#{cards(:one).id}")
    target = find("#column_#{columns(:done).id}")
    card.drag_to target

    assert_selector "#column_#{columns(:done).id} #card_#{cards(:one).id}"
  end
end
```

See NOTES.md for the system test conversion workflow — triage by churn + recency,
convert candidates to integration/controller tests.

## Anti-patterns

### Testing the Wrong Layer

**Problem:** Controller tests verify business logic; model tests verify HTTP behavior.

```ruby
# BAD — controller test checking domain logic
test "applies VIP discount" do
  post :create, params: { items: [...] }
  expect(Order.last.total).to eq(90)
end

# GOOD — domain logic in model test
test "applies VIP discount" do
  order = Order.new(customer: customers(:vip))
  order.calculate_total
  assert_equal 90, order.total
end
```

### Excessive System Tests

**Problem:** System tests are slow, brittle, and often test things integration
tests can cover. A test suite dominated by system tests gives slow feedback.

**Signal:** `test/system/` has more files than `test/integration/`. Tests that
only assert on response status or database state (no JS interaction) are system tests.

**Fix:** See system test conversion workflow in NOTES.md.

### Factory-Dependent Tests

**Problem:** Factories create objects at runtime, making tests slow and coupling
tests to factory definitions. Changes to factories break unrelated tests.

**Fix:** Fixtures. They're loaded once, relationships are explicit in YAML,
and ERB handles dynamic values.

### Mocking Internal Collaborators

**Problem:** Mocking model methods or internal Rails objects creates brittle
tests that break on refactoring and don't test real behavior.

**Fix:** Test observable outcomes (record counts, response codes, broadcasts).
Only mock at system boundaries (external APIs, time).

## Heuristics

- If a test doesn't need a browser, it shouldn't be a system test
- Test files should mirror `app/` structure — `app/models/card.rb` → `test/models/card_test.rb`
- Fixtures should cover the common cases; create records inline only for edge cases
- A test that relies on mock expectations rather than real assertions is testing implementation
- `assert_difference` is usually better than checking a count before and after

<!-- Add your own testing rules and heuristics below -->
