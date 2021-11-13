defmodule Apq.MixProject do
  use Mix.Project

  @version "2.0.0"
  def project do
    [
      app: :apq,
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      aliases: aliases(),
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
  defp elixirc_paths(:dev), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      bench: &bench/1
    ]
  end

  defp bench(arglist) do
    Mix.Tasks.Run.run(["benchmark/apq.exs" | arglist])
  end

  defp deps do
    [
      {:absinthe_plug, "~> 1.5"},
      {:jason, "~> 1.1", only: [:dev, :test]},
      {:ex_doc, "~> 0.22", only: :dev},
      {:mox, "~> 1.0", only: :test},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:cachex, "~> 3.3", only: [:dev, :test]},
      {:benchee, "~> 1.0", only: :dev}
    ]
  end
end
