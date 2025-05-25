defmodule AppWeb.CourseController do
  use AppWeb, :controller

  alias App.Bucknell
  alias App.Bucknell.Course

  def index(conn, _params) do
    courses = Bucknell.list_courses()
    render(conn, :index, courses: courses)
  end

  def new(conn, _params) do
    changeset = Bucknell.change_course(%Course{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"course" => course_params}) do
    case Bucknell.create_course(course_params) do
      {:ok, course} ->
        conn
        |> put_flash(:info, "Course created successfully.")
        |> redirect(to: ~p"/courses/#{course}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    course = Bucknell.get_course!(id)
    render(conn, :show, course: course)
  end

  def edit(conn, %{"id" => id}) do
    course = Bucknell.get_course!(id)
    changeset = Bucknell.change_course(course)
    render(conn, :edit, course: course, changeset: changeset)
  end

  def update(conn, %{"id" => id, "course" => course_params}) do
    course = Bucknell.get_course!(id)

    case Bucknell.update_course(course, course_params) do
      {:ok, course} ->
        conn
        |> put_flash(:info, "Course updated successfully.")
        |> redirect(to: ~p"/courses/#{course}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, course: course, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    course = Bucknell.get_course!(id)
    {:ok, _course} = Bucknell.delete_course(course)

    conn
    |> put_flash(:info, "Course deleted successfully.")
    |> redirect(to: ~p"/courses")
  end
end
