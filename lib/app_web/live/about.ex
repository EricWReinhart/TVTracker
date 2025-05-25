defmodule AppWeb.AboutLive do
  use AppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main id="main-content" class="max-w-5xl mx-auto p-4 grid grid-cols-1 md:grid-cols-2 gap-6 dark:bg-gray-900">

      <!-- Image + Intro -->
      <section
        class="bg-white p-4 rounded-lg shadow-lg border-4 border-gray-300
               transition-colors duration-300 dark:bg-gray-700 dark:border-gray-500
               md:col-span-2"
      >
        <h1 class="text-3xl font-bold text-gray-800 dark:text-gray-200 text-center">
              {gettext("Hi there!")}
              <br>
              <br>
        </h1>
        <div class="flex flex-col md:flex-row items-center gap-6">
          <img
            src={~p"/images/giraffe.png"}
            alt="Eric Reinhart"
            class="rounded-lg w-48 h-auto flex-shrink-0"
          />

          <div class="space-y-4 text-gray-700 dark:text-gray-300 flex-1">
            <p class="text-lg">
              {gettext("I’m Eric, a Bucknell CS grad who loves movies and TV, especially behind-the-scenes content and fan theories! When I'm not watching something, I'm usually goofing around with friends, hiking, or gaming. For gaming, I gravitate towards Minecraft and Pokemon, which have been my favorites since I was a wee lad! I've sunk far more hours into them than I'd like to admit…")}
            </p>
            <p class="text-lg">
              {gettext("This site is home to my TV Tracker, and you’ll also find a Data Story, other projects, and some of my favorite things and quotes. Enjoy exploring, and stay hydrated!")}

            </p>
            <p class="text-lg">
              {gettext("P.S. Never challenge me to games with a lot of luck involved; I'm really lucky :)")}
            </p>
          </div>
        </div>
      </section>

      <!-- Course Assignments -->
      <section
        class="bg-white p-4 rounded-lg shadow-lg border-4 border-gray-300
               transition-colors duration-300 dark:bg-gray-700 dark:border-gray-500 md:col-span-2"
      >
        <h2 class="text-2xl font-bold  text-center text-gray-800 dark:text-gray-200">
          {gettext("Course Assignments")}
        </h2>
        <div class="mt-4 flex flex-wrap justify-center gap-4">
          <.link navigate={~p"/tvtracker"} class="px-4 py-2 text-base font-medium rounded-lg bg-blue-500 text-white hover:bg-blue-600 dark:bg-blue-600 dark:hover:bg-blue-600 transition">
            {gettext("TVTracker")}
          </.link>
          <.link href="https://ericwreinhart.github.io/data_visualizations/" class="px-4 py-2 text-base font-medium rounded-lg bg-blue-500 text-white hover:bg-blue-600 dark:bg-blue-600 dark:hover:bg-blue-600 transition">
            {gettext("Data Story")}
          </.link>

          <.link navigate={~p"/pokemon"} class="px-4 py-2 text-base font-medium rounded-lg bg-blue-500 text-white hover:bg-blue-600 dark:bg-blue-600 dark:hover:bg-blue-600 transition">
            {gettext("Pokemon")}
          </.link>
          <.link navigate={~p"/minesweeper"} class="px-4 py-2 text-base font-medium rounded-lg bg-blue-500 text-white hover:bg-blue-600 dark:bg-blue-600 dark:hover:bg-blue-600 transition">
            {gettext("Minesweeper")}
          </.link>
          <.link navigate={~p"/chat"} class="px-4 py-2 text-base font-medium rounded-lg bg-blue-500 text-white hover:bg-blue-600 dark:bg-blue-600 dark:hover:bg-blue-600 transition">
            {gettext("Chat")}
          </.link>
          <.link navigate={~p"/charts"} class="px-4 py-2 text-base font-medium rounded-lg bg-blue-500 text-white hover:bg-blue-600 dark:bg-blue-600 dark:hover:bg-blue-600 transition">
            {gettext("Charts")}
          </.link>
          <.link navigate={~p"/animations"} class="px-4 py-2 text-base font-medium rounded-lg bg-blue-500 text-white hover:bg-blue-600 dark:bg-blue-600 dark:hover:bg-blue-600 transition">
            {gettext("Animations")}
          </.link>
          <.link navigate={~p"/accessibility"} class="px-4 py-2 text-base font-medium rounded-lg bg-blue-500 text-white hover:bg-blue-600 dark:bg-blue-600 dark:hover:bg-blue-600 transition">
            {gettext("Accessibility")}
          </.link>
        </div>
      </section>

      <!-- Favorite Things -->
      <section
        class="bg-white p-4 rounded-lg shadow-lg border-4 border-gray-300
               transition-colors duration-300 dark:bg-gray-700 dark:border-gray-500"
      >
        <h2 class="text-2xl font-bold text-center text-gray-800 dark:text-gray-200">
          {gettext("Favorite Things")}
        </h2>
        <div class="mt-4 flex flex-wrap justify-center gap-2">
          <span class="bg-blue-500 text-white text-sm px-3 py-1 rounded-full dark:bg-blue-700">{gettext("Minecraft")}</span>
          <span class="bg-green-500 text-white text-sm px-3 py-1 rounded-full dark:bg-green-700">{gettext("Pokemon")}</span>
          <span class="bg-red-500 text-white text-sm px-3 py-1 rounded-full dark:bg-red-700">{gettext("Fall Guys")}</span>
          <span class="bg-yellow-500 text-white text-sm px-3 py-1 rounded-full dark:bg-yellow-700">{gettext("Arcane")}</span>
          <span class="bg-purple-500 text-white text-sm px-3 py-1 rounded-full dark:bg-purple-700">{gettext("Ted Lasso")}</span>
          <span class="bg-pink-500 text-white text-sm px-3 py-1 rounded-full dark:bg-pink-700">{gettext("Better Call Saul")}</span>
          <span class="bg-indigo-500 text-white text-sm px-3 py-1 rounded-full dark:bg-indigo-700">{gettext("Gravity Falls")}</span>
          <span class="bg-teal-500 text-white text-sm px-3 py-1 rounded-full dark:bg-teal-700">{gettext("Daredevil")}</span>
          <span class="bg-cyan-500 text-white text-sm px-3 py-1 rounded-full dark:bg-cyan-700">{gettext("Hell's Kitchen")}</span>
          <span class="bg-lime-500 text-white text-sm px-3 py-1 rounded-full dark:bg-lime-700">{gettext("The Walking Dead")}</span>
          <span class="bg-amber-500 text-white text-sm px-3 py-1 rounded-full dark:bg-amber-700">{gettext("Breaking Bad")}</span>
          <span class="bg-orange-500 text-white text-sm px-3 py-1 rounded-full dark:bg-orange-700">{gettext("Spider-Man")}</span>
          <span class="bg-violet-500 text-white text-sm px-3 py-1 rounded-full dark:bg-violet-700">{gettext("Music")}</span>
          <span class="bg-fuchsia-500 text-white text-sm px-3 py-1 rounded-full dark:bg-fuchsia-700">{gettext("Reading")}</span>
          <span class="bg-sky-500 text-white text-sm px-3 py-1 rounded-full dark:bg-sky-700">{gettext("Running")}</span>
          <span class="bg-teal-400 text-white text-sm px-3 py-1 rounded-full dark:bg-teal-600">{gettext("Hiking")}</span>
          <span class="bg-purple-500 text-white text-sm px-3 py-1 rounded-full dark:bg-purple-700">{gettext("Friends")}</span>
          <span class="bg-orange-600 text-white text-sm px-3 py-1 rounded-full dark:bg-orange-800">{gettext("Family")}</span>
          <span class="bg-pink-400 text-white text-sm px-3 py-1 rounded-full dark:bg-pink-600">{gettext("Technoblade")}</span>
        </div>
      </section>

      <!-- Favorite Quotes -->
      <section
        class="bg-white p-4 rounded-lg shadow-lg border-4 border-gray-300
               transition-colors duration-300 dark:bg-gray-700 dark:border-gray-500"
      >
        <h2 class="text-2xl font-bold  text-center text-gray-800 dark:text-gray-200">
          {gettext("Favorite Quotes")}
        </h2>
        <p class="mt-4 text-center text-gray-700 dark:text-gray-300">
          “{gettext("Be curious, not judgmental")}” – Ted Lasso
        </p>
        <p class="mt-4 text-center text-gray-700 dark:text-gray-300">
          “{gettext("I wish there was a way to know you're in the good old days before you've actually left them")}” – Andy Bernard
        </p>
        <p class="mt-4 text-center text-gray-700 dark:text-gray-300">
          “{gettext("That's my secret, Captain. I'm always stressed")}” – Technoblade
        </p>
      </section>
    </main>
    """
  end


end
