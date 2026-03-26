defmodule NimblePublisherMDEx.MixProject do
  use Mix.Project

  @source_url "https://github.com/leandrocp/nimble_publisher_mdex"
  @version "0.1.1"

  def project do
    [
      app: :nimble_publisher_mdex,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      package: package(),
      docs: docs(),
      deps: deps(),
      aliases: aliases(),
      name: "NimblePublisherMDEx",
      source_url: @source_url,
      description: "NimblePublisher adapter for MDEx and Lumis"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def cli do
    [
      preferred_envs: [
        docs: :docs,
        "hex.publish": :docs,
        quality: :test
      ]
    ]
  end

  defp package do
    [
      maintainers: ["Leandro Pereira"],
      licenses: ["MIT"],
      links: %{
        Changelog: "https://hexdocs.pm/nimble_publisher_mdex/changelog.html",
        GitHub: @source_url
      },
      files: ~w[
        mix.exs
        lib
        README.md
        LICENSE
        CHANGELOG.md
      ]
    ]
  end

  defp docs do
    [
      main: "NimblePublisherMDEx",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: ["CHANGELOG.md"],
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end

  defp deps do
    [
      mdex_dep(),
      {:mdex_gfm, ">= 0.2.0"},
      {:nimble_publisher, ">= 1.0.0"},
      {:phoenix_live_view, "~> 1.0", optional: true},
      {:igniter, "~> 0.5", optional: true},
      {:ex_doc, ">= 0.0.0", only: :docs},
      {:makeup_elixir, "~> 1.0", only: :docs},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp mdex_dep do
    if path = System.get_env("MDEX_PATH") do
      {:mdex, path: path}
    else
      {:mdex, ">= 0.9.0"}
    end
  end

  defp aliases do
    [
      setup: ["deps.get", "compile"],
      quality: ["format", "test"]
    ]
  end
end
