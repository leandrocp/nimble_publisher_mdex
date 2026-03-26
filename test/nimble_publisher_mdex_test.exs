defmodule NimblePublisherMDExTest do
  use ExUnit.Case

  describe "deep_merge/2" do
    test "recursively merges nested keyword lists" do
      base = [
        extension: [table: true, phoenix_heex: true],
        render: [unsafe: true, full_info_string: true],
        syntax_highlight: [formatter: {:html_inline, theme: "github_dark"}]
      ]

      override = [
        extension: [autolink: true],
        render: [unsafe: false],
        syntax_highlight: [formatter: {:html_inline, theme: "onedark"}]
      ]

      merged = NimblePublisherMDEx.deep_merge(base, override)

      assert Keyword.get(merged, :extension) == [
               table: true,
               phoenix_heex: true,
               autolink: true
             ]

      assert Keyword.get(merged, :render)[:unsafe] == false
      assert Keyword.get(merged, :render)[:full_info_string] == true

      assert Keyword.get(merged, :syntax_highlight)[:formatter] ==
               {:html_inline, theme: "onedark"}
    end

    test "replaces non-keyword lists instead of merging them" do
      base = [plugins: [MDExGFM], tags: ["elixir", "phoenix"]]
      override = [plugins: [MDExGFM, MyPlugin], tags: ["mdex"]]

      assert NimblePublisherMDEx.deep_merge(base, override) == [
               plugins: [MDExGFM, MyPlugin],
               tags: ["mdex"]
             ]
    end

    test "overrides scalar values" do
      assert NimblePublisherMDEx.deep_merge([unsafe: true], unsafe: false) == [unsafe: false]
    end
  end

  describe "convert/4" do
    test "converts markdown to HTML" do
      html = NimblePublisherMDEx.convert("post.md", "# Hello", %{}, [])
      assert html =~ "<h1>Hello</h1>"
    end

    test "converts paragraphs with inline formatting" do
      body = """
      # Title

      Some **bold** and *italic* text.
      """

      html = NimblePublisherMDEx.convert("post.md", body, %{}, [])
      assert html =~ "<h1>Title</h1>"
      assert html =~ "<strong>bold</strong>"
      assert html =~ "<em>italic</em>"
    end

    test "applies syntax highlighting with light/dark themes" do
      body = """
      ```elixir
      def hello, do: :world
      ```
      """

      html = NimblePublisherMDEx.convert("post.md", body, %{}, [])
      assert html =~ "light-dark("
      assert html =~ "hello"
    end

    test "enables code block decorators by default" do
      body = """
      ```elixir pre_class="featured-snippet" include_highlights
      def hello do
        :world
      end
      ```
      """

      html = NimblePublisherMDEx.convert("post.md", body, %{}, [])

      assert html =~ "featured-snippet"
    end

    test "enables phoenix heex components by default" do
      body =
        ~s(<Phoenix.Component.link href="https://hex.pm/packages/mdex">Read the docs</Phoenix.Component.link>)

      html = NimblePublisherMDEx.convert("post.md", body, %{}, [])

      assert html =~ ~s(<a href="https://hex.pm/packages/mdex")
      assert html =~ "Read the docs"
    end

    test "handles .markdown extension" do
      html = NimblePublisherMDEx.convert("post.markdown", "# Hello", %{}, [])
      assert html =~ "<h1>Hello</h1>"
    end

    test "handles .livemd extension" do
      html = NimblePublisherMDEx.convert("post.livemd", "# Hello", %{}, [])
      assert html =~ "<h1>Hello</h1>"
    end

    test "handles .heex extension" do
      html =
        NimblePublisherMDEx.convert(
          "post.heex",
          ~s(<Phoenix.Component.link href="https://hex.pm/packages/mdex">Read the docs</Phoenix.Component.link>),
          %{},
          []
        )

      assert html =~ ~s(<a href="https://hex.pm/packages/mdex")
      assert html =~ "Read the docs"
    end

    test "returns body unchanged for unsupported extensions" do
      body = "<p>Already HTML</p>"
      assert NimblePublisherMDEx.convert("post.html", body, %{}, []) == body
    end

    test "extension check is case-insensitive" do
      html = NimblePublisherMDEx.convert("post.MD", "# Hello", %{}, [])
      assert html =~ "<h1>Hello</h1>"
    end

    test "enables table extension by default" do
      body = """
      | A | B |
      |---|---|
      | 1 | 2 |
      """

      html = NimblePublisherMDEx.convert("post.md", body, %{}, [])
      assert html =~ "<table>"
    end

    test "enables strikethrough extension by default" do
      html = NimblePublisherMDEx.convert("post.md", "~~deleted~~", %{}, [])
      assert html =~ "<del>deleted</del>"
    end

    test "enables autolink extension by default" do
      html = NimblePublisherMDEx.convert("post.md", "Visit https://example.com today", %{}, [])
      assert html =~ ~s(<a href="https://example.com")
    end

    test "allows raw HTML in markdown" do
      body = ~s(<div class="custom">content</div>)
      html = NimblePublisherMDEx.convert("post.md", body, %{}, [])
      assert html =~ ~s(<div class="custom">content</div>)
    end

    test "accepts mdex_opts via NimblePublisher opts" do
      body = """
      ```elixir
      def hello, do: :world
      ```
      """

      html =
        NimblePublisherMDEx.convert("post.md", body, %{}, mdex_opts: [syntax_highlight: nil])

      refute html =~ "light-dark("
    end

    test "mdex_opts override syntax highlight defaults" do
      body = """
      ```elixir
      def hello, do: :world
      ```
      """

      html =
        NimblePublisherMDEx.convert("post.md", body, %{},
          mdex_opts: [
            syntax_highlight: [formatter: {:html_inline, theme: "onedark"}]
          ]
        )

      # Single theme produces plain style= without light-dark()
      refute html =~ "light-dark("
      assert html =~ "style="
    end

    test "ignores attrs argument" do
      attrs = %{title: "Test", tags: ["elixir"]}
      html = NimblePublisherMDEx.convert("post.md", "# Hello", attrs, [])
      assert html =~ "<h1>Hello</h1>"
    end

    test "ignores NimblePublisher highlighters option" do
      html =
        NimblePublisherMDEx.convert("post.md", "# Hello", %{}, highlighters: [:makeup_elixir])

      assert html =~ "<h1>Hello</h1>"
    end
  end
end
