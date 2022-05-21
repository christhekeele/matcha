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
      dialyzer: dialyzer(),
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
      # Combination clean utility
      clean: [
        "typecheck.clean",
        "deps.clean --all",
        &clean_build_folders/1
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
      release: "hex.publish",
      # Typecheck tasks
      typecheck: [
        "typecheck.run"
      ],
      "typecheck.build-cache": "dialyzer --plt --format dialyxir",
      "typecheck.clean": "dialyzer.clean",
      "typecheck.explain": "dialyzer.explain --format dialyxir",
      "typecheck.run": "dialyzer --format dialyxir",
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
      {:recon, ">= 2.2.0", manager: :rebar3},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.28", only: [:dev, :test], runtime: false},
      # {:inch_ex, github: "rrrene/inch_ex", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.14 and >= 0.14.4", only: [:dev, :test]}
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
          Matcha.Context.Erlang,
          Matcha.Context.FilterMap,
          Matcha.Context.Match,
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
          Matcha.Rewrite.Kernel,
          Matcha.Source
        ]
      ]
    ]

  # Control dialyzer success-typing engine
  defp dialyzer,
    do: [
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
      flags: ["-Wunmatched_returns", :error_handling, :race_conditions, :underspecs],
      ignore_warnings: ".dialyzer_ignore.exs",
      list_unused_filters: true,
      # plt_add_deps: :apps_direct,
      plt_add_apps: [],
      plt_ignore_apps: []
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
        "docs",
        "mix.exs",
        "CHANGELOG.md",
        "CONTRIBUTING.md",
        "LICENSE.md",
        "README.md",
        "VERSION"
      ]
    ]

  defp preferred_cli_env,
    do: aliases() |> Keyword.keys() |> Enum.map(fn alias -> {alias, :test} end)

  defp test_coverage,
    do: [
      tool: ExCoveralls
    ]

  defp clean_build_folders(_) do
    ~w[doc cover _build deps] |> Enum.map(&File.rm_rf!/1)
  end
end
