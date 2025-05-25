defmodule App.BucknellFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `App.Bucknell` context.
  """

  @doc """
  Generate a course.
  """
  def course_fixture(attrs \\ %{}) do
    {:ok, course} =
      attrs
      |> Enum.into(%{
        name: "some name",
        semester: "some semester"
      })
      |> App.Bucknell.create_course()

    course
  end
end
