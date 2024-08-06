defmodule ChatturingWeb.RoomChannel do
  use ChatturingWeb, :channel

  @impl true
  def join("room:allocate", _payload, socket) do
    case socket.assigns[:user_id] do
      nil ->
        {:error, %{reason: "unauthorized"}}
      _user_id ->
        {:ok, room} = Chatturing.RoomRegistry.allocate_room()
        Chatturing.RoomRegistry.add_user_to_room(room, socket.assigns.user_id)
        {:ok, %{room: room}, assign(socket, :room, room)}
    end
  end

  def join(room, _payload, socket) do
    #{:ok, socket}
    {:ok, %{room: room}, assign(socket, :room, room)}
  end


  @spec handle_in(<<_::32, _::_*8>>, any(), any()) ::
          {:noreply, Phoenix.Socket.t()} | {:reply, {:ok, any()}, any()}
  def handle_in("new_msg", %{"body" => body}, socket) do
    user_id = socket.assigns[:user_id]
    broadcast!(socket, "new_msg", %{body: body, user_id: user_id})
    {:noreply, socket}
  end
  @impl true
  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end
  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (room:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  @impl true
  def terminate(_reason, _socket) do
    #user_id = socket.assigns.user_id
    #room_id = socket.assigns.room
    #Chatturing.RoomRegistry.remove_user_from_room(room_id, user_id)
    :ok
  end

  # Add authorization logic here as required.
  # defp authorized?(_payload) do
  #   true
  # end
end
