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
      version: "0.1.1",
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
      release: [],
      # Typecheck tasks
      typecheck: [
        "typecheck.dialyzer"
      ],
      "typecheck.cache": [
        "cmd mkdir -p priv/plts",
        "dialyzer --plt"
      ],
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
      {:recon, "~> 2.5"},
      {:dialyzex, "~> 1.2", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.26", only: [:dev, :test], runtime: false},
      # {:inch_ex, github: "rrrene/inch_ex", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: [:dev, :test]}
      # {:expublish, "~> 2.3", only: [:dev, :test]}
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
      logo: "img/logo.png",
      extras: [
        "README.md": [filename: "readme", title: "README"],
        "playgrounds/intro.livemd": [],
        "guides/overview.md": [filename: "overview", title: "Guides"],
        "guides/concepts.md": [
          filename: "concepts",
          title: "Patterns and Specs"
        ],
        "guides/usage.md": [filename: "usage", title: "Using Matcha"],
        "guides/usage/filtering-and-mapping.md": [
          filename: "filtering-and-mapping",
          title: "...for Filtering/Mapping"
        ],
        "guides/usage/ets.md": [
          filename: "ets",
          title: "...for ETS"
        ],
        "guides/usage/tracing.md": [
          filename: "tracing",
          title: "...for Tracing"
        ],
        "guides/internals/erlang-format.md": [
          filename: "internals-erlang-format",
          title: "Internal Erlang Format"
        ],
        "guides/internals/spec-contexts.md": [
          filename: "internals-spec-contexts",
          title: "Internal Spec Contexts"
        ],
        "LICENSE.md": [filename: "license", title: "LICENSE"]
      ],
      groups_for_extras: [],
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
        "mix.exs",
        "guides",
        "README.md",
        "LICENSE.md"
      ]
    ]

  defp preferred_cli_env,
    do: [
      test: :test,
      "test.focus": :test,
      "test.coverage": :test,
      "test.coverage.report": :test,
      "coveralls.github": :test,
      "coveralls.html": :test,
      "coveralls.post": :test,
      "coveralls.travis": :test,
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.github": :test,
      "coveralls.html": :test,
      "coveralls.post": :test,
      "coveralls.travis": :test,
      credo: :test,
      dialyzer: :test,
      docs: :test
      # inch: :test,
      # "inchci.add": :test,
      # "inch.report": :test
    ]

  defp test_coverage,
    do: [
      tool: ExCoveralls
    ]
end
