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
        example: "mix nimble_publisher_mdex.install"
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      app_module = Igniter.Project.Module.module_name_prefix(igniter)
      app_name = Igniter.Project.Application.app_name(igniter)
      web_module = Igniter.Libs.Phoenix.web_module(igniter)

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
      |> add_blog_routes(web_module)
      |> create_blog_live(blog_live_module, blog_module, post_module)
    end

    defp add_blog_routes(igniter, web_module) do
      {igniter, router} = Igniter.Libs.Phoenix.select_router(igniter)

      if is_nil(router) || blog_routes_installed?(igniter, router) do
        igniter
      else
        Igniter.Libs.Phoenix.append_to_scope(
          igniter,
          "/",
          """
          live "/blog", BlogLive
          live "/blog/:id", BlogLive
          """,
          router: router,
          arg2: web_module,
          with_pipelines: [:browser]
        )
      end
    end

    defp blog_routes_installed?(igniter, router) do
      {_igniter, _source, zipper} = Igniter.Project.Module.find_module!(igniter, router)

      live_route_exists?(zipper, "/blog") && live_route_exists?(zipper, "/blog/:id")
    end

    defp live_route_exists?(zipper, path) do
      case Igniter.Code.Function.move_to_function_call_in_current_scope(
             zipper,
             :live,
             [2, 3, 4],
             &Igniter.Code.Function.argument_equals?(&1, 0, path)
           ) do
        {:ok, _zipper} -> true
        :error -> false
      end
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

      Igniter.create_new_file(igniter, post_path, contents, on_exists: :skip)
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

      Igniter.create_new_file(igniter, blog_path, contents, on_exists: :skip)
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
      [light/dark theme](https://hexdocs.pm/mdex/light_dark_theme.html) support, and [code block decorators](https://hexdocs.pm/mdex/code_block_decorators-1.html) work out of the box:

      ```elixir
      defmodule Greeting do
        def hello(name) do
          "Hello, #{name}!"
        end
      end
      ```

      ## Phoenix HEEx

      You can also use Phoenix HEEx components directly in Markdown:

      <Phoenix.Component.link
        href="https://hexdocs.pm/mdex/phoenix_live_view_heex.html"
      >
        Read the MDEx Phoenix HEEx guide
      </Phoenix.Component.link>

      > This post was scaffolded by `mix nimble_publisher_mdex.install`
      '''

      Igniter.create_new_file(igniter, path, contents, on_exists: :skip)
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
          <main class="mx-auto max-w-3xl px-4 py-16 sm:px-6 lg:px-8">
            <.link
              navigate="/blog"
              class="inline-flex items-center gap-2 text-sm font-semibold text-base-content/70 transition hover:text-base-content"
            >
              <span aria-hidden="true">&larr;</span>
              Back to all posts
            </.link>

            <article class="mt-8 overflow-hidden rounded-[var(--radius-box)] border border-base-300 bg-base-100 shadow-sm">
              <header class="border-b border-base-300 bg-base-200 px-6 py-8 sm:px-10">
                <div class="flex flex-wrap items-center gap-3 text-sm">
                  <time datetime={@post.date} class="font-medium text-base-content/60"><%= @post.date %></time>
                  <span
                    :for={tag <- @post.tags}
                    class="badge badge-outline border-secondary/30 bg-secondary/10 px-3 py-3 text-[0.7rem] font-semibold uppercase tracking-wide text-secondary"
                  >
                    <%= tag %>
                  </span>
                </div>

                <h1 class="mt-4 text-4xl font-semibold tracking-tight text-base-content sm:text-5xl">
                  <%= @post.title %>
                </h1>
                <p class="mt-4 max-w-2xl text-base leading-7 text-base-content/70"><%= @post.description %></p>
              </header>

              <div class="px-6 py-8 sm:px-10">
                <div class="max-w-none text-base leading-8 text-base-content/80 [&_a]:font-semibold [&_a]:text-primary [&_a]:underline [&_a]:decoration-primary/30 [&_blockquote]:border-l-4 [&_blockquote]:border-primary/30 [&_blockquote]:pl-4 [&_blockquote]:italic [&_code]:rounded [&_code]:bg-base-200 [&_code]:px-1.5 [&_code]:py-0.5 [&_code]:font-mono [&_code]:text-sm [&_h2]:mt-10 [&_h2]:text-2xl [&_h2]:font-semibold [&_h2]:tracking-tight [&_h2]:text-base-content [&_li]:my-2 [&_ol]:my-6 [&_ol]:list-decimal [&_ol]:pl-6 [&_p]:my-6 [&_pre]:my-6 [&_pre]:overflow-x-auto [&_pre]:rounded-[calc(var(--radius-box)*1.5)] [&_pre]:p-4 [&_pre]:text-sm [&_pre]:leading-6 [&_pre_code]:bg-transparent [&_pre_code]:p-0 [&_table]:my-8 [&_table]:w-full [&_table]:text-left [&_td]:border-b [&_td]:border-base-300 [&_td]:py-3 [&_th]:border-b [&_th]:border-base-300 [&_th]:py-3 [&_th]:font-semibold [&_th]:text-base-content [&_ul]:my-6 [&_ul]:list-disc [&_ul]:pl-6">
                  {Phoenix.HTML.raw(@post.body)}
                </div>
              </div>
            </article>
          </main>
          """
        end

        def render(assigns) do
          ~H"""
          <main class="mx-auto max-w-5xl px-4 py-16 sm:px-6 lg:px-8">
            <section class="max-w-2xl">
              <p class="text-sm font-semibold uppercase tracking-[0.2em] text-secondary">NimblePublisher blog</p>
              <h1 class="mt-4 text-4xl font-semibold tracking-tight text-base-content sm:text-5xl">Latest posts</h1>
              <p class="mt-4 text-base leading-7 text-base-content/70">
                Browse your published posts and click through to read the full article.
              </p>
            </section>

            <section class="mt-12 space-y-6">
              <article
                :for={post <- @posts}
                class="group rounded-[var(--radius-box)] border border-base-300 bg-base-100 p-6 shadow-sm transition duration-200 hover:-translate-y-1 hover:border-primary/30 hover:shadow-lg sm:p-8"
              >
                <div class="flex flex-col gap-6 sm:flex-row sm:items-start sm:justify-between">
                  <div class="max-w-2xl">
                    <div class="flex flex-wrap gap-2">
                      <span
                        :for={tag <- post.tags}
                        class="badge badge-outline border-base-300 bg-base-200 px-3 py-3 text-[0.7rem] font-semibold uppercase tracking-wide text-base-content/70"
                      >
                        <%= tag %>
                      </span>
                    </div>

                    <h2 class="mt-4 text-2xl font-semibold tracking-tight text-base-content sm:text-3xl">
                      <.link navigate={"/blog/\#{post.id}"} class="transition group-hover:text-primary">
                        <%= post.title %>
                      </.link>
                    </h2>

                    <p class="mt-3 text-base leading-7 text-base-content/70"><%= post.description %></p>

                    <.link
                      navigate={"/blog/\#{post.id}"}
                      class="mt-6 inline-flex items-center gap-2 text-sm font-semibold text-primary transition hover:opacity-80"
                    >
                      Read post
                      <span aria-hidden="true">&rarr;</span>
                    </.link>
                  </div>

                  <time
                    datetime={post.date}
                    class="badge badge-ghost shrink-0 px-4 py-3 text-sm font-medium text-base-content/60"
                  >
                    <%= post.date %>
                  </time>
                </div>
              </article>
            </section>
          </main>
          """
        end
      end
      '''

      Igniter.create_new_file(igniter, blog_live_path, contents, on_exists: :skip)
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
