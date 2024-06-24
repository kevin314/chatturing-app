defmodule ChatturingWeb.MessageController do
  use ChatturingWeb, :controller

  def create(conn, %{"message" => message}) do
    # Process the message
    IO.inspect(message)

    # Send a response
    json(conn, %{"status" => "success", "message" => message})
  end
end
