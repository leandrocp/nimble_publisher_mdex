defmodule Mix.Tasks.NimblePublisherMdex.InstallTest do
  use ExUnit.Case
  import Igniter.Test

  defp get_content(igniter, path) do
    igniter.rewrite
    |> Rewrite.source!(path)
    |> Rewrite.Source.get(:content)
  end

  defp sample_post_path do
    today = Date.utc_today()
    year = today.year |> to_string()
    month = today.month |> to_string() |> String.pad_leading(2, "0")
    day = today.day |> to_string() |> String.pad_leading(2, "0")
    "priv/posts/#{year}/#{month}-#{day}-hello-world.md"
  end

  defp blog_path, do: "lib/test/blog.ex"
  defp post_path, do: "lib/test/blog/post.ex"
  defp live_path, do: "lib/test_web/blog_live.ex"

  test "creates all expected files" do
    test_project()
    |> Igniter.compose_task("nimble_publisher_mdex.install", [])
    |> assert_creates(post_path())
    |> assert_creates(blog_path())
    |> assert_creates(live_path())
    |> assert_creates(sample_post_path())
  end

  test "post module has struct and build/3" do
    igniter =
      test_project()
      |> Igniter.compose_task("nimble_publisher_mdex.install", [])
      |> apply_igniter!()

    post = get_content(igniter, post_path())

    assert post =~ "@enforce_keys [:id, :title, :body, :description, :tags, :date]"
    assert post =~ "defstruct [:id, :title, :body, :description, :tags, :date]"
    assert post =~ "def build(filename, attrs, body) do"
    assert post =~ "Date.from_iso8601!"
  end

  test "blog module uses NimblePublisher with MDEx converter" do
    igniter =
      test_project()
      |> Igniter.compose_task("nimble_publisher_mdex.install", [])
      |> apply_igniter!()

    blog = get_content(igniter, blog_path())

    assert blog =~ "use NimblePublisher"
    assert blog =~ "html_converter: NimblePublisherMDEx"
    assert blog =~ ~s|Application.app_dir(:test, "priv/posts/**/*.md")|
    assert blog =~ "def all_posts"
    assert blog =~ "def recent_posts"
    assert blog =~ "def get_post_by_id!"
    assert blog =~ "def get_posts_by_tag"
  end

  test "blog live view uses Phoenix.LiveView" do
    igniter =
      test_project()
      |> Igniter.compose_task("nimble_publisher_mdex.install", [])
      |> apply_igniter!()

    live = get_content(igniter, live_path())

    assert live =~ "use Phoenix.LiveView"
    assert live =~ "Blog.get_post_by_id!"
    assert live =~ "Blog.all_posts()"
    assert live =~ ~s|def mount(%{"id" => id}|
    assert live =~ "def render(%{post: _post} = assigns)"
    assert live =~ "def render(assigns)"
  end

  test "sample post has frontmatter and markdown content" do
    igniter =
      test_project()
      |> Igniter.compose_task("nimble_publisher_mdex.install", [])
      |> apply_igniter!()

    post = get_content(igniter, sample_post_path())

    assert post =~ ~s|title: "Hello World"|
    assert post =~ ~s|description:|
    assert post =~ ~s|tags: ["elixir"]|
    assert post =~ "---"
    assert post =~ "```elixir"
  end

  test "does not modify mix.exs" do
    test_project()
    |> Igniter.compose_task("nimble_publisher_mdex.install", [])
    |> assert_unchanged("mix.exs")
  end

  test "is idempotent" do
    test_project()
    |> Igniter.compose_task("nimble_publisher_mdex.install", [])
    |> apply_igniter!()
    |> Igniter.compose_task("nimble_publisher_mdex.install", [])
    |> assert_unchanged()
  end

  test "uses app name in NimblePublisher config" do
    igniter =
      test_project(app_name: :my_blog)
      |> Igniter.compose_task("nimble_publisher_mdex.install", [])
      |> apply_igniter!()

    blog = get_content(igniter, "lib/my_blog/blog.ex")
    assert blog =~ ~s|Application.app_dir(:my_blog, "priv/posts/**/*.md")|
    assert blog =~ "html_converter: NimblePublisherMDEx"

    post = get_content(igniter, "lib/my_blog/blog/post.ex")
    assert post =~ "def build(filename, attrs, body) do"

    live = get_content(igniter, "lib/my_blog_web/blog_live.ex")
    assert live =~ "use Phoenix.LiveView"
    assert live =~ "Blog.all_posts()"
  end
end
