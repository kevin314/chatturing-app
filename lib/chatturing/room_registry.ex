defmodule Chatturing.RoomRegistry do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  def allocate_room do
    GenServer.call(__MODULE__, :allocate_room)
  end

  def remove_user_from_room(room, user_id) do
    GenServer.call(__MODULE__, {:remove_user_from_room, room, user_id})
  end

  def handle_call(:allocate_room, _from, state) do
    {room, new_state} = find_or_create_room(state)
    IO.puts('firstroom')
    IO.puts(room)
    {:reply, {:ok, room}, new_state}
  end

  def handle_call({:add_user_to_room, room, user}, _from, state) do
    users = Map.get(state, room, [])
    new_state = Map.put(state, room, [user | users])
    IO.puts(room)
    IO.inspect(new_state)
    {:reply, :ok, new_state}
  end

  def handle_call({:remove_user_from_room, room, user_id}, _from, state) do
    IO.puts('wow')
    IO.inspect(state)
    new_state = Map.update(state, room, [], fn users -> List.delete(users, user_id) end)
    {:reply, :ok, new_state}
  end


  defp find_or_create_room(state) do
    state
    |> Enum.find(fn {_room, users} -> length(users) < 2 end)
    |> case do
      nil ->
        IO.puts("nil room")
        room = "room:#{Enum.count(state) + 1}"
        #IO.inspect(Map.put(state, room, []))
        {room, Map.put(state, room, [])}
      {room, _users} ->
        IO.puts("found room")
        #IO.inspect(state)
        {room, state}
    end
  end

  def add_user_to_room(room, user) do
    GenServer.call(__MODULE__, {:add_user_to_room, room, user})
  end
end
