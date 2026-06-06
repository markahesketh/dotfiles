# Good and Bad Tests

Don't add tests that simply restate the implementation — they give zero confidence.

## Good Tests

Test through the real public interface, not mocks of internal parts.

```ruby
# GOOD: observable behaviour through the public interface
it "confirms an order when the cart has a valid payment method" do
  cart = Cart.new
  cart.add(product)

  result = Checkout.new(cart, payment_method).call

  expect(result).to be_confirmed
end
```

Characteristics:

- Tests behaviour callers care about
- Uses the public API only
- Survives internal refactors
- Describes WHAT, not HOW
- One logical assertion per test

## Bad Tests

Coupled to internal structure — they break on refactor though behaviour is unchanged.

```ruby
# BAD: asserts on an internal collaborator and call shape
it "calls PaymentService#process with the total" do
  payment = instance_double(PaymentService)
  expect(payment).to receive(:process).with(cart.total)
  Checkout.new(cart, payment).call
end
```

Red flags:

- Mocking collaborators you own (vs. real system boundaries)
- Testing private methods
- Asserting on call counts/order
- Test name describes HOW, not WHAT

## Verifying through the interface

The anti-pattern is reaching _around_ the interface to assert on internal state when the public interface could tell you the same thing. In Rails the model **is** the public interface, so asserting through the model (or a query) is fine — that's not "bypassing" anything:

```ruby
# GOOD: the model is the interface; verifying persistence through it is correct
it "persists the user so it can be retrieved" do
  user = Users.create(name: "Alice")
  expect(User.find(user.id).name).to eq("Alice")
end
```

What to avoid is bypassing a meaningful public method to poke at private state it was supposed to encapsulate — e.g. reading an instance variable via `instance_variable_get` instead of calling the method that exposes the behaviour. If the only way to verify a behaviour is to reach into internals, that's a signal the interface is missing something.

Other stacks follow the same rule through their own idioms — ExUnit asserting on the return of a public function, GUT asserting through a node's public methods and watched signals.
