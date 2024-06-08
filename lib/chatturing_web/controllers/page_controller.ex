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
    {:ok, room} = Chatturing.RoomRegistry.allocate_room()
    Chatturing.RoomRegistry.add_user_to_room(room, user_id)
    render(conn, :home, room: room, user_id: user_id)
  end

  @spec chat(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def chat(conn, _params) do
    IO.puts('CHAT!')
    user_id = Ecto.UUID.generate()
    render(conn, :chat, user_id: user_id)
  end
end
