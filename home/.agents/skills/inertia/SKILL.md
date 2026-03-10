---
name: inertia
description: Build, debug, and maintain full-stack Rails + React applications using Inertia.js. Use when working with Inertia.js, inertia-rails gem, useForm, usePage, router, shared props, page props, deferred props, SSR, or when the user mentions Inertia, inertia_share, render inertia:, or Link/Form components.
allowed-tools: Read, Write, Edit, Glob, Grep
---

# Inertia.js (Rails + React)

Inertia.js bridges Rails controllers with React components, enabling SPA-style navigation without a separate API. This skill covers the full inertia-rails stack.

## First step

Before working on any Inertia.js task, fetch and read the full documentation:

```
https://inertia-rails.dev/llms-full.txt
```

Use the WebFetch tool to retrieve this URL and read it fully. It is the authoritative source for inertia-rails API and conventions.

## Core Patterns

### Rendering from controllers

```ruby
# Basic render
render inertia: 'Users/Index', props: { users: User.all }

# With deferred (expensive) props
render inertia: 'Users/Index', props: {
  users: User.all,
  stats: InertiaRails.defer { compute_stats }
}
```

Component names map to files under `app/frontend/pages/` (or your configured pages dir).

### Shared props

Use `inertia_share` in `ApplicationController` for data needed on every page:

```ruby
class ApplicationController < ActionController::Base
  inertia_share auth: -> { { user: current_user } }
  inertia_share flash: -> { flash.to_hash }
end
```

### Page props in React

```jsx
import { usePage } from '@inertiajs/react'

export default function Dashboard() {
  const { auth, users } = usePage().props
  return <div>Hello, {auth.user.name}</div>
}
```

### Forms

Prefer `useForm` for forms with validation:

```jsx
import { useForm } from '@inertiajs/react'

export default function CreateUser() {
  const { data, setData, post, processing, errors } = useForm({
    name: '',
    email: '',
  })

  function submit(e) {
    e.preventDefault()
    post('/users')
  }

  return (
    <form onSubmit={submit}>
      <input value={data.name} onChange={e => setData('name', e.target.value)} />
      {errors.name && <div>{errors.name}</div>}
      <button disabled={processing}>Create</button>
    </form>
  )
}
```

For simple cases, use the `<Form>` component:

```jsx
import { Form } from '@inertiajs/react'

<Form action="/users" method="post">
  <input type="text" name="name" />
  <button type="submit">Create</button>
</Form>
```

### Navigation

```jsx
import { Link, router } from '@inertiajs/react'

// Declarative
<Link href="/users">View Users</Link>

// Programmatic
router.get('/users')
router.post('/users', { name: 'Alice' })
router.visit('/users', { method: 'delete' })

// Partial reload (only fetch specific props)
router.reload({ only: ['users'] })
```

### Validation errors

Rails validation errors are automatically passed as `errors` props. In controllers:

```ruby
def create
  user = User.new(user_params)
  if user.save
    redirect_to users_path
  else
    render inertia: 'Users/Create', props: {
      errors: user.errors.as_json(full_messages: true)
    }
  end
end
```

Or use the inertia-rails helper:

```ruby
redirect_to users_path, inertia: { errors: user.errors }
```

### SSR

Configure in `config/initializers/inertia_rails.rb`:

```ruby
InertiaRails.configure do |config|
  config.ssr_enabled = Rails.env.production?
  config.version = ViteRuby.digest
end
```

SSR requires a separate Node.js renderer process. Components must be SSR-safe (no browser-only globals at module level).

## Key conventions

- Authorization: check server-side, pass results as props (`can: { edit: policy.edit? }`)
- Flash messages: expose via `inertia_share`, consume from `usePage().props.flash`
- Asset versioning: always configure `config.version` to trigger hard reloads on deploy
- Prop casing: use `prop_transformer` or manual `.camelize` if Rails snake_case conflicts with JS camelCase expectations
- Keep controller logic server-side; React components are display/interaction only

## Debugging

- Non-Inertia responses (errors, missing layout) appear as modal overlays in development
- Check that `layout: 'inertia'` (or `layout false`) is set on the controller/action
- Verify the `X-Inertia` request header is present on XHR navigation requests
- Shared prop lambdas are evaluated per request — avoid N+1 queries inside them
- Use `only:` partial reloads to debug which props are causing slow responses
