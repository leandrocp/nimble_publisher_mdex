if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.NimblePublisherMdex.Install do
    use Igniter.Mix.Task

    @shortdoc "Sets up a NimblePublisher blog with MDEx"

    @moduledoc """
    #{@shortdoc}

    Creates a blog module, sample post, and LiveView pages.

    ## Example

    ```sh
    mix igniter.install nimble_publisher_mdex
    ```
    """

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        group: :nimble_publisher_mdex,
        example: "mix nimble_publisher_mdex.install",
        only: nil,
        positional: [],
        composes: [],
        schema: [],
        defaults: [],
        aliases: [],
        required: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      app_module = Igniter.Project.Application.app_module(igniter)
      app_name = Igniter.Project.Application.app_name(igniter)
      web_module = Module.concat(app_module, "Web")

      blog_module = Module.concat(app_module, "Blog")
      post_module = Module.concat(blog_module, "Post")
      blog_live_module = Module.concat(web_module, "BlogLive")

      today = Date.utc_today()
      year = today.year |> to_string()
      month = today.month |> to_string() |> String.pad_leading(2, "0")
      day = today.day |> to_string() |> String.pad_leading(2, "0")

      igniter
      |> create_post_module(app_name, post_module)
      |> create_blog_module(app_name, blog_module, post_module)
      |> create_sample_post(year, month, day)
      |> create_blog_live(blog_live_module, blog_module, post_module)
    end

    defp create_post_module(igniter, _app_name, post_module) do
      post_path = Igniter.Project.Module.proper_location(igniter, post_module, :source_folder)

      contents = ~s'''
      defmodule #{inspect(post_module)} do
        @enforce_keys [:id, :title, :body, :description, :tags, :date]
        defstruct [:id, :title, :body, :description, :tags, :date]

        def build(filename, attrs, body) do
          [year, month_day_id] = filename |> Path.rootname() |> Path.split() |> Enum.take(-2)
          [month, day, id] = String.split(month_day_id, "-", parts: 3)
          date = Date.from_iso8601!("\#{year}-\#{month}-\#{day}")

          struct!(
            __MODULE__,
            [id: id, date: date, body: body] ++ Map.to_list(attrs)
          )
        end
      end
      '''

      Igniter.create_new_file(igniter, post_path, contents)
    end

    defp create_blog_module(igniter, app_name, blog_module, post_module) do
      blog_path = Igniter.Project.Module.proper_location(igniter, blog_module, :source_folder)

      contents = ~s'''
      defmodule #{inspect(blog_module)} do
        use NimblePublisher,
          build: #{inspect(post_module)},
          from: Application.app_dir(:#{app_name}, "priv/posts/**/*.md"),
          as: :posts,
          html_converter: NimblePublisherMDEx

        @posts Enum.sort_by(@posts, & &1.date, {:desc, Date})

        def all_posts, do: @posts

        def recent_posts(count \\\\ 5), do: Enum.take(all_posts(), count)

        def get_post_by_id!(id) do
          Enum.find(all_posts(), &(&1.id == id)) ||
            raise "post not found: \#{id}"
        end

        def get_posts_by_tag(tag) do
          Enum.filter(all_posts(), &(tag in &1.tags))
        end
      end
      '''

      Igniter.create_new_file(igniter, blog_path, contents)
    end

    defp create_sample_post(igniter, year, month, day) do
      path = "priv/posts/#{year}/#{month}-#{day}-hello-world.md"

      contents = ~S'''
      %{
        title: "Hello World",
        description: "My first blog post using NimblePublisher and MDEx.",
        tags: ["elixir"]
      }
      ---

      Welcome to your new blog powered by [NimblePublisher](https://hex.pm/packages/nimble_publisher)
      and [MDEx](https://hex.pm/packages/mdex).

      ## Code Highlighting

      MDEx uses [Lumis](https://hex.pm/packages/lumis) for syntax highlighting with automatic
      light/dark theme support:

      ```elixir
      defmodule Greeting do
        def hello(name) do
          "Hello, #{name}!"
        end
      end
      ```

      ## Markdown Features

      All GitHub Flavored Markdown features are enabled by default:

      | Feature | Supported |
      |---------|-----------|
      | Tables | Yes |
      | ~~Strikethrough~~ | Yes |
      | Autolinks | Yes |
      | Task lists | Yes |
      | Footnotes | Yes |

      - [x] Set up NimblePublisher
      - [x] Write first post
      - [ ] Deploy to production

      > This post was scaffolded by `mix nimble_publisher_mdex.install`.
      '''

      Igniter.create_new_file(igniter, path, contents)
    end

    defp create_blog_live(igniter, blog_live_module, blog_module, _post_module) do
      blog_live_path =
        Igniter.Project.Module.proper_location(igniter, blog_live_module, :source_folder)

      contents = ~s'''
      defmodule #{inspect(blog_live_module)} do
        use Phoenix.LiveView

        alias #{inspect(blog_module)}

        def mount(%{"id" => id}, _session, socket) do
          post = Blog.get_post_by_id!(id)
          {:ok, assign(socket, page_title: post.title, post: post)}
        end

        def mount(_params, _session, socket) do
          {:ok, assign(socket, page_title: "Blog", posts: Blog.all_posts())}
        end

        def render(%{post: _post} = assigns) do
          ~H"""
          <article>
            <header>
              <h1><%= @post.title %></h1>
              <time datetime={@post.date}><%= @post.date %></time>
              <div :for={tag <- @post.tags}><%= tag %></div>
            </header>
            <div><%%= raw(@post.body) %></div>
          </article>
          <p><.link navigate="/blog">Back to all posts</.link></p>
          """
        end

        def render(assigns) do
          ~H"""
          <h1>Blog</h1>
          <article :for={post <- @posts}>
            <h2><.link navigate={"/blog/\#{post.id}"}><%= post.title %></.link></h2>
            <time datetime={post.date}><%= post.date %></time>
            <p><%= post.description %></p>
          </article>
          """
        end
      end
      '''

      Igniter.create_new_file(igniter, blog_live_path, contents)
    end
  end
else
  defmodule Mix.Tasks.NimblePublisherMdex.Install do
    @shortdoc "Sets up a NimblePublisher blog with MDEx | Install `igniter` to use"
    @moduledoc @shortdoc

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'nimble_publisher_mdex.install' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
