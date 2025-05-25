defmodule AppWeb.ItemLive.FormComponent do
  use AppWeb, :live_component

  alias App.Items

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage item records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="item-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />

        <.input
          field={@form[:type]}
          type="select"
          options={App.Items.Item.type_options()}
          label="Type"
        />

        <!-- Render checkboxes for attributes -->
        <.input
          :for={i <- 1..8}
          type="checkbox"
          field={@form[String.to_atom("attr#{i}")]}
          label={"Attribute #{i}"}
        />

        <:actions>
          <.button type="submit" phx-disable-with="Saving...">Save Item</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{item: item} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Items.change_item(Map.merge(item, item.attributes || %{})))
     end)
     |> assign(:item, item)}
  end

  @impl true
  def handle_event("validate", %{"item" => item_params}, socket) do
    changeset = Items.change_item(socket.assigns.item, item_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"item" => item_params}, socket) do
    save_item(socket, socket.assigns.action, item_params)
  end

  def handle_event("toggle_checkbox", %{"value" => value, "index" => index}, socket) do
    # Convert the index from string to integer
    index = String.to_integer(index)

    # Convert the value to boolean
    checked = value == "true"

    # Update the item's attribute dynamically based on the index
    item = socket.assigns.item
    updated_item = update_checkbox_state(item, index, checked)

    # Update the socket with the new item
    {:noreply, assign(socket, item: updated_item)}
  end

  # Function to update the checkbox values on the item
  defp update_checkbox_state(item, attr_index, value) do
    # Update the item's attribute dynamically based on the checkbox index
    Map.put(item, "attr#{attr_index}", value)
  end

  defp save_item(socket, :edit, item_params) do
    case Items.update_item(socket.assigns.item, item_params) do
      {:ok, item} ->
        notify_parent({:saved, item})

        {:noreply,
         socket
         |> put_flash(:info, "Item updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_item(socket, :new, item_params) do
    case Items.create_item(item_params) do
      {:ok, item} ->
        notify_parent({:saved, item})

        {:noreply,
         socket
         |> put_flash(:info, "Item created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
