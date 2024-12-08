defmodule Matcha.Trace.Handler do
  @moduledoc """
  About trace handlers.
  """

  @default_width 120

  alias Matcha.Trace

  import Inspect.Algebra

  use GenServer

  defstruct [:trace, :caller, :io_device, :width, :worker_supervisor]

  @type t :: %__MODULE__{
          trace: Trace.t(),
          caller: pid() | nil,
          io_device: IO.device(),
          width: non_neg_integer() | :infinity,
          worker_supervisor: pid()
        }

  def options(options \\ []) do
    {caller, options} = Keyword.pop(options, :caller, self())
    {io_device, options} = Keyword.pop(options, :io_device, Process.group_leader())
    {width, options} = Keyword.pop(options, :width, @default_width)

    {[
       caller: caller,
       io_device: io_device,
       width: width
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

    {:ok, worker_supervisor} = Trace.Supervisor.start_worker_supervisor(handler, [])
    handler = %__MODULE__{handler | worker_supervisor: worker_supervisor}

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

  def handle_cast({:__matcha_trace__, message}, handler = %__MODULE__{trace: %Trace{handler: custom_handler}}) do
    worker = if custom_handler do
      fn ->
        custom_handler.(handler, message)
      end
    else
      fn ->
        IO.puts(handler.io_device, format_message(handler, message))
      end
    end

    Task.Supervisor.start_child(handler.worker_supervisor, worker)

    {:noreply, handler}
  end

  @spec format_message(%__MODULE__{}, Trace.message()) :: iodata()
  @doc """
  Formats a trace message.
  """
  def format_message(handler, message)

  def format_message(handler, {:trace, pid, :call, {module, function, arguments}}) do
    call = format_call(module, function, arguments, pid)

    "Matcha.Trace:"
    |> Inspect.Algebra.glue(call)
    |> Inspect.Algebra.nest(2)
    |> Inspect.Algebra.format(handler.width)
  end

  def format_message(handler, {:trace, pid, :call, {module, function, arguments}, message}) do
    call = format_call(module, function, arguments, pid, message)

    "Matcha.Trace:"
    |> Inspect.Algebra.glue(call)
    |> Inspect.Algebra.nest(2)
    |> Inspect.Algebra.format(handler.width)
  end

  def format_message(handler, term) do
    # "Matcha.Trace:"
    # |> Inspect.Algebra.glue("unrecognized trace message:")
    # # |> Inspect.Algebra.
    # |> Inspect.Algebra.nest(2)
    "Matcha.Trace: unrecognized trace message\n```\n#{inspect(term)}\n```\n"
  end

  defp format_call(module, function, arguments, pid, message \\ nil)

  defp format_call(module, function, arguments, pid, message) when is_list(arguments) do
    arity = length(arguments)
    call = call_to_string(module, function, arity)

    " traced call `#{call}`" <>
      "\n  on pid: #{inspect(pid)}" <>
      if message do
        "\n  with message: #{message}"
      else
        ""
      end <>
      "\n  with arguments:\n```\n#{inspect(arguments)}\n```"
  end

  defp format_call(module, function, arity, pid, message) when is_integer(arity) do
    call = call_to_string(module, function, arity)

    "\n  traced call `#{call}`" <>
      "\n  on pid: #{inspect(pid)}" <>
      if message do
        "\n  with message: #{message}"
      else
        ""
      end
  end

  defp format_arguments(arguments) do

  end

  defp call_to_string(module, function, arity) when is_integer(arity) do
    Macro.to_string(quote(do: &(unquote(module).unquote(function) / unquote(arity))))
  end
end
