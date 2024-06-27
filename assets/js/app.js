// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
//import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken}
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

let Hooks = {}

Hooks.Chat = {
  mounted() {
    console.log('mounted!')
    this.setupEventListeners()
  },
  updated() {
    console.log('updated!')
    this.setupEventListeners()
  },
  setupEventListeners() {
    let roomInfo = document.getElementById("room-info");
    let userId = roomInfo.getAttribute("data-user-id");
    let roomId = roomInfo.getAttribute("data-room-id");

    var $messages = $('.messages-content');

    let d, h, m, i = 0;

    //$messages.mCustomScrollbar();

    function updateScrollbar() {
      $messages.mCustomScrollbar("update").mCustomScrollbar('scrollTo', 'bottom', {
        scrollInertia: 10,
        timeout: 0
      });
    }

    function initializeScrollbar() {
      $messages.mCustomScrollbar();
      console.log($messages)
    }

    this.handleEvent("start_timer", ({time}) => {
      console.log("HANDLE EVENT START TIMER", time)
      startTimer(time);
    });

    function startTimer(time) {
      console.log("TIMER STARTED");
      let timerElement = document.querySelector("#timer");
      let endTime = Date.now() + time;
      let animationFrame;
      
      const updateTimer = () => {
        let now = Date.now();
        let remaining = endTime - now;
        
        if (remaining <= 0) {
          timerElement.textContent = "00:00";
          cancelAnimationFrame(animationFrame);
          // Optionally, you can trigger another event or function when the timer ends
        } else {
          let seconds = Math.floor((remaining / 1000) % 60);
          let minutes = Math.floor((remaining / (1000 * 60)) % 60);
          timerElement.textContent = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
          animationFrame = requestAnimationFrame(updateTimer); // Schedule the next update
        }
      };
    
      updateTimer(); // Initialize the timer display immediately
      animationFrame = requestAnimationFrame(updateTimer);
    }

    function setDate() {
      d = new Date();
      if (m != d.getMinutes()) {
        m = d.getMinutes();
        $('<div class="timestamp">' + d.getHours() + ':' + m + '</div>').appendTo($('.message:last'));
      }
    }

    function insertMessage(msg) {
      console.log('insert message')
      messageInput.setAttribute('disabled', 'true');
      sendButton.setAttribute('disabled', 'true');
      if ($.trim(msg) == '') {
        return false;
      }
      $('<div class="message message-personal">' + msg + '</div>').appendTo($('.mCSB_container')).addClass('new');
      setDate();
      $('.message-input').val(null);
      updateScrollbar();
    }

    function receiveMessage(msg) {
      $('<div class="message new"><figure class="avatar"><img src="/images/eva.png" /></figure>' 
      + msg + '</div>').appendTo($('.mCSB_container')).addClass('new');
      setDate();
      updateScrollbar();
    }

    this.handleEvent("update_turn", ({turnUserId}) => {
      updateTurn(turnUserId);
    });

    let messageInput = this.el.querySelector('.message-input');
    let sendButton = this.el.querySelector('.message-submit');
  
    function updateTurn(turnUserId) {
      console.log('updating TURN!')
      console.log('turnUserID', turnUserId)

      if (userId == turnUserId) {
        messageInput.removeAttribute('disabled');
        sendButton.removeAttribute('disabled');
      } else {
        messageInput.setAttribute('disabled', 'true');
        sendButton.setAttribute('disabled', 'true');
      }
    }

    const messageBox = this.el.querySelector('.message-box');
    console.log('dp message', messageBox)
    const prompt = this.el.querySelector('#prompt');
    console.log('dp prompt', prompt)
    const humanBtn = this.el.querySelector('#human-btn');
    const botBtn = this.el.querySelector('#bot-btn');

    const guessResult = document.getElementById('guess-result');
    const guessText = document.getElementById('guess');

    function displayGuessPrompt(room) {
      messageBox.style.display = 'none';
      prompt.style.display = 'block';

      humanBtn.addEventListener('click', () => {
        console.log('HUMAN button clicked');
        prompt.style.display = 'none';
        if (room === "room:bot") {
          guessText.textContent = 'BOT!';
        } else {
          guessText.textContent = 'HUMAN!';
        }
        guessResult.style.display = 'block';
      });

      botBtn.addEventListener('click', () => {
        console.log('BOT button clicked');
        prompt.style.display = 'none';
        if (room === "room:bot") {
          guessText.textContent = 'BOT!';
        } else {
          guessText.textContent = 'HUMAN!';
        }
        guessResult.style.display = 'block';
      });
    }

    this.el.querySelector('.message-submit').addEventListener('click', function() {
      sendMessage();
    });

    window.addEventListener('keydown', function(e) {
      if (e.which == 13) {
        e.preventDefault();
        sendMessage();
        return false;
      }
    });

    let sendMessage = () => {
      console.log('send message')
      let msg = this.el.querySelector('.message-input').value;
      if ($.trim(msg) === '') return;

      // Push the message to the channel
      this.pushEvent("send_message", { message: msg, user_id: userId });
      insertMessage(msg);
    };


    this.handleEvent("new_msg", ({message, user_id}) => {
      console.log('receive msg!')
      console.log('user_id', user_id)
      console.log(JSON.stringify(message))

      if (userId !== user_id) {
        receiveMessage(message)
      }
    });

    this.handleEvent("init_guess", ({room}) => {
      console.log('init_guess!')
      console.log('room', room)
      displayGuessPrompt(room)
    });

    window.addEventListener("beforeunload", () => {
      console.log("left channel")
    })

    initializeScrollbar();
  }
}

liveSocket = new LiveSocket("/live", Socket, {hooks: Hooks, params: {_csrf_token: csrfToken}})

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

