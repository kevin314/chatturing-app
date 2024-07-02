defmodule Chatturing.Messenger do
  def send_message_to_python(message, saved, user_id) do
    url = Application.get_env(:chatturing, :python_server_url) <> "/api/messages"
    payload = %{"message" => message, "saved" => saved, "user_id" => user_id} |> Jason.encode!()
    headers = [{"Content-Type", "application/json"}]

    case HTTPoison.post(url, payload, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        IO.puts("Successfully sent message to Python server")
        case Jason.decode(body) do
          {:ok, json} ->
            IO.inspect(json)
          {:error, reason} ->
            IO.puts("Failed to decode JSON response: #{reason}")
            IO.inspect(body)
        end
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.puts("Failed to send message to Python server")
        IO.inspect(reason)
    end
  end
end
