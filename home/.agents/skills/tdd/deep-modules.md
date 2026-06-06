# Deep Modules

From _A Philosophy of Software Design_:

- **Deep module** = small interface + lots of implementation. Few methods, simple params, complex logic hidden inside. Aim for these.
- **Shallow module** = large interface + thin implementation that just passes through. Avoid.

When designing an interface, ask: can I reduce the number of methods? Simplify the params? Hide more complexity inside?

## Designing for testability

Deep, well-shaped interfaces are also the easy ones to test:

1. **Accept dependencies, don't create them** — pass a boundary collaborator in so a test can substitute it (see [mocking.md](mocking.md)).
2. **Return results, don't mutate hidden state** — `calculate_discount(cart) => Discount` is trivial to assert; `apply_discount!(cart)` that mutates in place is not.
3. **Small surface area** — fewer methods means fewer tests; fewer params means simpler setup.

If a behaviour is awkward to test, treat that as feedback about the interface, not a reason to reach into internals.
