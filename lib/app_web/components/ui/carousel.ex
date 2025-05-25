defmodule AppWeb.Components.UI.Carousel do
  use Phoenix.Component

  @moduledoc """
  Renders a Flowbite carousel. Each entry should be a map with:
    * `:src` - image URL
    * `:alt` - alt text

  ## Assigns
    * `:id` - unique DOM id (default: "default-carousel")
    * `:entries` - list of `%{src: String.t(), alt: String.t()}`
  """

  attr :id, :string, default: "default-carousel", doc: "DOM id and data-carousel target"
  attr :entries, :list, required: true, doc: "List of slide entries"

  def carousel(assigns) do
    ~H"""
    <div id={@id} class="relative w-full" data-carousel="slide">
      <!-- Carousel wrapper -->
      <div class="relative h-56 overflow-hidden rounded-lg md:h-96">
        <%= for entry <- @entries do %>
          <div class="hidden duration-700 ease-in-out" data-carousel-item>
            <img src={entry.src}
                 class="absolute block w-full -translate-x-1/2 -translate-y-1/2 top-1/2 left-1/2"
                 alt={entry.alt} />
          </div>
        <% end %>
      </div>

      <!-- Slider indicators -->
      <div class="absolute z-30 flex -translate-x-1/2 bottom-5 left-1/2 space-x-3 rtl:space-x-reverse">
        <%= for {_entry, idx} <- Enum.with_index(@entries) do %>
          <button type="button"
                  class="w-3 h-3 rounded-full"
                  aria-current={if idx == 0, do: "true", else: "false"}
                  aria-label={"Slide " <> Integer.to_string(idx + 1)}
                  data-carousel-slide-to={idx}>
          </button>
        <% end %>
      </div>

      <!-- Slider controls -->
      <button type="button" class="absolute top-0 start-0 z-30 flex items-center justify-center h-full px-4 cursor-pointer group focus:outline-none" data-carousel-prev>
        <span class="inline-flex items-center justify-center w-10 h-10 rounded-full bg-white/30 dark:bg-gray-800/30 group-hover:bg-white/50 dark:group-hover:bg-gray-800/60 group-focus:ring-4 group-focus:ring-white dark:group-focus:ring-gray-800/70 group-focus:outline-none">
          <svg class="w-4 h-4 text-white dark:text-gray-800 rtl:rotate-180" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 6 10">
            <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 1 1 5l4 4"/>
          </svg>
          <span class="sr-only">Previous</span>
        </span>
      </button>
      <button type="button" class="absolute top-0 end-0 z-30 flex items-center justify-center h-full px-4 cursor-pointer group focus:outline-none" data-carousel-next>
        <span class="inline-flex items-center justify-center w-10 h-10 rounded-full bg-white/30 dark:bg-gray-800/30 group-hover:bg-white/50 dark:group-hover:bg-gray-800/60 group-focus:ring-4 group-focus:ring-white dark:group-focus:ring-gray-800/70 group-focus:outline-none">
          <svg class="w-4 h-4 text-white dark:text-gray-800 rtl:rotate-180" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 6 10">
            <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m1 9 4-4-4-4"/>
          </svg>
          <span class="sr-only">Next</span>
        </span>
      </button>
    </div>
    """
  end
end
