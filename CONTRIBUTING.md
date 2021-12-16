# Contributing

Thanks for considering contributing to Matcha!

## Places to Start

We cultivate [a set of issues][open-issues-good-first-issue] that are good ways to contribute to Matcha for the first time.

Looking for other ways to contribute? Consider:

- **_[Improving the documentation][open-issues-kind-documentation]_**

  Documentation is the most valuable contribution you can make directly to the repository!

  It is easy to overlook documentation when programming, and difficult to look back on something you understand and see where others may get confused.

  This makes it hard to keep documentation high-quality, and all assistance in fighting entropy is invaluable!

- **_[Tackling something that doesn't require extensive knowledge of the codebase][open-issues-level-simple]_**

  These are less-involved issues that should be approachable without spending a bunch of time studying the entire project.

  They generally touch parts of the library that are similar across other Elixir and open-source projects.

- **_[Addressing regressions in upcoming releases to the language][open-upcoming-regressions]_**

  Matcha continuously looks ahead to upcoming language releases, running its test suite against them to anticipate compatibility issues.

  If a storm is brewing on the horizon, the bleeding-edge test suite normally catches it, with more than enough time for someone to jump in and deal with the regression.

- **_[Submitting a PR][open-a-pr]_**

  See a typo or a broken link? Is existing documentation unclear, or does following it lead to behaviour you consider surprising? Jump in and help us correct it!

- **_[Starting a discussion][open-a-new-discussion]_**

  Have an idea for an improvement or an enhancement, but don't see a issue for it yet? Crack open a discussion and flesh it out with the maintainers!

- **_[Opening a new issue][open-a-new-issue]_**

  Is something else the matter, or do the ideas above not fit what you have in mind? Create an issue and continue the conversation!

## Code

Want to contribute code? Here's what you need to know.

### Structure

Matcha is a pretty standard Elixir library, and should be navigable to anyone familiar with such things. Here is the map, with points of interest:

```
matcha
│
├── CONTRIBUTING.md   # YOU ARE HERE
│
├── README.md         # Project landingpad
├── mix.exs           # Project manifest
│
├── VERSION           # Library version
├── lib/              # Library source code
│
├── test/             # Test suite
│
├── docs/             # Extra material for docgen
│   ├── img/          # Images used in docs
│   └── guides/       # Additional guides
│
├── RELEASE.md        # Changes for next release
├── CHANGELOG.md      # Changes from prior releases
│
└── LICENSE.md        # Legalese
```

### Tooling

Matcha has three different checks that run in continuous integration. If you want to get ahead of build failures, you can run them all locally before pushing up code via `mix checks`. This is equivalent to running:

- `mix test`

  Runs the tests found in `test/`, checking for failures.

- `mix lint`

  Checks for compiler warnings, formatting divergences, and [style problems][credo].

- `mix typecheck`

  Runs [dialyzer][dialyzer], checking for provable type issues.

<!-- Places to start -->

[open-issues-good-first-issue]: https://github.com/christhekeele/matcha/labels/good%20first%20issue
[open-issues-kind-documentation]: https://github.com/christhekeele/matcha/labels/Kind%3A%20Documentation
[open-issues-level-simple]: https://github.com/christhekeele/matcha/labels/Level%3A%20Simple
[open-upcoming-regressions]: https://github.com/christhekeele/matcha/actions/workflows/edge.yml
[open-a-pr]: https://github.com/christhekeele/matcha/compare
[open-a-new-discussion]: https://github.com/christhekeele/matcha/discussions/new
[open-a-new-issue]: https://github.com/christhekeele/matcha/issues/new

<!-- Tooling -->

[credo]: https://github.com/rrrene/credo
[dialyzer]: https://www.erlang.org/doc/man/dialyzer.html
