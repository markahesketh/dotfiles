---
globs: spec/**/*_spec.rb
---

# RSpec Best Practices

Follow these practices when writing or modifying RSpec specs.
Reference: https://evenbetterspecs.github.io/

## Guiding Principles

- Tests must be self-contained, not DRY — prioritise readability and independence over code reuse
- Follow the Arrange-Act-Assert pattern: setup, execute, then verify — with blank lines separating each phase

## Describe & Context

- Use the class constant, not a string: `describe User do` not `describe 'User' do`
- Use `.method_name` for class methods, `#method_name` for instance methods:

```ruby
# Good
describe User do
  describe '.authenticate' do; end
  describe '#admin?' do; end
end

# Bad
describe 'the authenticate method for User' do; end
```

- For request specs, describe the controller and use `#action_name`:

```ruby
# Good
describe UsersController, type: :request do
  describe '#index' do; end
  describe '#create' do; end
end

# Bad — don't use URL paths or 'GET #index' style
describe '/users', type: :request do
  describe 'GET #index' do; end
end
```

- Use `context` blocks starting with "when" or "with" to describe conditions. Don't encode conditions in `it` descriptions:

```ruby
# Good
context 'when logged in' do
  it 'returns 200' do
    expect(response.code).to eq('200')
  end
end

# Bad — condition buried in the description
it 'has 200 status code if logged in' do
  expect(response.code).to eq('200')
end
```

- Keep `it` descriptions under 100 characters. If too long, split into nested contexts:

```ruby
# Good
context 'when first_name is missing' do
  it 'returns 422' do; end
end

# Bad — description too long
it 'returns 422 when user first_name is missing from params and when last_name is missing' do; end
```

## Data Setup

- Use factories (FactoryBot), not fixtures. Use `build_stubbed` when the code doesn't hit the database:

```ruby
# Good — build_stubbed is faster when no DB needed
user = build_stubbed(:user, first_name: 'Santos', last_name: 'Dumont')

# Good — create when DB interaction is needed
user = create(:user, first_name: 'Santos', last_name: 'Dumont')
```

- Use `described_class` instead of repeating the class name. Only the top-level `describe` needs updating if the class is renamed:

```ruby
# Good
describe Pilot do
  it 'returns the most successful pilot' do
    most_successful = described_class.most_successful
  end
end

# Bad — hardcodes the class name
most_successful = Pilot.most_successful
```

- Use `subject` when calling `described_class.new` with no arguments. Override it locally when arguments are needed:

```ruby
# Good — no args
expect(subject.add(1, 2)).to eq(3)

# Good — with args, override locally
subject = described_class.new(5)
expect(subject.add(1, 2)).to eq(8)

# Bad
calculator = described_class.new
expect(calculator.add(1, 2)).to eq(3)
```

- Create only the minimum data each test needs:

```ruby
# Good — only what's needed to test the query
create(:product, featured: false)
product_featured = create(:product, featured: true)
expect(described_class.featured_product).to eq(product_featured)

# Bad — 5 extra records serve no purpose
create_list(:product, 5)
product_featured = create(:product, featured: true)
```

## Avoid Indirection — Keep Tests Self-Contained

- **Avoid `let` and `let!`** — define variables directly inside each `it` block. `let` definitions force the reader to hunt through the file to understand test state, and mutations on let variables make tests fragile:

```ruby
# Good — everything visible in one place
describe '#full_name' do
  context 'when first name and last name are present' do
    it 'returns the full name' do
      user = build(:user, first_name: 'Edson', last_name: 'Pele')
      expect(user.full_name).to eq('Edson Pele')
    end
  end

  context 'when last name is not present' do
    it 'returns the first name' do
      user = build(:user, first_name: 'Edson', last_name: nil)
      expect(user.full_name).to eq('Edson')
    end
  end
end

# Bad — let definition is separated from usage, mutations make it worse
let(:user) { build(:user, first_name: 'Edson', last_name: 'Pele') }

context 'when last name is not present' do
  it 'returns the first name' do
    user.last_name = nil  # mutating let variable — fragile
    expect(user.full_name).to eq('Edson')
  end
end
```

- **Avoid `before`/`after` hooks** — set up data directly in each test. Hooks split the arrangement across multiple locations making the test harder to follow:

