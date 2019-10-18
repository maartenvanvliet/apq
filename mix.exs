defmodule Apq.MixProject do
  use Mix.Project

  @version "1.2.0"
  def project do
    [
      app: :apq,
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      name: "Apq",
      description: "Support for Automatic Persisted Queries in Absinthe",
      package: [
        maintainers: ["Maarten van Vliet"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/maartenvanvliet/apq"},
        files: ~w(LICENSE README.md CHANGELOG.md lib mix.exs)
      ],
      source_url: "https://github.com/maartenvanvliet/apq",
      docs: [
        main: "readme",
        extras: ["README.md", "CHANGELOG.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:absinthe_plug,
       git: "https://github.com/absinthe-graphql/absinthe_plug.git", branch: "master"},
      {:jason, "~> 1.1", only: [:dev, :test]},
      {:ex_doc, "~> 0.21.0", only: :dev},
      {:mox, "~> 0.4", only: :test},
      {:credo, "~> 1.1.0", only: [:dev, :test], runtime: false}
    ]
  end
end
