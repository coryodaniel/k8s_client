defmodule K8s.Client.MixProject do
  use Mix.Project

  def project do
    [
      app: :k8s_client,
      description: "An experimental k8s client.",
      version: "0.1.3",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.travis": :test
      ],
      docs: [
        extras: ["README.md"],
        main: "readme"
      ],
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.5"},
      {:jason, "~> 1.1"},
      {:k8s_conf, "~> 0.1"},

      # Dev dependencies
      {:mix_test_watch, "~> 0.8", only: :dev, runtime: false},
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.19", only: :dev},
      {:bypass, "~> 1.0", only: :test},
      {:excoveralls, "~> 0.10", only: :test},
      {:stream_data, "~> 0.4", only: :test}
    ]
  end

  defp package do
    [
      name: :k8s_client,
      maintainers: ["Cory O'Daniel"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/coryodaniel/k8s_conf"
      }
    ]
  end
end
