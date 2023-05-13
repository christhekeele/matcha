defmodule Matcha.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    [
      Matcha.Trace.Handler.Registry,
      Matcha.Trace.Handler.Supervisor
    ]
    |> Supervisor.start_link(strategy: :rest_for_one, name: Matcha.Supervisor)
  end
end
