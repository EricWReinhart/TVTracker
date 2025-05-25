defmodule AppWeb.AccessibilityLive do
  use AppWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <article class="mt-4 format dark:format-invert max-w-full">
      {@page_content}
    </article>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    # get markdown content from file
    case File.read(Path.join([:code.priv_dir(:app), "accessibility.md"])) do
      {:ok, content} ->
        content =
          content
          |> MDEx.to_html!(render: [unsafe_: true], features: [sanitize: false])
          |> raw()

        {:ok, assign(socket, :page_content, content)}

      {:error, _} ->
        {:ok, socket
        |> put_flash(:error, "Page content could not be loaded.")
        |> assign(:page_content, nil)}
    end
  end
end
