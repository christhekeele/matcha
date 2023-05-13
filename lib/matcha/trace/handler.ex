defmodule Matcha.Trace.Handler do
  @callback handle_trace :: any()

  alias __MODULE__

  alias Matcha.Trace

  use GenServer

  def start_link(%Trace{handler: pid}) when is_pid(pid) do
    {:ok, pid}
  end

  def start_link(%Trace{handler: fun}) when is_function(fun, 1) do
    do_start(fun)
  end

  def start_link(%Trace{handler: mod}) when is_atom(mod) do
    do_start(Function.capture(mod, :handle_trace, 1))
  end

  def start_link(%Trace{handler: {mod, fun}}) when is_atom(mod) and is_atom(fun) do
    do_start(Function.capture(mod, fun, 1))
  end

  defp do_start(fun) do
    GenServer.start_link(__MODULE__, fun)
  end

  def init(handler) do
    {:ok, handler}
  end

  def handle_info(trace_event, handler) do
    handler.(trace_event)
    {:noreply, handler}
  end
end
