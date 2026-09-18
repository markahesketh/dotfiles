# Factual conflict between the two eval-3 runs, resolved against source

Claim under dispute: can the `status-filter-open` badge node exist before its count
has arrived, giving the cucumber step a race to scrape a stale number?

- with_skill said YES: the `stats` Inertia prop is `defer: true`, so the badge paints
  before the count arrives, and only a retrying assertion closes the gap.
- without_skill said NO: `QuickFilters` early-returns a `Skeleton` while `stats` is
  unresolved, so the node cannot exist before the count.

## without_skill is correct

`app/views/tasks/QuickFilters.tsx:286-297`

    export const QuickFilters = (props: Props) => {
      ...
      if (!props.stats) {
        return (<div className="flex justify-between">
          <Skeleton className="rounded-full h-10 w-150" /> ...

`statusFilterList(props.stats, ...)` runs only after that guard, and the
`status-filter-*` testid is rendered by the link component it builds. So the testid
does not exist until `stats` is resolved. `find_testid` is Capybara `find`, which
waits. There is no race of the kind the reviewer described, and with_skill's
`defer: true` reasoning reached the wrong conclusion by not checking the component.

## The bug without_skill found instead is real

`QuickFilters.tsx:231` renders `{filter.count.toLocaleString()}`, so a count of 1234
renders "1,234". The step does `Integer(find_testid(...).text[/\d+/])`, and `/\d+/`
matches only the first digit run, yielding 1. Silent wrong answer, latent only
because current scenario counts are small.
