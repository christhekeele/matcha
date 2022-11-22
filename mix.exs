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

  @dev_envs [:dev, :test]

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

  def application, do: [mod: {Matcha.Application, []}]

  defp extra_applications(:prod), do: []

  defp extra_applications(_env),
    do: [
      :dialyzer
    ]

  defp aliases,
    do: [
      # Benchmark report generation
      benchmarks: [
        "test --include benchmark",
        "benchmarks.index"
      ],
      "benchmarks.index": &index_benchmarks/1,
      # Combination check utility
      checks: [
        "test.suite",
        "lint",
        "typecheck"
      ],
      # Combination clean utility
      clean: [
        "typecheck.clean",
        "deps.clean --all",
        &clean_build_folders/1
      ],
      # Coverage report generation
      coverage: "coveralls.html --include doctest --include unit --include usage",
      # Documentation tasks
      "docs.coverage": "doctor",
      # "docs.coverage": "inch",
      # "docs.coverage.report": "inch.report",
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
      # Static pages tasks
      static: [
        "benchmarks",
        "coverage",
        "docs",
        &collect_static_pages/1
      ],
      # Typecheck tasks
      typecheck: [
        "typecheck.run"
      ],
      "typecheck.build-cache": "dialyzer --plt --format dialyxir",
      "typecheck.clean": "dialyzer.clean",
      "typecheck.explain": "dialyzer.explain --format dialyxir",
      "typecheck.run": "dialyzer --format dialyxir",
      # Test tasks
      "test.benchmark": "test --include benchmark",
      "test.doctest": "test --include doctest",
      "test.usage": "test --include usage",
      "test.unit": "test --include unit",
      # test everything but benchmarks
      "test.suite": [
        "test --include doctest --include unit --include usage"
      ],
      # coverage for everything but benchmarks
      "test.coverage": "coveralls --include doctest --include unit --include usage",
      "test.coverage.report": "coveralls.github --include doctest --include unit --include usage"
    ]

  defp deps,
    do: [
      {:recon, ">= 2.3.0"},
      # Dev tooling
      {:benchee, "~> 1.0", only: @dev_envs, runtime: false},
      {:benchee_html, "~> 1.0", only: @dev_envs, runtime: false},
      {:credo, "~> 1.6", only: @dev_envs, runtime: false},
      {:dialyxir, "~> 1.0", only: @dev_envs, runtime: false},
      {:doctor, "~> 0.18", only: @dev_envs, runtime: false},
      {:ex_doc, "~> 0.28", only: @dev_envs, runtime: false},
      {:excoveralls, "~> 0.14 and >= 0.14.4", only: @dev_envs},
      {:jason, ">= 0.0.1", only: @dev_envs, runtime: false}
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
      flags:
        ["-Wunmatched_returns", :error_handling, :underspecs] ++
          if :erlang.system_info(:otp_release) != '25' do
            [:race_conditions]
          else
            []
          end,
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
    ~w[_build bench cover deps doc] |> Enum.map(&File.rm_rf!/1)
  end

  defp index_benchmarks(_) do
    list_items =
      Path.wildcard("bench/*/**/*.html")
      |> Enum.map(fn html_file ->
        relative_file = String.replace_leading(html_file, "bench/", "")
        ~s|<li><a href="#{relative_file}">#{html_file}</a></li>|
      end)

    index_html = ["<ul>", list_items, "</ul>"]

    File.write!("bench/index.html", index_html)
  end

  defp collect_static_pages(_) do
    File.mkdir_p!("static")

    File.cp_r!("bench", "static/bench")

    File.mkdir_p!("static/cover")
    File.cp!("cover/excoveralls.html", "static/cover/index.html")

    File.cp_r!("doc", "static/doc")

    File.write!("static/index.html", ~s|
      <ul>
        <li><a href="bench/index.html">Benchmarks</a></li>
        <li><a href="cover/index.html">Coverage</a></li>
        <li><a href="doc/index.html">Documentation</a></li>
    |)
  end
end
