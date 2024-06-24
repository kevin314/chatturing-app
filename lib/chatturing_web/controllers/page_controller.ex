defmodule ChatturingWeb.PageController do
  use ChatturingWeb, :controller

  # def home(conn, _params) do
  #   # The home page is often custom made,
  #   # so skip the default app layout.
  #   render(conn, :home, layout: false)
  # end

  def home(conn, _params) do
    IO.puts('HOME!')

    user_id = Ecto.UUID.generate()
    render(conn, :home, user_id: user_id)
  end

  @spec chat(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def chat(conn, params) do
    IO.puts('CHAT!')
    IO.inspect(params)
    #user_id = Ecto.UUID.generate()
    user_id = Map.get(params, "user_id", 'wow')
    IO.puts(user_id)
    {:ok, room} = Chatturing.RoomRegistry.allocate_room()
    Chatturing.RoomRegistry.add_user_to_room(room, user_id)
    render(conn, :chat, room: room, user_id: user_id)
  end

  def chat_room(conn, params) do
    IO.puts('CHAT ROOM!')
    IO.inspect(params)
    #user_id = Ecto.UUID.generate()
    user_id = Map.get(params, "user_id", 'big')
    IO.puts(user_id)
    {:ok, room} = Chatturing.RoomRegistry.allocate_room()
    Chatturing.RoomRegistry.add_user_to_room(room, user_id)
    render(conn, ChatturingWeb.ChatRoomLive, room: room, user_id: user_id)
  end
end
