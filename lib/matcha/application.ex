defmodule Matcha.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    [
      {Matcha.Trace.Supervisor, name: Matcha.Trace.Tracer.Supervisor},
      {Matcha.Trace.Supervisor, name: Matcha.Trace.Handler.Supervisor},
      {Matcha.Trace.Supervisor, name: Matcha.Trace.Worker.Supervisor}
    ]
    |> Supervisor.start_link(strategy: :one_for_one, name: Matcha.Supervisor)
  end
end
