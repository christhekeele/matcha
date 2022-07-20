# Contributing

Thanks for considering contributing to Matcha!

## Quickstart

Assuming you have the [GitHub cli](https://cli.github.com/) and the [`asdf` version manager](https://asdf-vm.com/) installed:

```sh
# Acquire a copy of the code
gh repo fork git@github.com:christhekeele/matcha.git --remote
cd matcha

# Install dependencies
asdf install
mix deps.get

# Start work
git checkout -b <some-branch-name>
# ...do changes, commits, pushes, etc
mix checks
# ...address reported test failures, type issues, linting problems

# Submit PR
gh pr create
```

If you are not using `gh` or `asdf`, you should fork Matcha [from the source](https://github.com/christhekeele/matcha) and set up your erlang and Elixir installations on your machine to match those described in [.tool-versions](.tool-versions) yourself.

## What to Contribute

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

### Project Structure

Matcha is a pretty standard Elixir library, and should be navigable to anyone familiar with such things. Here is the map, with points of interest where it may deviate from a typical project:

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
│   ├── docs/         #   Tests of moduledocs as laid out in lib/
│   ├── unit/         #   Tests modules as laid out in lib/
│   └── usecases/     #   Tests derived from realworld ms usage
│
├── docs/             # Extra material for docgen
│   ├── img/          #   Images used in docgen
│   └── guides/       #   Interactive livebook guides
│
├── bench/            # Benchmark suite
│
├── CHANGELOG.md      # Describes changes in each release
│
└── LICENSE.md        # License Matcha is available under
```

### Branches & Tags

- [`latest`][branch-latest] is the default integration branch where work comes together.

  This means that you can get the "cutting edge" version of Matcha via:

  ```elixir
  Mix.install matcha: [github: "christhekeele/matcha", ref: "latest"]
  ```

- [`release`][branch-release] is the staging branch where code intended for the next release is placed.

  This means that you can get the "release candidate" version of Matcha via:

  ```elixir
  Mix.install matcha: [github: "christhekeele/matcha", ref: "release"]
  ```

- [`stable`][tag-stable] is a floating tag pointing to the "highest" semantic version of Matcha released to [hex.pm][hex-matcha].

  This means that the "latest official" version of Matcha is available identically via:

  ```elixir
  Mix.install matcha: [github: "christhekeele/matcha", ref: "stable"]
  ```

  and

  ```elixir
  Mix.install matcha: ">= 0.0.0"
  ```

- [tags starting with `v`][hex-versions], ex `vX.Y.Z-mayberc`, represent [semantic versions](https://semver.org/) published to [hex.pm][hex-matcha].

  If versions must be modified or yanked, currently these tags should be deleted or moved manually.

  This means that these two are equivalent:

  ```elixir
  Mix.install matcha: [github: "christhekeele/matcha", ref: "vX.Y.Z-mayberc"]
  ```

  and

  ```elixir
  Mix.install matcha: "vX.Y.Z-mayberc"
  ```

All other branch or tag names are fair game.

## Docs

### Code Documentation

Matcha uses `ex_doc` to generate documentation from source code automatically on every release.

If you're developing documentation, you can preview it locally by running:

```sh
mix docs
open doc/index.html
```

The warnings emitted by `ex_doc` are useful and worth keeping an eye on!

You can also get and overview of the current documentation coverage status by running:

```sh
mix docs.coverage
```

### Guides

Matcha also includes a set of interactive guides powered by [LiveBook][livebook].

They are maintained in the [docs/guides][guides] folder. They are best developed against a [local instance][livebook-locally-escript] of livebook, via:

```sh
LIVEBOOK_TOKEN_ENABLED=false livebook server --root-path docs/guides
```

Avoid having the `.livemd` files also open in an editor as you work on a guide, to avoid getting into save-tug-of-war!

## Checks

Matcha has three different checks that may run during various automatic builds. If you want to get ahead of build failures, you can run them all locally before pushing up code with the command `mix checks`.
This is equivalent to running:

- `mix test`

  Runs the tests found in `test/`, checking for failures.

- `mix typecheck`

  Runs [dialyzer][dialyzer], checking for provable type issues.

- `mix lint`

  Checks for compiler warnings, formatting divergences, and [style problems][credo].

### CI Suites

Matcha has 5 test suites that run different checks automatically, depending on what's happening, for different versions of erlang/OTP, Elixir, and Matcha's dependencies.

#### Versions

The sets of versions we run checks against are named:

- `preferred`

  - `otp`: The latest minor version of the highest major version erlang we want to support

  - `elixir`: The latest patch version of highest minor Elixir we want to support

  - `deps`: The locked-down version of our dependencies in our `mix.lock`

- `matrix`

  - `otp`: The latest minor versions of every major erlang version we want to support

  - `elixir`: The latest patch versions of every minor Elixir version we want to support

  - `deps`: The locked-down version of our dependencies in our `mix.lock`

- `edge`

  - `otp`: The latest major version erlang

  - `elixir`: The upcoming version of Elixir available on its default branch

  - `deps`: The un-locked version of dependencies in our `mix.exs`

#### Workflows

The automated test workflows we run are:

- **[Test Suite][test-suite]**

  - **Runs on** every set of commits pushed up to GitHub, on source or forked repositories.

  - **Runs** all `mix checks` for the `preferred` versions of our dependencies.

  - **Provides** continuous feedback on every potential change to the codebase.

- **[Test Status][test-status]**

  - **Runs on** every set of commits and every PR into the `latest` and `release` branches.

  - **Runs** the _Test Suite_, and updates related code quality services about its robustness.

  - **Provides** insight into test meta-data like code coverage, documentation quality, etc. displayed in the README.md.

- **[Test Matrix][test-matrix]**

  - **Runs on** every set of commits and every PR into the `latest` and `release` branches.

  - **Runs** all `mix checks` for every set of versions in our `matrix` of dependencies.

  - **Provides** full feedback on if each approved change will work on all supported versions.

- **[Test Release][test-release]**

  - **Runs on** every set of commits added to pull requests to the `release` branch.

  - **Performs** a dry-run of a planned release.

  - **Provides** a preview of what a release would look like if published from the `release` branch.

- **[Test Edge][test-edge]**

  - **Runs automatically** UTC midnight.

  - **Runs** all `mix checks` for the `edge` versions of our dependencies.

  - **Provides** continuous feedback on how prepared the codebase is for upstream changes in dependencies.

<!-- Places to start -->

[open-issues-good-first-issue]: https://github.com/christhekeele/matcha/labels/good%20first%20issue
[open-issues-kind-documentation]: https://github.com/christhekeele/matcha/labels/Kind%3A%20Documentation
[open-issues-level-simple]: https://github.com/christhekeele/matcha/labels/Level%3A%20Simple
[open-upcoming-regressions]: https://github.com/christhekeele/matcha/actions/workflows/edge.yml
[open-a-pr]: https://github.com/christhekeele/matcha/compare
[open-a-new-discussion]: https://github.com/christhekeele/matcha/discussions/new
[open-a-new-issue]: https://github.com/christhekeele/matcha/issues/new

<!-- Code Locations -->

[branch-latest]: https://github.com/christhekeele/matcha/tree/latest
[branch-release]: https://github.com/christhekeele/matcha/tree/release
[tag-stable]: https://github.com/christhekeele/matcha/tree/stable
[hex-matcha]: https://hex.pm/packages/matcha
[hex-versions]: https://hex.pm/packages/matcha/versions

<!-- Tooling -->

[credo]: https://github.com/rrrene/credo
[dialyzer]: https://www.erlang.org/doc/man/dialyzer.html

<!-- Guides -->

[livebook]: https://github.com/livebook-dev/livebook
[livebook-locally-escript]: https://github.com/livebook-dev/livebook#escript
[guides]: https://github.com/christhekeele/matcha/actions/workflows/test-suite.yml

<!-- Workflows -->

[test-suite]: https://github.com/christhekeele/matcha/actions/workflows/test-suite.yml
[test-matrix]: https://github.com/christhekeele/matcha/actions/workflows/test-matrix.yml
[test-release]: https://github.com/christhekeele/matcha/actions/workflows/test-release.yml
[test-status]: https://github.com/christhekeele/matcha/actions/workflows/test-status.yml
[test-edge]: https://github.com/christhekeele/matcha/actions/workflows/test-edge.yml
