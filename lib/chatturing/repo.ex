defmodule Chatturing.Repo do
  use Ecto.Repo,
    otp_app: :chatturing,
    adapter: Ecto.Adapters.Postgres
end
