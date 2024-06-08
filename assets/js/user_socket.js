// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "assets/js/app.js".

// Bring in Phoenix channels client library:
import {Socket} from "phoenix"

// And connect to the path in "lib/chatturing_web/endpoint.ex". We pass the
// token for authentication. Read below how it should be used.
// 

var $messages = $('.messages-content'),
    d, h, m,
    i = 0;

$(window).on("load", function() {
  $messages.mCustomScrollbar();
});

function updateScrollbar() {
  $messages.mCustomScrollbar("update").mCustomScrollbar('scrollTo', 'bottom', {
    scrollInertia: 10,
    timeout: 0
  });
}

function setDate(){
  d = new Date();
  if (m != d.getMinutes()) {
    m = d.getMinutes();
    $('<div class="timestamp">' + d.getHours() + ':' + m + '</div>').appendTo($('.message:last'));
  }
}

function insertMessage(msg) {
  if ($.trim(msg) == '') {
    return false;
  }
  $('<div class="message message-personal">' + msg + '</div>').appendTo($('.mCSB_container')).addClass('new');
  setDate();
  $('.message-input').val(null);
  updateScrollbar();
}

$('.message-submit').click(function() {
  console.log('message submit click!')
  sendMessage();
});

$(window).on('keydown', function(e) {
  if (e.which == 13) {
    sendMessage();
    return false;
  }
});

function sendMessage() {
  let msg = $('.message-input').val();
  if ($.trim(msg) === '') return;

  // Push the message to the channel
  console.log(roomChannel)
  roomChannel.push("new_msg", { body: msg });
  insertMessage(msg);
}

function receiveMessage(msg) {
  $('<div class="message new"><figure class="avatar"><img src="/images/eva.png" /></figure>' 
  + msg + '</div>').appendTo($('.mCSB_container')).addClass('new');
  setDate();
  updateScrollbar();
}

let roomChannel = 'hello'
document.addEventListener("DOMContentLoaded", () => {
  let roomInfo = document.getElementById("room-info");
  let userId = roomInfo.getAttribute("data-user-id");
  let roomId = roomInfo.getAttribute("data-room-id");

  // let socket = new Socket("/socket", {params: {token: window.userToken}})
  let socket = new Socket("/socket", {params: {user_id: userId}})

  // When you connect, you'll often need to authenticate the client.
  // For example, imagine you have an authentication plug, `MyAuth`,
  // which authenticates the session and assigns a `:current_user`.
  // If the current user exists you can assign the user's token in
  // the connection for use in the layout.
  
  // In your "lib/chatturing_web/router.ex":
  
  //     pipeline :browser do
  //       ...
  //       plug MyAuth
  //       plug :put_user_token
  //     end
  
  //     defp put_user_token(conn, _) do
  //       if current_user = conn.assigns[:current_user] do
  //         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
  //         assign(conn, :user_token, token)
  //       else
  //         conn
  //       end
  //     end
  
  // Now you need to pass this token to JavaScript. You can do so
  // inside a script tag in "lib/chatturing_web/templates/layout/app.html.heex":
  
  //     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
  
  // You will need to verify the user token in the "connect/3" function
  // in "lib/chatturing_web/channels/user_socket.ex":
  
  //     def connect(%{"token" => token}, socket, _connect_info) do
  //       # max_age: 1209600 is equivalent to two weeks in seconds
  //       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1_209_600) do
  //         {:ok, user_id} ->
  //           {:ok, assign(socket, :user, user_id)}
  
  //         {:error, reason} ->
  //           :error
  //       end
  //     end
  //
  // Finally, connect to the socket:
  socket.connect()

  // Now that you are connected, you can join channels with a topic.
  // Let's assume you have a channel with a topic named `room` and the
  // subtopic is its id - in this case 42:

  //let allocate = socket.channel("room:allocate", {})
  let chatInput = document.querySelector("#chat-input")
  let messagesContainer = document.querySelector("#messages")
    
  roomChannel = socket.channel(roomId, {});
    joinRoom(roomChannel);
    

  function joinRoom(channel) {
    channel.join()
      .receive("ok", resp => { console.log("Joined successfully", resp) })
      .receive("error", resp => { console.log("Unable to join", resp) })
    
    // chatInput.addEventListener("keypress", event => {
    //   if(event.key === 'Enter'){
    //     channel.push("new_msg", {body: chatInput.value})
    //     chatInput.value = ""
    //   }
    // })

    channel.on("new_msg", payload => {
      // let messageItem = document.createElement("p")
      // messageItem.innerText = `[${Date()}] ${payload.body}`
      // messagesContainer.appendChild(messageItem)
      console.log(JSON.stringify(payload))

      if (userId !== payload.user_id) {
        receiveMessage(payload.body)
      }
    })

    window.addEventListener("beforeunload", () => {
      console.log("left channel")
      channel.leave()
    })
  }
})
