defmodule Apq.MixProject do
  use Mix.Project

  @version "1.0.1"
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
        files: ~w(LICENSE README.md lib mix.exs)
      ],
      source_url: "https://github.com/maartenvanvliet/apq",
      docs: [
        main: "readme",
        extras: ["README.md"]
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
      {:benchee, "~> 0.13", only: [:dev, :test]},
      {:absinthe_plug, "~> 1.4.5"},
      {:jason, "~> 1.1", only: :test},
      {:ex_doc, "~> 0.19.1", only: :dev},
      {:mox, "~> 0.4", only: :test}
    ]
  end
end
