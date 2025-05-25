# defmodule AppWeb.Components.UI.Modal2 do
#   use Phoenix.Component

#   alias Phoenix.LiveView.JS

#   @doc """
#   Renders a Flowbite [Modal](https://flowbite.com/docs/components/modal).

#   ## Examples

#       <.modal heading="Great Modal" backdrop="static" small>
#         This is my fantastic modal.
#       </.modal>
#   """
#   attr :backdrop, :string,
#   default: "dynamic",
#   values: ~w(dynamic static),
#   doc: "Choose between static or dynamic to prevent closing the modal when clicking outside."

#   attr :heading, :string, required: true, doc: "Will be displayed left to the close button."

#   attr :small, :boolean, default: false,
#   doc: "If true, restricts the width of the modal according to the small modal variant in the Flowbite library. Will use default to the 'large' modal variant otherwise"

#   slot :inner_block, required: true

#   def modal(assigns) do
#     ~H"""
#     <!-- Outer container / backdrop -->
#     <div
#       id="default-modal"
#       tabindex="-1"
#       aria-hidden="true"
#       class="hidden overflow-y-auto overflow-x-hidden fixed top-0 right-0 left-0 z-50 justify-center items-center w-full md:inset-0 h-[calc(100%-1rem)] max-h-full"
#       phx-click={if @backdrop == "dynamic", do: close_modal(), else: nil}
#     >
#       <!-- Inner container; stops clicks inside from closing the modal -->
#       <div
#         class={"relative p-4 w-full max-h-full " <> if(@small, do: "max-w-md", else: "max-w-2xl")}
#         phx-click-stop-propagation
#       >
#         <!-- Modal content -->
#         <div class="relative bg-white rounded-lg shadow-sm dark:bg-gray-700">
#           <!-- Modal header -->
#           <div class="flex items-center justify-between p-4 md:p-5 border-b rounded-t dark:border-gray-600 border-gray-200">
#             <h3 class="text-xl font-semibold text-gray-900 dark:text-white">
#               <%= @heading %>
#             </h3>
#             <button
#               type="button"
#               phx-click={close_modal()}
#               class="text-gray-400 bg-transparent hover:bg-gray-200 hover:text-gray-900 rounded-lg text-sm w-8 h-8 ms-auto inline-flex justify-center items-center dark:hover:bg-gray-600 dark:hover:text-white"
#             >
#               <svg
#                 class="w-3 h-3"
#                 aria-hidden="true"
#                 xmlns="http://www.w3.org/2000/svg"
#                 fill="none"
#                 viewBox="0 0 14 14"
#               >
#                 <path
#                   stroke="currentColor"
#                   stroke-linecap="round"
#                   stroke-linejoin="round"
#                   stroke-width="2"
#                   d="M1 1l6 6m0 0l6 6M7 7l6-6M7 7l-6 6"
#                 />
#               </svg>
#               <span class="sr-only">Close modal</span>
#             </button>
#           </div>
#           <!-- Modal body -->
#           <div class="p-4 md:p-5 space-y-4">
#             <%= render_slot(@inner_block) %>
#           </div>
#         </div>
#       </div>
#     </div>
#     """
#   end

#   def open_modal() do
#     %JS{}
#     |> JS.show(
#       to: "#default-modal",
#       transition: {"ease-out duration-300", "opacity-0", "opacity-100"}
#     )
#   end

#   def close_modal() do
#     %JS{}
#     |> JS.hide(
#       to: "#default-modal",
#       transition: {"ease-in duration-200", "opacity-100", "opacity-0"}
#     )
#   end
# end
