defmodule AppWeb.MessageHTML do
  use AppWeb, :html

  embed_templates "message_html/*"

  @doc """
  Renders a message form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def message_form(assigns)
end
