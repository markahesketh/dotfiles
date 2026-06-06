# When to Mock

Mock at **system boundaries** only:

- External APIs (payment, email, third-party services)
- Databases (usually prefer a real test DB; transactional fixtures keep it fast)
- Time / randomness (`Timecop`, `travel_to`, seeded RNG)
- The file system (sometimes)

Don't mock:

- Your own classes/models/contexts
- Internal collaborators
- Anything you control

Mocking what you own couples the test to today's call graph. The test then passes when the collaboration is wrong and breaks when you refactor — the opposite of what you want.

## Designing for mockability

At a boundary, make the dependency easy to substitute.

**Inject the dependency** rather than constructing it internally:

```ruby
# Easy to substitute the boundary
class ProcessPayment
  def initialize(payment_client:)
    @payment_client = payment_client
  end

  def call(order) = @payment_client.charge(order.total)
end

# Hard to substitute: the boundary is hard-wired
class ProcessPayment
  def call(order)
    StripeClient.new(ENV["STRIPE_KEY"]).charge(order.total)
  end
end
```

**Prefer specific operations over one generic caller.** A client with `get_user(id)`, `create_order(data)` is easier to fake than a single `request(endpoint, opts)` — each fake returns one shape, with no conditional logic in the test setup.

Notes for other stacks:

- **Elixir**: inject the boundary module via config or a function arg (`Application.get_env`, or pass the module), and assert against a stub module. `Mox` formalises this with behaviours.
- **Godot/GUT**: inject collaborators through exported properties or `_init` args so a test can pass a double; avoid reaching for autoloads/singletons inside the unit under test.