```ruby
# Good — complete, self-contained test
context 'when user has a profile' do
  it 'returns 200' do
    user = create(:user)
    create(:profile, user: user)
    sign_in user

    get profile_path

    expect(response.code).to eq('200')
  end
end

context 'when user does not have a profile' do
  it 'returns 404' do
    user = create(:user)
    sign_in user

    get profile_path

    expect(response.code).to eq('404')
  end
end

# Bad — setup scattered between before block and individual tests
before do
  @user = create(:user)
  sign_in @user
  get profile_path
end

context 'when user has a profile' do
  it 'returns 200' do
    create(:profile, user: @user)
    expect(response.code).to eq('200')
  end
end
```

- **Avoid `shared_examples` / `it_behaves_like`** — duplication in tests is fine. Shared examples add indirection and complexity that makes tests harder to understand and debug:

```ruby
# Good — explicit, readable, self-contained
describe Dog do
  describe '#able_to_bark?' do
    it 'barks' do
      subject = described_class.new(able_to_bark: true)
      expect(subject.able_to_bark?).to eq(true)
    end
  end
end

# Bad — reader must find shared example definition to understand the test
shared_examples 'a barking animal' do
  it 'barks' do
    expect(animal.able_to_bark?).to eq(true)
  end
end

describe Dog do
  let(:animal) { described_class.new(able_to_bark: true) }
  it_behaves_like 'a barking animal'
end
```

## Group Expectations & Cover All Cases

- Group related expectations that share the same setup into one `it` block. Don't duplicate setup across tests for separate assertions on the same result:

```ruby
# Good — one setup, multiple assertions
it 'responds with 200 and JSON content type' do
  user = create(:user)

  get user_path(user)

  expect(response.code).to eq('200')
  expect(response.content_type).to eq('application/json')
end

# Bad — identical setup duplicated
it 'returns 200' do
  user = create(:user)
  get user_path(user)
  expect(response.code).to eq('200')
end

it 'returns JSON content type' do
  user = create(:user)
  get user_path(user)
  expect(response.content_type).to eq('application/json')
end
```

- Test valid, edge, and invalid/error cases. If there are too many cases, the subject class may have too many responsibilities:

```ruby
describe '#destroy' do
  context 'when the product exists' do
    it 'deletes the product' do; end
  end

  context 'when the product does not exist' do
    it 'raises 404' do; end
  end

  context 'when user is not authenticated' do
    it 'raises 404' do; end
  end
end
```

## Mocking & Stubbing

- Use `instance_double` over `double` — it verifies methods exist on the real class, catching typos and renames immediately:

```ruby
# Good — fails if User doesn't have a `name` method
user = instance_double(User, name: "Gustavo Kuerten")

# Bad — silently passes even if `name` doesn't exist on User
user = double(:user, name: "Gustavo Kuerten")
```

- Mock external dependencies (APIs, third-party services) to isolate code under test:

```ruby
# Good
it 'displays the number of stars' do
  expect(Github).to receive(:fetch_repository_stars).with(1).and_return(10)
  expect(subject.github_stars(1)).to eq('Stars: 10')
end

# Bad — relies on real external API
it 'displays the number of stars' do
  expect(subject.github_stars(1)).to eq('Stars: 10')
end
```

- Stub HTTP requests with WebMock or VCR — never make real HTTP calls in tests
- Stub environment variables explicitly in tests rather than relying on `.env` files:

```ruby
# Good — self-contained
it 'prepares the email' do
  stub_env('SALES_TEAM_EMAIL', 'sales-group@company.com')
  subject = described_class.notify_sales_team
  expect(subject.to).to eq(['sales-group@company.com'])
end

# Bad — depends on .env.test file, not visible in the test
it 'prepares the email' do
  subject = described_class.notify_sales_team
  expect(subject.to).to eq(['sales-group@company.com'])
end
```

## Syntax & Style

- Always use `expect` syntax, never `should`:

```ruby
# Good
expect(response.code).to eq('200')

# Bad
response.code.should eq('200')
```

- Prefer request specs (`type: :request`) over controller specs (`type: :controller`). Request specs exercise the full middleware stack, router, and rack — controller specs don't
- Don't add `require 'rails_helper'` to spec files — configure it in `.rspec` instead
