# Accessibility
### Accessibility Concern 1: Screen-Reader Text

#### Description:
Screen-reader-only text is visually hidden, but is readable by screen readers. It's useful for providing descriptive labels of the content for visually impaired users.

#### Example Code:
```elixir
defmodule MyAppWeb.Components do
  use Phoenix.Component

  def sr_text(assigns) do
    ~H"""
    <p class="sr-only"><%= @text %></p>
    """
  end
end
```

This feature is implemented using the "sr-only" class modifier.

```heex
<p class="sr-only">Example text</p>
```

#### Sample from my code
```heex
<section class="bg-white p-6 rounded-lg shadow-lg border-4 border-gray-300 transition-colors duration-300 dark:bg-gray-700 dark:border-gray-500">
  <p class="sr-only">This section provides information about me, such as my hobbies, favorite movies and games, and favorite quotes!</p>
</section>
```


### Accessibility Concern 2: Labels

#### Description:
To make form fields more accessible, labels can be added to explain what each field requires, which can be read by a screen reader.


#### Example Code:
```elixir
<.simple_form :let={f} for={@message_changeset} class="p-6 space-y-4" phx-change="change-message" phx-submit="save-message">
  <label for="email">Email</label>
  <.input field={f[:email]} type="email" id="email"/>
  <.button type="submit" class="w-full">Submit</.button>
</.simple_form>
```

This feature is implemnted by assocaating a "label" tag to each input.

```heex
<label for="email">Email</label>
<input type="email" id="email" name="email"/>
```

#### Sample from my code
```heex
<.simple_form :let={f} for={@message_changeset} class="p-6 space-y-4" phx-change="change-message" phx-submit="save-message">
  <label for="email">Email</label>
  <.input field={f[:email]} type="email" id="email"/>

  <label for="subject">Subject</label>
  <.input field={f[:subject]} type="text" id="subject"/>

  <label for="message">Message</label>
  <.input field={f[:message]} type="text" id="message"/>

  <.button type="submit" class="w-full">Submit</.button>
</.simple_form>
```


### Accessibility Concern 3: Alt Text for Images

#### Description:
Alternative text (alt text) provides a description of an image, which can be read by screen readers.

#### Example Code:
```elixir
<.img src="/images/logo.png" alt="Company Logo" class="h-10 w-auto"/>
```

This feature is implemented by adding an "alt" attribute to image elements.

```heex
<img src="/images/avatar.jpg" alt="User Avatar" class="w-12 h-12 rounded-full">
```

#### Sample from my code
```heex
<a href="/" class="flex items-center space-x-1 rtl:space-x-reverse flex-grow ml-6">
  <img src="/images/profile.png" class="h-8 mr-3 rounded-full" alt="Profile Picture">
</a>
```


### Accessibility Concern 4: Dark Mode Support

#### Description:
Dark mode changes the color scheme and can reduce eye strain. A light/dark mode toggle allows users to switch between light and dark mode depending on their preferences.

#### Example Code:
```elixir
defmodule MyAppWeb.LayoutView do
  use MyAppWeb, :view

  def theme_class(assigns) do
    if assigns[:dark_mode], do: "dark", else: "light"
  end
end
```

This feature is implemented by adding a function to toggle dark mode and adding the "dark" class modifier, which displays a different color when in dark mode.

```heex
<button phx-click="toggle-dark-mode" class="p-2">
  <span class="dark:hidden">🌞 Light Mode</span>
  <span class="hidden dark:block">🌙 Dark Mode</span>
</button>

<div class="bg-white text-black dark:bg-gray-900 dark:text-white p-6">
  Content adjusts based on theme preference.
</div>
```

#### Sample from my code
```heex
<p class="mt-4 text-center text-gray-700 dark:text-gray-300">
  “{gettext("Be curious, not judgmental")}” - Ted Lasso
</p>
```

### Accessibility Concern 5: Semantic HTML Elements

#### Description:
Semantic HTML elements means to avoid generic tags like div and span in favor of more descriptive elements like header, nav, and main. This improves accessibility by making the structure of the page clearer to assistive technology like screen readers.


#### Example Code:
```elixir
def render(assigns) do
  ~H"""
  <header>
    <h1>Website Header</h1>
  </header>
  <nav>
    <ul>
      <li><a href="/home">Home</a></li>
      <li><a href="/about">About</a></li>
    </ul>
  </nav>
  """
end
```

This feature is implemented by using descriptive tags like header, nav, ul, li.

```heex
<header>
  <h1>Website Title</h1>
</header>

<nav>
  <ul>
    <li><.link navigate="/home">Home</.link></li>
    <li><.link navigate="/profile">Profile</.link></li>
  </ul>
</nav>
```

#### Sample from my code
```heex
<body class="bg-gray-100 text-gray-900 font-sans transition-colors duration-300 dark:bg-gray-900 dark:text-white">
  <main class="p-6 grid grid-cols-1 md:grid-cols-2 gap-6 dark:bg-gray-900">
    <section class="bg-white p-6 rounded-lg shadow-lg border-4 border-gray-300 transition-colors duration-300 dark:bg-gray-700 dark:border-gray-500 flex items-center justify-center">
      <img src={~p"/images/giraffe.png"} alt="Giraffe" class="rounded-full max-w-xs mt-4">
    </section>
  </main>
</body>

<footer class="bg-gray-200 p-4 mt-6 text-center transition-colors duration-300 dark:bg-gray-900 dark:text-white">
  <ul class="flex justify-center gap-x-2 list-none">
    <li><.badge color="red">{gettext("Red")}</.badge></li>
    <li><.badge color="green">{gettext("Green")}</.badge></li>
  </ul>
</footer>
```

### Accessibility Concern 6: Descriptive Link Text

#### Description:
A descriptive link text is a clear explanation of where a link leads, which is useful for people using screen readers.

#### Example Code:
```elixir
link("Learn more about accessibility", to: "/accessibility-guide")
```

This feature is implemented by adding text inside of a link element.

```heex
<.link navigate="/accessibility-guide">Learn more about accessibility</.link>
```

#### Sample from my code
```heex
<.link href={~p"/users/reset_password"} class="text-sm font-semibold dark:text-white">
  Forgot your password?
</.link>
```

### Accessibility Concern 7: Skip Links for Navigation

#### Description:
Skip links are hidden links that can be read by screenreaders or viewed by tabbing the webpage, and can be used to skip directly to relevant content.


#### Example Code:
```elixir
defmodule MyAppWeb.LayoutView do
  use MyAppWeb, :view

  def skip_link(assigns) do
    ~H"""
    <a href="#main-content" class="sr-only focus:not-sr-only focus:absolute focus:top-0 focus:left-0 focus:bg-white focus:text-black focus:p-2 z-50">
      Skip to main content
    </a>
    """
  end
end
```

A skip link, placed above the navbar, allows users to jump directly to the main content.  It works by linking to an element's ID, enabling quick navigation when clicked.

```heex
<.skip_link />

<main id="main-content" class="p-6 grid grid-cols-1 md:grid-cols-2 gap-6 dark:bg-gray-900">
  Content here...
</main>
```

#### Sample from my code
```heex
<a href="#main-content" class="sr-only focus:not-sr-only focus:absolute focus:top-0 focus:left-0 focus:bg-white focus:text-black focus:p-2 z-50">
      Skip to Content
</a>

<main id="main-content" class="p-6 grid grid-cols-1 md:grid-cols-2 gap-6 dark:bg-gray-900">
  Content here...
</main>
```
