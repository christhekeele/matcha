defmodule Matcha.MixProject do
  use Mix.Project

  def project,
    do: [
      app: :matcha,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs()
    ]

  def application,
    do: [
      extra_applications: [:logger]
    ]

  defp deps,
    do: [
      {:ex_doc, "~> 0.23", only: :dev, runtime: false}
      # Benchmarks
    ]

  defp docs,
    do: [
      # Metadata
      name: "Matcha",
      authors: ["Chris Keele"],
      source_ref: "release",
      source_url: "https://github.com/christhekeele/matcha",
      homepage_url: "http://YOUR_PROJECT_HOMEPAGE",
      # Files and Layout
      extra_section: "GUIDES",
      docs: [
        main: "matcha",
        # logo: "path/to/logo.png",
        extras: ["README.md", ~r|guides/*\.md|]
      ],
      groups_for_modules: [
        Internals: [
          Matcha.Source,
          Matcha.Rewrite,
          Matcha.Context,
          Matcha.Context.Table,
          Matcha.Context.Trace
        ],
        Exceptions: ~r|Matcha\.(.*?)Error|
      ]
    ]
end
