defmodule Matcha.MixProject do
  use Mix.Project

  @name "Matcha"
  @description "First-class match specification and match patterns for Elixir"
  @authors ["Chris Keele"]
  @maintainers ["Chris Keele"]
  @licenses ["MIT"]

  @release_branch "release"

  @github_url "https://github.com/christhekeele/matcha"
  @homepage_url @github_url

  def project,
    do: [
      # Application
      app: :matcha,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      version: "VERSION" |> File.read!() |> String.trim(),
      extra_applications: extra_applications(Mix.env()),
      # Informational
      name: @name,
      description: @description,
      source_url: @github_url,
      homepage_url: @homepage_url,
      # Configuration
      aliases: aliases(),
      deps: deps(),
      docs: docs(),
      package: package(),
      preferred_cli_env: preferred_cli_env(),
      test_coverage: test_coverage()
    ]

  defp extra_applications(:prod), do: []

  defp extra_applications(_env),
    do: [
      :dialyzer
    ]

  defp aliases,
    do: [
      # Combination check utility
      checks: [
        "test",
        "lint",
        "typecheck"
      ],
      # Documentation tasks
      "docs.coverage": "inch",
      "docs.coverage.report": "inch.report",
      # Mix installation tasks
      install: [
        "install.rebar",
        "install.hex",
        "install.deps"
      ],
      "install.rebar": "local.rebar --force",
      "install.hex": "local.hex --force",
      "install.deps": "deps.get",
      # Linting tasks
      lint: [
        "lint.compile",
        "lint.format",
        "lint.style"
      ],
      "lint.compile": "compile --force --warnings-as-errors",
      "lint.format": "format --check-formatted",
      "lint.style": "credo --strict",
      # Release tasks
      "release.major":
        "expublish.major --version-file=VERSION --changelog-date-time --commit-prefix=\"Publishing release version\"",
      "release.minor":
        "expublish.minor --version-file=VERSION --changelog-date-time --commit-prefix=\"Publishing release version\"",
      "release.patch":
        "expublish.patch --version-file=VERSION --changelog-date-time --commit-prefix=\"Publishing release version\"",
      # Prerelease tasks
      "prerelease.rc":
        "expublish.rc --version-file=VERSION --changelog-date-time --commit-prefix=\"Publishing prerelease version\"",
      "prerelease.beta":
        "expublish.beta --version-file=VERSION --changelog-date-time --commit-prefix=\"Publishing prerelease version\"",
      "prerelease.alpha":
        "expublish.alpha --version-file=VERSION --changelog-date-time --commit-prefix=\"Publishing prerelease version\"",
      # Typecheck tasks
      typecheck: [
        "typecheck.dialyzer"
      ],
      "typecheck.cache": "dialyzer --plt",
      "typecheck.dialyzer": "dialyzer --no-check --halt-exit-status",
      # Test tasks
      test: [
        "test"
      ],
      "test.focus": "test --only focus",
      "test.coverage": "coveralls",
      "test.coverage.report": "coveralls.github"
    ]

  defp deps,
    do: [
      {:recon, ">= 2.2.0"},
      {:dialyzex, "~> 1.2", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.26", only: [:dev, :test], runtime: false},
      # {:inch_ex, github: "rrrene/inch_ex", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.14", only: [:dev, :test]},
      {:expublish, "~> 2.5", only: [:dev, :test]}
    ]

  defp docs,
    do: [
      # Metadata
      name: @name,
      authors: @authors,
      source_ref: @release_branch,
      source_url: @github_url,
      homepage_url: @homepage_url,
      # Files and Layout
      extra_section: "OVERVIEW",
      main: "Matcha",
      logo: "docs/img/logo.png",
      extras: [
        # Guides
        "docs/guides/usage.livemd": [filename: "usage", title: "Using Matcha"],
        "docs/guides/usage/filtering-and-mapping.livemd": [
          filename: "filtering-and-mapping",
          title: "...for Filtering/Mapping"
        ],
        "docs/guides/usage/tables.livemd": [
          filename: "tables",
          title: "...for ETS/DETS/Mnesia"
        ],
        "docs/guides/usage/tracing.livemd": [
          filename: "tracing",
          title: "...for Tracing"
        ],
        # Reference
        "CHANGELOG.md": [filename: "changelog", title: "Changelog"],
        "CONTRIBUTING.md": [filename: "contributing", title: "Contributing"],
        "LICENSE.md": [filename: "license", title: "License"]
      ],
      groups_for_extras: [
        Guides: ~r/docs\/guides/,
        Reference: [
          "CHANGELOG.md",
          "CONTRIBUTING.md",
          "LICENSE.md"
        ]
      ],
      groups_for_modules: [
        Contexts: [
          Matcha.Context,
          Matcha.Context.Common,
          Matcha.Context.FilterMap,
          Matcha.Context.Table,
          Matcha.Context.Trace
        ],
        Exceptions: [
          Matcha.Error,
          Matcha.Pattern.Error,
          Matcha.Rewrite.Error,
          Matcha.Spec.Error,
          Matcha.Trace.Error
        ],
        Internals: [
          Matcha.Rewrite,
          Matcha.Source
        ]
      ]
    ]

  # Hex.pm information
  defp package,
    do: [
      maintainers: @maintainers,
      licenses: @licenses,
      links: %{
        Home: @homepage_url,
        GitHub: @github_url
      },
      files: [
        "lib",
        "docs/guides",
        "mix.exs",
        "CHANGELOG.md",
        "CONTRIBUTING.md",
        "LICENSE.md",
        "README.md",
        "VERSION"
      ]
    ]

  defp preferred_cli_env,
    do: [
      checks: :test,
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.github": :test,
      "coveralls.github": :test,
      "coveralls.html": :test,
      "coveralls.html": :test,
      "coveralls.post": :test,
      "coveralls.post": :test,
      "coveralls.travis": :test,
      "coveralls.travis": :test,
      credo: :test,
      dialyzer: :test,
      docs: :test,
      test: :test,
      "test.coverage.report": :test,
      "test.coverage": :test,
      "test.focus": :test
      # inch: :test,
      # "inchci.add": :test,
      # "inch.report": :test
    ]

  defp test_coverage,
    do: [
      tool: ExCoveralls
    ]
end
