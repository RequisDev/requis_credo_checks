defmodule RequisCredoChecks.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :requis_credo_checks,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      dialyzer: [
        plt_add_apps: [:ex_unit, :mix, :credo],
        list_unused_filters: true,
        plt_local_path: "dialyzer",
        plt_core_path: "dialyzer",
        flags: [:unmatched_returns]
      ],
      preferred_cli_env: [
        credo: :test,
        dialyzer: :test,
        check: :test,
        doctor: :test,
        ex_doc: :test,
        coveralls: :test,
        "coveralls.json": :test,
        "coveralls.html": :test
      ],

      # Hex
      description: "Custom Credo checks used by the Requis Backend Elixir team",
      package: package(),

      # Docs
      name: "RequisCredoChecks",
      docs: docs()
    ]
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
      {:absinthe, "~> 1.0"},

      {:credo, "~> 1.4", runtime: false},
      {:blitz_credo_checks, "~> 0.1", runtime: false, optional: true},
      {:ex_check, "~> 0.12", only: :test, runtime: false},
      {:dialyxir, "~> 1.0", only: :test, runtime: false},
      {:excoveralls, "~> 0.13", only: :test, runtime: false},
      {:ex_doc, "~> 0.26", only: [:dev, :test], runtime: false},
      {:doctor, "~> 0.21.0", only: :test}
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      main: "README.md",
      canonical: "http://hexdocs.pm/requis_credo_checks",
      source_url: "https://github.com/RequisDev/requis_credo_checks",
      logo: "requis.png",
      filter_prefix: "RequisCredoChecks",
      extras: [
        "README.md": [filename: "README.md"],
        "CHANGELOG.md": [filename: "CHANGELOG.md"]
      ]
    ]
  end

  defp package do
    [
      maintainers: ["Kurt Hogarth"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/requisdev/requis_credo_checks"},
      files: [
        "lib/",
        "mix.exs",
        "README.md",
        "CHANGELOG.md"
      ]
    ]
  end
end
