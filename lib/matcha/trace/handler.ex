defmodule Matcha.Trace.Handler do
  @moduledoc """
  About trace handlers.
  """

  alias Matcha.Trace

  use GenServer

  defstruct [:trace, :caller, :io_device]

  @type t :: %__MODULE__{
          trace: Trace.t(),
          caller: pid() | nil,
          io_device: IO.device()
        }

  def options(options \\ []) do
    {caller, options} = Keyword.pop(options, :caller, self())
    {io_device, options} = Keyword.pop(options, :io_device, Process.group_leader())

    {[
       caller: caller,
       io_device: io_device
     ], options}
  end

  def child_spec(options) do
    {trace, options} = Keyword.pop!(options, :trace)
    {options, child_spec_options} = options(options)

    {id, child_spec_options} = Keyword.pop(child_spec_options, :id, __MODULE__)
    {restart, child_spec_options} = Keyword.pop(child_spec_options, :restart, :transient)
    {shutdown, child_spec_options} = Keyword.pop(child_spec_options, :shutdown, :brutal_kill)
    {significant, child_spec_options} = Keyword.pop(child_spec_options, :significant, false)

    extra_options = child_spec_options

    if extra_options != [] do
      problems =
        for option <- extra_options do
          {:error,
           "unexpected option `#{inspect(option)}` provided to `#{inspect(__MODULE__)}.child_spec/1`"}
        end

      raise Trace.Error,
        source: trace,
        details: "when building handler child spec",
        problems: problems
    else
      %{
        id: id,
        start: {__MODULE__, :start_link, [[{:trace, trace} | options]]},
        type: :worker,
        restart: restart,
        shutdown: shutdown,
        significant: significant
      }
    end
  end

  def start_link(options) do
    {trace, options} = Keyword.pop!(options, :trace)
    {options, extra_options} = options(options)

    if extra_options != [] do
      problems =
        for option <- extra_options do
          {:error,
           "unexpected option `#{inspect(option)}` provided to `#{inspect(__MODULE__)}.start_link/1`"}
        end

      raise Trace.Error,
        source: trace,
        details: "when starting trace handler",
        problems: problems
    else
      GenServer.start_link(__MODULE__, struct!(__MODULE__, [{:trace, trace} | options]))
    end
  end

  @impl true
  def init(handler = %__MODULE__{}) do
    if handler.caller do
      Process.flag(:trap_exit, true)
      Process.link(handler.caller)
    end

    {:ok, handler}
  end

  @impl true
  def handle_info(message, handler)

  def handle_info(
        {:EXIT, caller, _reason},
        handler = %__MODULE__{caller: caller}
      ) do
    {:stop, :normal, handler}
  end

  @impl true
  def handle_cast(message, handler)

  # Invoke user-defined handler function when available
  def handle_cast(
        {:__matcha_trace__, message},
        handler = %__MODULE__{trace: %Trace{handler: fun}}
      )
      when not is_nil(fun) do
    fun.(handler, message)
    {:noreply, handler}
  end

  # Otherwise, by default write back to IO device
  def handle_cast({:__matcha_trace__, message}, handler = %__MODULE__{}) do
    IO.puts(handler.io_device, Trace.format_message(message))

    {:noreply, handler}
  end
end
