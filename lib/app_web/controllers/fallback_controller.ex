defmodule AppWeb.MyFallbackController do
  use Phoenix.Controller

  def call(conn, {:error, :not_found}) do
    conn
    |> put_root_layout(false)
    |> put_layout(false)
    |> put_status(:not_found)
    |> put_view(html: AppWeb.ErrorHTML)
    |> render(:"404")
  end

end
