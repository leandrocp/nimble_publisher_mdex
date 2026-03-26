# NimblePublisherMDEx

[![Hex.pm](https://img.shields.io/hexpm/v/nimble_publisher_mdex)](https://hex.pm/packages/nimble_publisher_mdex)
[![Hexdocs](https://img.shields.io/badge/hexdocs-latest-blue.svg)](https://hexdocs.pm/nimble_publisher_mdex)

<!-- MDOC -->

[NimblePublisher](https://hex.pm/packages/nimble_publisher) adapter for [MDEx](https://hex.pm/packages/mdex) and [Lumis](https://hex.pm/packages/lumis), with support for both static Markdown rendering and Phoenix LiveView rendering.

- Syntax highlighting for 110+ languages powered by [Tree-sitter](https://tree-sitter.github.io/tree-sitter/) via [Lumis](https://lumis.sh)
- 120+ color themes from the Neovim ecosystem
- Automatic light/dark mode
- Static Markdown to HTML rendering
- [Phoenix HEEx](https://hexdocs.pm/mdex/phoenix_live_view_heex.html) support when `:phoenix_live_view` is installed
- [Code block decorators](https://hexdocs.pm/mdex/code_block_decorators-1.html)
- GitHub Flavored Markdown via [MDExGFM](https://hex.pm/packages/mdex_gfm)
- Extensible with [more plugins](https://hex.pm/packages?search=mdex_&sort=recent_downloads) — Mermaid diagrams, KaTeX math, Video, and more.

## Getting Started

Pick the path that fits your situation:

- **[New project](#new-project)** — start from scratch with Phoenix + blog
- **[Add a blog to an existing Phoenix project](#add-a-blog-to-an-existing-phoenix-project)** — scaffold a blog into your app
- **[Switch from Earmark to MDEx](#switch-from-earmark-to-mdex)** — already using NimblePublisher

### New project

Install the [Igniter](https://hex.pm/packages/igniter) archive if you haven't already:

```sh
mix archive.install hex igniter_new
```

Create a new Phoenix project with a blog already set up:

```sh
mix igniter.new my_blog --install nimble_publisher_mdex --with phx.new --with-args="--no-ecto"
```

This will generate a Phoenix app, add the dependency, and scaffold a blog module, sample post, and LiveView.

### Add a blog to an existing Phoenix project

Run the installer to scaffold everything:

```sh
mix igniter.install nimble_publisher_mdex
```

This will add the dependency and generate a blog module, sample post, and LiveView. Then add the color-scheme meta tag to your root layout:

```html
<meta name="color-scheme" content="light dark">
```

### Switch from Earmark to MDEx

Add the dependency:

```elixir
def deps do
  [
    {:nimble_publisher_mdex, "~> 0.1"}
  ]
end
```

Set the converter in your blog module:

```elixir
use NimblePublisher,
  build: __MODULE__,
  from: "priv/posts/**/*.md",
  as: :posts,
  html_converter: NimblePublisherMDEx
```

Remove the `:highlighters` option and any `makeup_*` dependencies — MDEx handles syntax highlighting out of the box.

Add the color-scheme meta tag to your root layout:

```html
<meta name="color-scheme" content="light dark">
```

## Configuration

Pass `:mdex_opts` to customize [MDEx Options](https://hexdocs.pm/mdex/MDEx.Document.html#t:options/0)

Built-in defaults include:

```elixir
[
  plugins: [MDExGFM],
  extension: [phoenix_heex: true],
  render: [
    unsafe: true,
    github_pre_lang: true,
    full_info_string: true
  ],
  syntax_highlight: [
    formatter:
      {:html_multi_themes,
       themes: [light: "github_light", dark: "github_dark"], default_theme: "light-dark()"}
  ]
]
```

Static Markdown rendering works out of the box. If you also want MDEx to render Phoenix HEEx through LiveView, install the optional `:phoenix_live_view` dependency.

You can change the default options in the app config:

```elixir
# config/config.exs
config :nimble_publisher_mdex,
  mdex_opts: [
    syntax_highlight: [
      formatter: {:html_inline, theme: "dracula"}
    ]
  ]
```

Or pass options directly through NimblePublisher:

```elixir
use NimblePublisher,
  build: __MODULE__,
  from: "priv/posts/**/*.md",
  as: :posts,
  html_converter: NimblePublisherMDEx,
  mdex_opts: [syntax_highlight: nil]
```

### Themes

Browse all available themes at [lumis.sh](https://lumis.sh). Some popular choices:

| Theme | Style |
|-------|-------|
| `github_light` / `github_dark` | GitHub (default) |
| `catppuccin_latte` / `catppuccin_mocha` | Catppuccin |
| `tokyonight_day` / `tokyonight_storm` | Tokyo Night |
| `onedark` | One Dark |
| `dracula` | Dracula |

<!-- MDOC -->

## License

MIT License. See [LICENSE](LICENSE) for details.
