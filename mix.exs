defmodule Matcha.MixProject do
  use Mix.Project

  def project do
    [
      app: :matcha,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ] ++ docs()
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.23", only: :dev, runtime: false}
      # Benchmarks
    ]
  end

  defp docs,
    do: [
      name: "Matcha",
      authors: ["Chris Keele"],
      source_ref: "release",
      source_url: "https://github.com/christhekeele/matcha",
      homepage_url: "http://YOUR_PROJECT_HOMEPAGE",
      extra_section: "GUIDES",
      docs: [
        main: "Matcha",
        # logo: "path/to/logo.png",
        extras: ["README.md"]
      ]
    ]
end
