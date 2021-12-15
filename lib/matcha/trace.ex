defmodule Matcha.Trace do
  alias Matcha.Trace

  @moduledoc """
  About tracing.
  """

  require Matcha

  alias Matcha.Context
  alias Matcha.Helpers

  alias Matcha.Spec

  @default_trace_limit 1
  @recon_any_function :_
  @matcha_any_function @recon_any_function
  @recon_any_arity :_
  @matcha_any_arity :any

  defstruct [:module, :function, :arguments, limit: @default_trace_limit, opts: []]

  @type t :: %__MODULE__{
          module: atom(),
          function: atom(),
          arguments: :any | 0..255 | Spec.t(),
          limit: pos_integer(),
          opts: Keyword.t()
        }

  # Ensure only valid traces are built
  defp build_trace!(module, function, arguments, limit, opts) do
    problems =
      []
      |> trace_problems_module_exists(module)
      |> trace_problems_function_exists(module, function)
      |> trace_problems_numeric_arities_valid(arguments)
      |> trace_problems_function_with_arity_exists(module, function, arguments)
      |> trace_problems_ensure_match_spec_tracing_context(arguments)
      |> trace_problems_match_spec_valid(arguments)

    trace = %__MODULE__{
      module: module,
      function: function,
      arguments: arguments,
      limit: limit,
      opts: opts
    }

    if length(problems) > 0 do
      raise Trace.Error, source: trace, details: "when building trace", problems: problems
    else
      trace
    end
  end

  defp trace_problems_module_exists(problems, module) do
    if Helpers.module_exists?(module) do
      problems
    else
      [
        {:error, "cannot trace a module that doesn't exist: `#{module}`"}
        | problems
      ]
    end
  end

  defp trace_problems_function_exists(problems, module, function) do
    if Helpers.function_exists?(module, function) do
      problems
    else
      [
        {:error, "cannot trace a function that doesn't exist: `#{module}.#{function}`"}
        | problems
      ]
    end
  end

  defp trace_problems_numeric_arities_valid(problems, arguments) do
    if (is_integer(arguments) and (arguments < 0 or arguments > 255)) or
         (is_atom(arguments) and arguments != @matcha_any_arity) do
      [
        {:error,
         "invalid arguments provided to trace: `#{inspect(arguments)}`, must be an integer within `0..255`, a `Matcha.Spec`, or `#{@matcha_any_arity}`"}
        | problems
      ]
    else
      problems
    end
  end

  defp trace_problems_function_with_arity_exists(problems, module, function, arguments) do
    if is_integer(arguments) and arguments in 0..255 do
      if Helpers.function_with_arity_exists?(module, function, arguments) do
        problems
      else
        [
          {:error,
           "cannot trace a function that doesn't exist: `#{module}.#{function}/#{arguments}`"}
          | problems
        ]
      end
    else
      problems
    end
  end

  defp trace_problems_ensure_match_spec_tracing_context(problems, arguments) do
    if is_map(arguments) and Map.get(arguments, :__struct__) == Spec and
         arguments.context != Context.Trace do
      [
        {:error,
         "#{inspect(arguments)} was not defined in a `#{Matcha.Context.Trace.__context_name__()}` context, try defining in a tracing context via `Matcha.spec(#{Matcha.Context.Trace.__context_name__()}) do...`"}
        | problems
      ]
    else
      problems
    end
  end

  defp trace_problems_match_spec_valid(problems, arguments) do
    if is_map(arguments) and Map.get(arguments, :__struct__) == Spec and
         arguments.context == Context.Trace do
      case Spec.validate(arguments) do
        {:ok, _spec} -> problems
        {:error, spec_problems} -> spec_problems ++ problems
      end
    else
      problems
    end
  end

  @doc """
  Trace `function` calls to `module`, executing a spec on matching arguments, using provided `opts`.

  The `clauses` in the do block provided to this macro become a `Matcha.Spec` that is used during tracing.

  By default, only #{@default_trace_limit} calls will be traced.
  More calls can be traced by providing an integer `:limit` in the `opts`.

  All other `opts` are forwarded to `:recon_trace.calls/3`.
  """
  defmacro calls_matching(module, function, opts \\ [], _source = [do: clauses]) do
    quote do
      require Matcha

      Matcha.Trace.calls(
        unquote(module),
        unquote(function),
        Matcha.spec(:trace, do: unquote(clauses)),
        unquote(opts)
      )
    end
  end

  @doc """
  Trace `function` calls to `module`, executing the `spec` on matching arguments, using provided `opts`.

  By default, only #{@default_trace_limit} calls will be traced.
  More calls can be traced by providing an integer `:limit` in the `opts`.

  All other `opts` are forwarded to `:recon_trace.calls/3`.
  """
  def calls(module, function, spec, opts \\ []) do
    do_trace(module, function, spec, opts)
  end

  @doc """
  Trace one `function` call to a `module`, of any arity.
  """
  def function(module, function) do
    do_trace(module, function, @matcha_any_arity, [])
  end

  @doc """
  Trace one `function` call to `module` with given `arity`.

  `arity` may be `#{@recon_any_arity}`, in which case all arities will be traced.
  """
  def function(module, function, arity) do
    do_trace(module, function, arity, [])
  end

  @doc """
  Trace `function` calls to `module` with given `arity`, using provided `opts`.

  `arity` may be `#{@recon_any_arity}`, in which case all arities will be traced.

  By default, only #{@default_trace_limit} calls will be traced.
  More calls can be traced by providing an integer `:limit` in the `opts`.

  All other `opts` are forwarded to `:recon_trace.calls/3`.
  """
  def function(module, function, arity, opts) do
    do_trace(module, function, arity, opts)
  end

  @doc """
  Trace all calls to a `module`, using provided `opts`.

  By default, only #{@default_trace_limit} calls will be traced.
  More calls can be traced by providing an integer `:limit` in the `opts`.

  All other `opts` are forwarded to `:recon_trace.calls/3`.
  """
  def module(module, opts \\ [])
      when is_atom(module) and is_list(opts) do
    do_trace(module, @matcha_any_function, @matcha_any_arity, opts)
  end

  # Build trace from args/opts
  defp do_trace(module, function, arguments, opts) do
    {limit, opts} = Keyword.pop(opts, :limit, @default_trace_limit)
    trace = build_trace!(module, function, arguments, limit, opts)

    do_recon_trace_calls(trace)
  end

  # Translate a trace to :recon_trace.calls arguments and invoke it
  defp do_recon_trace_calls(%Trace{} = trace) do
    recon_module = trace.module

    recon_function =
      case trace.function do
        @matcha_any_function -> @recon_any_function
        function -> function
      end

    recon_arguments =
      case trace.arguments do
        @matcha_any_arity -> @recon_any_arity
        arity when is_integer(arity) -> arity
        %Spec{source: source} -> source
      end

    recon_limit = trace.limit

    recon_opts = trace.opts

    :recon_trace.calls({recon_module, recon_function, recon_arguments}, recon_limit, recon_opts)
  end

  @spec awaiting_messages?(:all | pid, timeout :: non_neg_integer()) :: boolean
  @doc """
  Checks if `pid` is awaiting trace messages.

  Waits `timeout` milliseconds for the `pid` to report that all trace messages
  intended for it when `awaiting_messages?/2` was called have been delivered.

  Returns `true` if no response is received within `timeout`, and you may assume
  that `pid` is still working through trace messages it has received.
  If it receives confirmation before the `timeout`, returns `false`.

  The `pid` must refer to an alive (or previously alive) process
  ***from the same node this function is called from***,
  or it will raise an `ArgumentError`.

  If the atom `:all` is provided instead of a `pid`, this function returns `true`
  if ***any*** process on the current node is awaiting trace messages.

  This function is best used when shutting down processes (or the current node),
  to give them a chance to finish any tracing they are handling.

  """
  def awaiting_messages?(pid \\ :all, timeout \\ 5000) do
    ref = request_confirmation_all_messages_delivered(pid)

    receive do
      {:trace_delivered, ^pid, ^ref} -> false
    after
      timeout -> true
    end
  end

  defp request_confirmation_all_messages_delivered(pid) do
    :erlang.trace_delivered(pid)
  end

  @spec info(pid_port_func_event) :: any
        when pid_port_func_event:
               pid()
               | port()
               | :new
               | :new_processes
               | :new_ports
               | {module :: atom(), function :: atom(), arity :: non_neg_integer()}
               | :on_load
               | :send
               | :receive
  def info(_pid_port_func_event) do
  end
end
