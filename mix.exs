defmodule Framex.MixProject do
  use Mix.Project

  def project do
    [
      app: :framex,
      version: "0.1.0",
      elixir: "~> 1.18",
      description: "Lazy, read-only queries over a FrameNet JSON artifact",
      package: package(),
      docs: docs(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Framex.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.38", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "TERMINOLOGY.md"]
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/collective-mind/framex"},
      files: [
        ".formatter.exs",
        "LICENSE",
        "README.md",
        "TERMINOLOGY.md",
        "lib",
        "mix.exs",
        "priv/corpora/demo_en_17"
      ]
    ]
  end
end
