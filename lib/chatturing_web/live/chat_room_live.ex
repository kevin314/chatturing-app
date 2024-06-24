defmodule ChatturingWeb.PageLive do
  use Phoenix.LiveView

  def mount(params, session, socket) do
    IO.puts('MOUNT!')
    user_id = Ecto.UUID.generate()
    room = params["room"] || session["room"]
    # {:ok, room} = Chatturing.RoomRegistry.allocate_room()
    # Chatturing.RoomRegistry.add_user_to_room(room, user_id)
    {:ok, assign(socket, room: room, user_id: user_id, id: 1)}
  end

  # def handle_event("new_msg", %{"body" => body}, socket) do
  #   broadcast!(socket, "new_msg", %{user_id: socket.assigns.user_id, body: body})
  #   {:noreply, socket}
  # end

  # def handle_event("send_message", %{"message" => message, "value" => _value}, socket) do
  #   IO.puts('handle_send_message!')
  #   #messages = socket.assigns.messages ++ [message]
  #   {:noreply, assign(socket, message: message)}
  # end

  def handle_event("join_chat", %{"user_id" => user_id, "value" => _value}, socket) do
    IO.puts('handle_join_chat!')
    random_num = :rand.uniform()
    if random_num < 0.5 do
      {:ok, room} = Chatturing.RoomRegistry.allocate_room()
      Chatturing.RoomRegistry.add_user_to_room(room, user_id)

      if connected?(socket), do: Phoenix.PubSub.subscribe(Chatturing.PubSub, "chat_room:" <> room)

      socket = assign(socket, room: room, user_id: user_id)
      {:noreply, socket}
    else
      room = "room:bot"
      socket = assign(socket, room: room, user_id: user_id)
      {:noreply, socket}
    end
  end

  def handle_event("send_message", %{"message" => message, "user_id" => _user_id}, socket) do
    IO.puts('HANDLE SEND MESSAGE!')
    room = socket.assigns.room
    user_id = socket.assigns.user_id
    if room == "room:bot" do
      saved = socket.assigns[:saved] || ""
      res = Chatturing.Messenger.send_message_to_python(message, saved, user_id)

      updated_socket = assign(socket, :saved, res["saved"])
      {:noreply, push_event(updated_socket, "new_msg", %{"message" => res["message"], "user_id" => "bot"})}

    else
      Phoenix.PubSub.broadcast(Chatturing.PubSub, "chat_room:" <> room, {:new_message, %{"message" => message, "user_id" => user_id}})
      {:noreply, socket}
    end
    #{:noreply, push_event(socket, "new_msg", %{"message" => message, user_id => user_id})}
    #{:noreply, socket}
  end

  @spec handle_info({:new_message, map()}, Phoenix.LiveView.Socket.t()) :: {:noreply, map()}
  def handle_info({:new_message, %{"message" => message, "user_id" => user_id}}, socket) do
    IO.puts('HANDLE NEW MESSAGE!')
    {:noreply, push_event(socket, "new_msg", %{"message" => message, "user_id" => user_id})}
    #{:noreply, update(socket, :messages, fn messages -> [payload.message | messages] end)}
  end

  def handle_info({:end_game, %{"user_id" => user_id}}, socket) do
    IO.puts("ENDING GAME")
    {:noreply, push_event(socket, "init_guess", %{"user_id" => user_id})}
  end

  def terminate(_reason, socket) do
    user_id = socket.assigns.user_id
    room = socket.assigns.room
    if room == nil do
      :ok
    else
      Phoenix.PubSub.broadcast(Chatturing.PubSub, "chat_room:" <> room, {:end_game, %{"user_id" => user_id}})
      #Chatturing.RoomRegistry.remove_user_from_room(room, user_id)
      :ok
    end
  end


  def render(assigns) do
    IO.puts("RENDER!")
    ~H"""
    <%= if @room do %>
      <div id="chat-room-container" id="chat-submit" phx-hook="Chat">
        <h1>Welcome to the Chat Room</h1>
        <p>User: <%= @user_id %></p>
        <p>You are in chat: <%= @room %></p>
        <div id="room-info" data-user-id={@user_id} data-room-id={@room}></div>
        <div class="chat">
          <div class="chat-title">
            <h1>Time Remaining</h1>
            <h2>1:32</h2>
            <figure class="avatar">
              <img src="" />
            </figure>
          </div>
          <div class="messages">
            <div class="messages-content"></div>
          </div>
          <div class="message-box">
            <textarea type="text" class="message-input" placeholder="Type message..."></textarea>
            <button type="submit" class="message-submit">Send</button>
          </div>
          <div id="prompt" style="display:none;">
            <p>Who did you talk to?</p>
            <button id="human-btn">HUMAN</button>
            <button id="bot-btn">BOT</button>
          </div>
          <div id="guess-result" style="display:none;">
            <p>This conversation was with a</p>
            <p id="guess"></p>
          </div>
        </div>
      <div class="bg"></div>
      </div>
    <% else %>
      <div id="home-screen">
      <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Lato">

      <!-- Text divied up in divs each corresponding to a class linked up to  n animation-->

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
        <h1>Welcome to the Home Page</h1>
        <p>This is the home page.</p>
        <button phx-click="join_chat" phx-value-user_id={@user_id}>Go to Chat Room</button>
      </div>
    <% end %>
    """
  end

end
