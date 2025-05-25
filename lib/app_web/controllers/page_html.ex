defmodule AppWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use AppWeb, :html

  embed_templates "page_html/*"
  def slug_to_semester(slug) do
    slug
    |> String.capitalize()
    |> String.replace("_", " ")
  end

end
