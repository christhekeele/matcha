defmodule Matcha.Context.Trace do
  @moduledoc """
  Additional functions that trace match specs can use in their bodies.

  The return values of specs created in this context do not differentiate
  between specs that fail to find a matching clause for the given input,
  and specs with matching clauses that literally return the `false` value;
  they return `{:traced, result, flags}` tuples either way.

  Tracing match specs offer a wide suite of instructions to drive erlang's tracing engine
  in response to matching certain calls.
  Calls to these functions in match spec bodies will, when that clause is matched,
  effect the documented change during tracing.

  These instructions are documented and type-specced here as a convenient reference.
  For more information, consult the [erlang tracing match spec docs](https://www.erlang.org/doc/apps/erts/match_spec.html#functions-allowed-only-for-tracing).

  In addition to general helpful informational functions, tracing supports:

  ### Trace Flags

  Match specs can change how tracing behaves by changing the trace flags on any process.
  See `:erlang.trace/3` for more information.

  Related functions:

  - `enable_trace/1`
  - `enabled_trace/2`
  - `disable_trace/1`
  - `disable_trace/2`
  - `trace/2`
  - `trace/3`

  ### Sequential Tracing

  Match specs can be used to transfer information between processes via sequential tracing.
  See the [erlang sequential tracing docs](https://www.erlang.org/doc/man/seq_trace.html#whatis)
  for more information.

  Related functions:
  - `is_seq_trace/0`
  - `set_seq_token/2`
  - `get_seq_token/0`

  """

  alias Matcha.Context

  use Context

  ###
  # CALLBACKS
  ##

  @impl Context
  def __erl_type__ do
    :trace
  end

  @impl Context
  def __default_match_target__ do
    []
  end

  @impl Context
  def __valid_match_target__(match_target) do
    is_list(match_target)
  end

  @impl Context
  def __invalid_match_target_error_message__(match_target) do
    "test targets for trace specs must be a list, got: `#{inspect(match_target)}`"
  end

  @impl Context
  def __prepare_source__(source) do
    {:ok, source}
  end

  @impl Context
  def __emit_erl_test_result__(result) do
    {:emit, result}
  end

  @impl Context
  def __transform_erl_test_result__(result) do
    case result do
      {:ok, result, flags, _warnings} ->
        result =
          if is_list(result) do
            List.to_string(result)
          else
            result
          end

        {:ok, {:traced, result, flags}}

      {:error, problems} ->
        {_warnings, errors} = Keyword.split(problems, [:warning])
        {:error, Matcha.Rewrite.problems(errors)}
    end
  end

  @impl Context
  def __transform_erl_run_results__(results) do
    {:ok, results}
  end

  ###
  # INFORMATIONAL FUNCTIONS
  ##

  @dialyzer {:nowarn_function, message: 1}
  @compile {:inline, message: 1}
  @spec message(message | {message, false | message, true}) :: true when message: any
  @doc """
  Sets an additional `message` appended to the trace message sent.

  One can only set one additional message in the body. Later calls replace the appended message.

  Always returns `true`.

  As a special case, `{message, false}` disables sending of trace messages ('call' and 'return_to')
  for this function call, just like if the match specification had not matched.
  This can be useful if only the side effects of the match spec clause's body part are desired.

  Another special case is `{message, true}`, which sets the default behavior,
  as if the function had no match specification;
  trace message is sent with no extra information
  (if no other calls to message are placed before `{message, true}`, it is in fact a "noop").
  """
  def message(message) do
    _ignore = message
    :noop
  end

  @dialyzer {:nowarn_function, return_trace: 0}
  @compile {:inline, return_trace: 0}
  @spec return_trace :: true
  @doc """
  Causes a `return_from` trace message to be sent upon return from the current function.

  If the process trace flag silent is active, the `return_from` trace message is inhibited.

  Always returns `true`.

  > ***Warning***:
  >
  > If the traced function is tail-recursive,
  > this match specification function destroys that property.
  > Hence, if a match specification executing this function is used on a perpetual server process,
  > it can only be active for a limited period of time, or the emulator will eventually
  > use all memory in the host machine and crash.
  > If this match specification function is inhibited
  > using process trace flag silent, tail-recursiveness still remains.
  """
  def return_trace do
    :noop
  end

  @dialyzer {:nowarn_function, exception_trace: 0}
  @compile {:inline, exception_trace: 0}
  @spec exception_trace :: true
  @doc """
  Works as `return_trace/0`, generating an extra `exception_from` message on exceptions.

  Causes a `return_from` trace message to be sent upon return from the current function.
  Plus, if the traced function exits because of an exception,
  an `exception_from` trace message is generated, ***whether or not the exception is caught***.

  If the process trace flag silent is active, the `return_from` and `exception_from` trace messages are inhibited.

  Always returns `true`.

  > ***Warning***:
  > If the traced function is tail-recursive,
  > this match specification function destroys that property.
  > Hence, if a match specification executing this function is used on a perpetual server process,
  > t can only be active for a limited period of time, or the emulator will eventually
  > use all memory in the host machine and crash.
  > If this match specification function is inhibited
  > using process trace flag silent, tail-recursiveness still remains.
  """
  def exception_trace do
    :noop
  end

  @dialyzer {:nowarn_function, process_dump: 0}
  @compile {:inline, process_dump: 0}
  @spec process_dump :: true
  @doc """
  Returns some textual information about the current process as a binary.
  """
  def process_dump do
    :noop
  end

  @dialyzer {:nowarn_function, caller: 0}
  @compile {:inline, caller: 0}
  @spec caller :: {module, function, arity :: non_neg_integer} | :undefined
  @doc """
  Returns the module/function/arity of the calling function.

  If the calling function cannot be determined, returns `:undefined`.
  This can happen with BIFs in particular.
  """
  def caller do
    :noop
  end

  @dialyzer {:nowarn_function, display: 1}
  @compile {:inline, display: 1}
  @spec display(value :: any) :: {module, function, arity :: non_neg_integer} | :undefined
  @doc """
  Displays the given `value` on stdout for debugging purposes.

  Always returns `true`.
  """
  def display(value) do
    _ignore = value
    :noop
  end

  @dialyzer {:nowarn_function, get_tcw: 0}
  @compile {:inline, get_tcw: 0}
  @spec get_tcw :: trace_control_word when trace_control_word: non_neg_integer
  @doc """
  Returns the value of the current node's trace control word.

  Identical to calling `:erlang.system_info/1` with the argument `:trace_control_word`.

  The trace control word is a 32-bit unsigned integer intended for generic trace control.
  The trace control word can be tested and set both from within trace match specifications and with BIFs.
  """
  def get_tcw do
    :noop
  end

  @dialyzer {:nowarn_function, set_tcw: 1}
  @compile {:inline, set_tcw: 1}
  @spec set_tcw(trace_control_word) :: trace_control_word when trace_control_word: non_neg_integer
  @doc """
  Sets the value of the current node's trace control word to `trace_control_word`.

  Identical to calling `:erlang.system_flag/2` with the arguments `:trace_control_word` and `trace_control_word`.

  Returns the previous value of the node's trace control word.
  """
  def set_tcw(trace_control_word) do
    _ignore = trace_control_word
    :noop
  end

  @dialyzer {:nowarn_function, silent: 1}
  @compile {:inline, silent: 1}
  @spec silent(mode :: boolean | any) :: any
  @doc """
  Changes the verbosity of the current process's messaging `mode`.

  - If `mode` is `true`, supresses all trace messages.
  - If `mode` is `false`, re-enables trace messages in future calls.
  - If `mode` is anything else, the current mode remains active.
  """
  def silent(mode) do
    _ignore = mode
    :noop
  end

  ###
  # TRACE FLAG FUNCTIONS
  ##

  @type trace_flag ::
          :all
          | :send
          | :receive
          | :procs
          | :ports
          | :call
          | :arity
          | :return_to
          | :silent
          | :running
          | :exiting
          | :running_procs
          | :running_ports
          | :garbage_collection
          | :timestamp
          # | :cpu_timestamp
          | :monotonic_timestamp
          | :strict_monotonic_timestamp
          | :set_on_spawn
          | :set_on_first_spawn
          | :set_on_link
          | :set_on_first_link
  @type tracer_trace_flag ::
          {:tracer, pid | port}
          | {:tracer, module, any}

  @dialyzer {:nowarn_function, enable_trace: 1}
  @compile {:inline, enable_trace: 1}
  @spec enable_trace(trace_flag) :: true
  @doc """
  Turns on the provided `trace_flag` for the current process.

  See the third parameter `:erlang.trace/3` for a list of flags and their effects.
  Note that the `:cpu_timestamp` and `:tracer` flags are not supported in this function.

  Always returns `true`.
  """
  def enable_trace(trace_flag) do
    _ignore = trace_flag
    :noop
  end

  @dialyzer {:nowarn_function, enable_trace: 2}
  @compile {:inline, enable_trace: 2}
  @spec enable_trace(pid, trace_flag) :: non_neg_integer
  @doc """
  Turns on the provided `trace_flag` for the specified `pid`.

  See the third parameter `:erlang.trace/3` for a list of flags and their effects.
  Note that the `:cpu_timestamp` and `:tracer` flags are not supported in this function.

  Always returns `true`.
  """
  def enable_trace(pid, trace_flag) do
    _ignore = pid
    _ignore = trace_flag
    :noop
  end

  @dialyzer {:nowarn_function, disable_trace: 1}
  @compile {:inline, disable_trace: 1}
  @spec disable_trace(trace_flag) :: true
  @doc """
  Turns off the provided `trace_flag` for the current process.

  See the third parameter `:erlang.trace/3` for a list of flags and their effects.
  Note that the `:cpu_timestamp` and `:tracer` flags are not supported in this function.

  Always returns `true`.
  """
  def disable_trace(trace_flag) do
    _ignore = trace_flag
    :noop
  end

  @dialyzer {:nowarn_function, disable_trace: 2}
  @compile {:inline, disable_trace: 2}
  @spec disable_trace(pid, trace_flag) :: true
  @doc """
  Turns off the provided `trace_flag` for the specified `pid`.

  See the third parameter `:erlang.trace/3` for a list of flags and their effects.
  Note that the `:cpu_timestamp` and `:tracer` flags are not supported in this function.

  Always returns `true`.
  """
  def disable_trace(pid, trace_flag) do
    _ignore = pid
    _ignore = trace_flag
    :noop
  end

  @dialyzer {:nowarn_function, trace: 2}
  @compile {:inline, trace: 2}
  @spec trace(
          disable_flags :: [trace_flag | tracer_trace_flag],
          enable_flags :: [trace_flag | tracer_trace_flag]
        ) :: boolean
  @doc """
  Atomically disables and enables a set of trace flags for the current process in one go.

  Flags enabled in the `enable_flags` list will override duplicate flags in the `disable_flags` list.

  See the third parameter `:erlang.trace/3` for a list of flags and their effects.
  Note that the `:cpu_timestamp` flag is not supported in this function, however
  unlike the `enable_trace/1` and `disable_trace/1` functions, the `:tracer` flags are supported..

  If no `:tracer` is specified, the same tracer as the process executing the match specification is used (not the meta tracer).
  If that process doesn't have tracer either, then trace flags are ignored.
  When using a tracer module, the module must be loaded before the match specification is executed. If it is not loaded, the match fails.

  Returns `true` if any trace property was changed for the current process, otherwise `false`.
  """
  def trace(disable_flags, enable_flags) do
    _ignore = disable_flags
    _ignore = enable_flags
    :noop
  end

  @dialyzer {:nowarn_function, trace: 3}
  @compile {:inline, trace: 3}
  @spec trace(
          disable_flags :: [trace_flag | tracer_trace_flag],
          enable_flags :: [trace_flag | tracer_trace_flag]
        ) :: boolean
  @doc """
  Atomically disables and enables a set of trace flags for the given `pid` in one go.

  Flags enabled in the `enable_flags` list will override duplicate flags in the `disable_flags` list.

  See the third parameter `:erlang.trace/3` for a list of flags and their effects.
  Note that the `:cpu_timestamp` flag is not supported in this function, however
  unlike the `enable_trace/1` and `disable_trace/1` functions, the `:tracer` flags are supported..

  If no `:tracer` is specified, the same tracer as the process executing the match specification is used (not the meta tracer).
  If that process doesn't have tracer either, then trace flags are ignored.
  When using a tracer module, the module must be loaded before the match specification is executed. If it is not loaded, the match fails.

  Returns `true` if any trace property was changed for the given `pid`, otherwise `false`.
  """
  def trace(pid, disable_flags, enable_flags) do
    _ignore = pid
    _ignore = disable_flags
    _ignore = enable_flags
    :noop
  end

  ###
  # SEQUENTIAL TRACING FUNCTIONS
  ##

  @type seq_token :: {integer, boolean, any, any, any}
  @type seq_token_flag ::
          :send
          | :receive
          | :print
          | :timestamp
          | :monotonic_timestamp
          | :strict_monotonic_timestamp
  @type seq_token_component ::
          :label
          | :serial
          | seq_token_flag
  @type seq_token_label_value :: any
  @type seq_token_serial_number :: non_neg_integer
  @type seq_token_previous_serial_number :: seq_token_serial_number
  @type seq_token_current_serial_number :: seq_token_serial_number
  @type seq_token_serial_value ::
          {seq_token_previous_serial_number, seq_token_current_serial_number}
  @type seq_token_value :: seq_token_label_value | seq_token_serial_value | boolean

  @dialyzer {:nowarn_function, is_seq_trace: 0}
  @compile {:inline, is_seq_trace: 0}
  @spec is_seq_trace :: boolean
  @doc """
  Returns `true` if a sequential trace token is set for the current process, otherwise `false`.
  """
  def is_seq_trace do
    :noop
  end

  @dialyzer {:nowarn_function, set_seq_token: 2}
  @compile {:inline, set_seq_token: 2}
  @spec set_seq_token(seq_token_component, seq_token_value) :: true | charlist
  @doc """
  Sets a label, serial number, or flag `token` to `value` for sequential tracing.

  Acts like `:seq_trace.set_token/2`, except
  returns `true` on success, and `'EXIT'` on error or bad argument.

  Note that this function cannot be used to exclude message passing from the trace,
  since that is normally accomplished by passing `[]` into `:seq_trace.set_token/1`
  (however there is no `set_seq_token/1` allowed in match specs).

  Note that the values set here cannot be introspected in
  a match spec tracing context
  (`get_seq_token/0` returns an opaque representation of the current trace token,
  but there's no `get_seq_token/1` to inspect individual values).

  For more information, consult `:seq_trace.set_token/2` docs.
  """
  def set_seq_token(token, value) do
    _ignore = token
    _ignore = value
    :noop
  end

  @dialyzer {:nowarn_function, get_seq_token: 0}
  @compile {:inline, get_seq_token: 0}
  @spec get_seq_token :: seq_token | []
  @doc """
  Retreives the (opaque) value of the trace token for the current process.

  If the current process is not being traced, returns `[]`.

  Acts identically to `:seq_trace.get_token/0`. The docs say that the return value
  can be passed back into `:seq_trace.set_token/1`. However,
  in a tracing match spec context, there is no equivalent
  (`set_seq_token/2` works, but there's no `set_seq_token/1`).
  So I am unsure what this can be used for.

  For more information, consult `:seq_trace.get_token/0` docs.
  """
  def get_seq_token do
    :noop
  end
end
