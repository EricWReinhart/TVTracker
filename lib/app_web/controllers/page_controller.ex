defmodule AppWeb.PageController do
  import AppWeb.PageHTML
  use AppWeb, :controller

  @courses [
    %{semester: "Fall 2024", name: ["CSCI 315", "CSCI 475", "MATH 303", "PHIL 100", "POLS 120"]}, %{semester: "Spring 2025", name: ["CSCI 379", "CSCI 475", "MATH 230", "PHIL 100", "MUSC 123"]}
  ]

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    # IO.inspect(App.Planets.list_planets)
    # changeset = App.Notification.change_message(%Message{})
    # render(conn, :home, message_changeset: changeset)
    render(conn, :home)
    # changeset = App.Notification.change_message(%App.Notification.Message{}) # Ensure correct module path
  end

  # Case for /courses/:slug where slug is valid
  def courses(conn, %{"slug" => slug}) when slug in ["fall_2024", "spring_2025"] do
    semester = slug_to_semester(slug)
    filtered_courses =
      @courses
      |> Enum.filter(fn course -> course.semester == semester end)
    render(conn, :courses, courses: filtered_courses)
  end

  # Courses, invalid slug
  def courses(conn, %{"slug" => _slug}) do
    render(conn, "error.html", courses: [], error: "Invalid semester! :(")
  end

  # Courses, no slug
  def courses(conn, %{})  do
    render(conn, :courses, courses: @courses)
  end

  # Courses, no slug
  # def courses(conn, %{})  do
  #   # IO.inspect(Bucknell.list_courses())
  #   render(conn, :courses, courses: Bucknell.list_courses())
  # end

  # Case for /gallery
  # def gallery(conn, %{"slug" => _slug}) do
  #   render(conn, "error.html", gallery: [], error: "Invalid URL :(")
  # end

  # # Gallery, no slug
  # def gallery(conn, %{})  do
  #   render(conn, :gallery)
  # end

  # def random_redirect(conn, _params) do
  #   # List of pages you want to randomly redirect to
  #   pages = ["/", "/planets", "/planets/random", "/courses", "/gallery"]

  #   # Pick a random page from the list
  #   random_page = Enum.random(pages)

  #   # Redirect to the chosen page
  #   redirect(conn, to: random_page)
  # end

end
