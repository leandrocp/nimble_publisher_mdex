defmodule NimblePublisherMDEx do
  @external_resource "README.md"

  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC -->")
             |> Enum.fetch!(1)

  @markdown_extensions [".md", ".markdown", ".livemd"]

  @default_opts [
    syntax_highlight: [
      formatter:
        {:html_multi_themes,
         themes: [light: "github_light", dark: "github_dark"], default_theme: "light-dark()"}
    ]
  ]

  @doc """
  Converts a Markdown file to HTML using [MDEx](https://hex.pm/packages/mdex).

  Implements the `html_converter` interface expected by
  [NimblePublisher](https://hex.pm/packages/nimble_publisher).

  Uses [MDExGFM](https://hex.pm/packages/mdex_gfm) for GitHub Flavored Markdown
  (tables, strikethrough, autolinks, task lists, footnotes, alerts).

  See [more plugins](https://hex.pm/packages?search=mdex_&sort=recent_downloads) for
  additional features like Mermaid diagrams, KaTeX math, and more.

  ## Arguments

    * `filepath` - the path to the source file
    * `body` - the raw Markdown content (after frontmatter has been extracted)
    * `attrs` - the parsed frontmatter attributes (unused)
    * `opts` - options from `use NimblePublisher`

  ## Configuration

  MDEx options are resolved in the following order (later values win):

    1. Built-in defaults (light/dark syntax highlighting)
    2. Application config: `config :nimble_publisher_mdex, mdex_opts: [...]`
    3. `:mdex_opts` key passed through the NimblePublisher opts

  ## Examples

      # Minimal — just set the converter
      use NimblePublisher,
        build: __MODULE__,
        from: "priv/posts/**/*.md",
        as: :posts,
        html_converter: NimblePublisherMDEx

      # Override via application config
      config :nimble_publisher_mdex,
        mdex_opts: [
          syntax_highlight: [formatter: {:html_inline, theme: "dracula"}]
        ]

      # Override via NimblePublisher opts
      use NimblePublisher,
        build: __MODULE__,
        from: "priv/posts/**/*.md",
        as: :posts,
        html_converter: NimblePublisherMDEx,
        mdex_opts: [syntax_highlight: nil]

  """
  @spec convert(Path.t(), String.t(), map(), keyword()) :: String.t()
  def convert(filepath, body, _attrs, opts) do
    ext = filepath |> Path.extname() |> String.downcase()

    if ext in @markdown_extensions do
      mdex_opts = build_opts(opts)

      MDEx.new(markdown: body, syntax_highlight: mdex_opts[:syntax_highlight])
      |> MDExGFM.attach()
      |> MDEx.to_html!()
    else
      body
    end
  end

  defp build_opts(opts) do
    app_opts = Application.get_env(:nimble_publisher_mdex, :mdex_opts, [])
    passthrough_opts = Keyword.get(opts, :mdex_opts, [])

    @default_opts
    |> deep_merge(app_opts)
    |> deep_merge(passthrough_opts)
  end

  defp deep_merge(base, override) do
    Keyword.merge(base, override, fn
      _key, base_val, override_val when is_list(base_val) and is_list(override_val) ->
        if Keyword.keyword?(base_val) and Keyword.keyword?(override_val) do
          deep_merge(base_val, override_val)
        else
          override_val
        end

      _key, _base_val, override_val ->
        override_val
    end)
  end
end
