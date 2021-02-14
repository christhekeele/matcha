defmodule Matcha.MixProject do
  use Mix.Project

  def project,
    do: [
      app: :matcha,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      docs: docs()
    ]

  def application,
    do: [
      extra_applications: [:logger]
    ]

  defp deps,
    do: [
      {:dialyzex, "~> 1.2", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.23", only: [:dev, :test, :docs], runtime: false},
      {:inch_ex, github: "rrrene/inch_ex", only: [:dev, :test, :docs]}
    ]

  defp docs,
    do: [
      # Metadata
      name: "Matcha",
      authors: ["Chris Keele"],
      source_ref: "release",
      source_url: "https://github.com/christhekeele/matcha",
      homepage_url: "https://github.com/christhekeele/matcha",
      # Files and Layout
      extra_section: "OVERVIEW",
      main: "Matcha",
      # logo: "path/to/logo.png",
      extras: [
        "README.md": [filename: "README", title: "Matcha"],
        "guides/ets.md": [filename: "with-ets", title: "with ETS"],
        "guides/tracing.md": [filename: "with-tracing", title: "with Tracing"]
      ],
      groups_for_modules: [
        Internals: [
          Matcha.Context,
          Matcha.Context.Table,
          Matcha.Context.Trace,
          Matcha.Rewrite,
          Matcha.Source
        ],
        Exceptions: [
          Matcha.Error,
          Matcha.Pattern.Error,
          Matcha.Rewrite.Error,
          Matcha.Spec.Error
        ]
      ]
    ]

  defp aliases(), do: []
end
