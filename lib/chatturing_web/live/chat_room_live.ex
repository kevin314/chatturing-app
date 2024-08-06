defmodule ChatturingWeb.PageLive do
  use Phoenix.LiveView

  def mount(params, session, socket) do
    user_id = Ecto.UUID.generate()
    room = params["room"] || session["room"]

    {:ok, assign(socket, room: room, user_id: user_id, turn_user_id: nil, loading: true)}
  end

  def handle_event("join_chat", %{"user_id" => user_id, "value" => _value}, socket) do
    random_num = :rand.uniform()

    if random_num > 0.5 do
      {:ok, room} = Chatturing.RoomRegistry.allocate_room()
      Chatturing.RoomRegistry.add_user_to_room(room, user_id)

      if connected?(socket), do: Phoenix.PubSub.subscribe(Chatturing.PubSub, "chat_room:" <> room)

      users = Chatturing.RoomRegistry.get_users_from_room(room)
      if length(users) == 2 do
        socket = assign(socket, room: room, user_id: user_id, loading: true, turn_user_id: socket.assigns.user_id)
        Process.send_after(self(), {:check_room, room}, 3000)
        {:noreply, socket}
      else
        socket = assign(socket, room: room, user_id: user_id, loading: true)
        Process.send_after(self(), {:check_room, room}, 10000)
        {:noreply, socket}
      end
    else
      room = "room:930b9c27-5a6d-46e8-bot5-51d998650e40"
      socket = assign(socket, room: room, user_id: user_id, loading: true, turn_user_id: socket.assigns.user_id)
      Process.send_after(self(), {:check_room, room}, 3000)
      {:noreply, socket}
    end
  end

  def handle_event("send_message", %{"message" => message, "user_id" => _user_id}, socket) do
    room = socket.assigns.room
    user_id = socket.assigns.user_id
    if room == "room:930b9c27-5a6d-46e8-bot5-51d998650e40" do

      saved = socket.assigns[:saved] || ""
      res = Chatturing.Messenger.send_message_to_python(message, saved, user_id)
      random_number = :rand.uniform(8000)
      :timer.sleep(2000 + random_number)

      socket = assign(socket, saved: res["saved"])
      socket = push_event(socket, "update_turn", %{"turnUserId" => user_id})
      {:noreply, push_event(socket, "new_msg", %{"message" => res["message"], "user_id" => "bot"})}

    else
      Phoenix.PubSub.broadcast(Chatturing.PubSub, "chat_room:" <> room, {:new_message, %{"message" => message, "user_id" => user_id}})
      {:noreply, socket}
    end
  end

  @spec handle_info({:new_message, map()}, Phoenix.LiveView.Socket.t()) :: {:noreply, map()}
  def handle_info({:new_message, %{"message" => message, "user_id" => user_id}}, socket) do
    users = Chatturing.RoomRegistry.get_users_from_room(socket.assigns.room)
    if Enum.at(users, 0) != user_id do
      socket = assign(socket, :turn_user_id, Enum.at(users, 0))
      socket = push_event(socket, "update_turn", %{"turnUserId" => socket.assigns.turn_user_id})
      {:noreply, push_event(socket, "new_msg", %{"message" => message, "user_id" => user_id})}
    else
      socket = assign(socket, :turn_user_id, Enum.at(users, 1))
      socket = push_event(socket, "update_turn", %{"turnUserId" => socket.assigns.turn_user_id})
      {:noreply, push_event(socket, "new_msg", %{"message" => message, "user_id" => user_id})}
    end
  end

  def handle_info({:update_turn, %{"user_id" => user_id}}, socket) do
    {:noreply, push_event(socket, "update_turn", %{"turnUserId" => user_id})}
  end

  def handle_info({:end_game, %{"room" => room}}, socket) do
    {:noreply, push_event(socket, "init_guess", %{"room" => room})}
  end

  def handle_info({:check_room, room}, socket) do
    if room == "room:930b9c27-5a6d-46e8-bot5-51d998650e40" do
      send(self(), {:finish_loading})
      {:noreply, socket}
    else
      users_in_room = Chatturing.RoomRegistry.get_users_from_room(room)

      if length(users_in_room) >= 2 do
        Phoenix.PubSub.broadcast(Chatturing.PubSub, "chat_room:" <> room, {:finish_loading})
        {:noreply, socket}
      else
        send(self(), {:switch_room, room})
        {:noreply, socket}
      end
    end
  end

  def handle_info({:switch_room, room}, socket) do
    Chatturing.RoomRegistry.remove_room(room)
    room = "room:930b9c27-5a6d-46e8-bot5-51d998650e40"

    socket = assign(socket, room: room, user_id: socket.assigns.user_id, loading: true, turn_user_id: socket.assigns.user_id)
    Process.send_after(self(), {:check_room, room}, 3000)
    {:noreply, socket}
  end

  def handle_info({:finish_loading}, socket) do
    room = socket.assigns.room

    random_number = :rand.uniform()

    if room == "room:930b9c27-5a6d-46e8-bot5-51d998650e40" and random_number > 0.5 do
      room = socket.assigns.room
      socket = assign(socket, :loading, false)

      Process.send_after(self(), {:end_game, %{"room" => room}}, 120000)
      socket = push_event(socket, "start_timer", %{"time" => 120000})

      send(self(), {:send_bot_message})
      {:noreply, socket}
    else
      socket = push_event(socket, "update_turn", %{"turnUserId" => socket.assigns.turn_user_id})
      socket = assign(socket, :loading, false)

      Process.send_after(self(), {:end_game, %{"room" => room}}, 120000)
      {:noreply, push_event(socket, "start_timer", %{"time" => 120000})}
    end
  end

  def handle_info({:send_bot_message}, socket) do
    res = Chatturing.Messenger.send_message_to_python("hello", "", socket.assigns.user_id)
    random_number = :rand.uniform(8000)

    :timer.sleep(2000 + random_number)

    socket = assign(socket, saved: res["saved"])

    socket = push_event(socket, "update_turn", %{"turnUserId" => socket.assigns.user_id})
    {:noreply, push_event(socket, "new_msg", %{"message" => res["message"], "user_id" => "bot"})}
  end


  def terminate(_reason, socket) do
    room = socket.assigns.room
    if room == nil do
      :ok
    else
      Chatturing.RoomRegistry.remove_room(room)
      Phoenix.PubSub.broadcast(Chatturing.PubSub, "chat_room:" <> room, {:end_game, %{"room" => room}})
      :ok
    end
  end


  def render(assigns) do
    ~H"""
    <%= if @room do %>
      <%= if @loading do %>
        <div id="loading-screen">
          <p>Loading... Please wait for another user to join.</p>
        </div>
      <% else %>
        <div id="chat-room-container" id="chat-submit" phx-hook="Chat">
          <p>User: <%= @user_id %></p>
          <p>Room: <%= @room %></p>
          <div id="room-info" data-user-id={@user_id} data-room-id={@room}></div>
          <div class="chat">
            <div class="chat-title">
              <h1>Time Remaining</h1>
              <h2 id="timer">0:00</h2>
              <figure class="avatar">
                <img src="" />
              </figure>
            </div>
            <div class="messages">
              <div class="messages-content" ></div>
            </div>
              <div class="message-box">
                <textarea type="text" class="message-input" placeholder="Type message..." disabled="true"></textarea>
                <button type="submit" class="message-submit" disabled="true">Send</button>
              </div>
            <div id="prompt" style="display:none;">
              <p>WHO DID YOU TALK TO?</p>
              <button id="human-btn">HUMAN</button>
              <button id="bot-btn">BOT</button>
            </div>
            <div id="guess-result" style="display:none;">
              <p>THIS CONVERSATION WAS WITH A</p>
              <p id="guess"></p>
            </div>
          </div>
        <div class="bg"></div>
        </div>
      <% end %>
    <% else %>
      <div id="home-screen">
      <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Lato">

      <div class="logo-text">
      <div class="anim-letter-1">c</div>
      <div class="anim-letter-2">h</div>
      <div class="anim-letter-3">a</div>
      <div class="anim-letter-4">t</div>
      <div class="anim-letter-5">•</div>
      <div class="anim-letter-6">t</div>
      <div class="anim-letter-7">u</div>
      <div class="anim-letter-8">r</div>
      <div class="anim-letter-9">i</div>
      <div class="anim-letter-10">n</div>
      <div class="anim-letter-11">g</div>
      </div>
        <p>Join a chat room to play!</p>
        <button phx-click="join_chat" phx-value-user_id={@user_id}>Go to Chat Room</button>
      </div>
    <% end %>
    """
  end
end
