defmodule Matcha.Context.Trace do
  @moduledoc """
  Functions and operators that `:trace` matchspecs can use in their bodies.

  Tracing matchspecs offer a wide suite of instructions to drive erlang's tracing engine
  in response to matching certain calls.

  #### Sequential Tracing
  erlang [sequential tracing docs](https://www.erlang.org/doc/man/seq_trace.html#whatis)
  """

  alias Matcha.Context

  @behaviour Context

  ####
  # CALLBACKS
  ##

  @impl Context
  def __context_name__ do
    :trace
  end

  @impl Context
  def __erl_test_type__ do
    :trace
  end

  @impl Context
  def __default_test_target__ do
    []
  end

  @impl Context
  def __valid_test_target__(test_target) do
    is_list(test_target)
  end

  @impl Context
  def __invalid_test_target_error_message__(test_target) do
    "test targets for trace specs must be a list, got: `#{inspect(test_target)}`"
  end

  @impl Context
  def __handle_erl_test_results__(return) do
    case return do
      {:ok, result, flags, _warnings} ->
        result =
          if is_list(result) do
            List.to_string(result)
          else
            result
          end

        {:ok, {:traced, result, flags}}

      {:error, problems} ->
        {errors, _warnings} = Keyword.split(problems, [:warnings])
        {:error, Matcha.Rewrite.problems(errors)}
    end
  end

  ####
  # SUPPORTED FUNCTIONS
  ##

  def return_trace do
    :noop
  end

  def message(_) do
    :noop
  end

  def caller do
    :noop
  end

  def set_seq_token(component, val) do
    :seq_trace.set_token(component, val)
  end

  #   is_seq_trace
  # Returns true if a sequential trace token is set for the current process, otherwise false.

  # set_seq_token
  # Works as seq_trace:set_token/2, but returns true on success, and 'EXIT' on error or bad argument. Only allowed in the MatchBody part and only allowed when tracing.

  # get_seq_token
  # Same as seq_trace:get_token/0 and only allowed in the MatchBody part when tracing.

  # message
  # Sets an additional message appended to the trace message sent. One can only set one additional message in the body. Later calls replace the appended message.

  # As a special case, {message, false} disables sending of trace messages ('call' and 'return_to') for this function call, just like if the match specification had not matched. This can be useful if only the side effects of the MatchBody part are desired.

  # Another special case is {message, true}, which sets the default behavior, as if the function had no match specification; trace message is sent with no extra information (if no other calls to message are placed before {message, true}, it is in fact a "noop").

  # Takes one argument: the message. Returns true and can only be used in the MatchBody part and when tracing.

  # return_trace
  # Causes a return_from trace message to be sent upon return from the current function. Takes no arguments, returns true and can only be used in the MatchBody part when tracing. If the process trace flag silent is active, the return_from trace message is inhibited.

  # Warning: If the traced function is tail-recursive, this match specification function destroys that property. Hence, if a match specification executing this function is used on a perpetual server process, it can only be active for a limited period of time, or the emulator will eventually use all memory in the host machine and crash. If this match specification function is inhibited using process trace flag silent, tail-recursiveness still remains.

  # exception_trace
  # Works as return_trace plus; if the traced function exits because of an exception, an exception_from trace message is generated, regardless of the exception is caught or not.

  # process_dump
  # Returns some textual information about the current process as a binary. Takes no arguments and is only allowed in the MatchBody part when tracing.

  # enable_trace
  # With one parameter this function turns on tracing like the Erlang call erlang:trace(self(), true, [P2]), where P2 is the parameter to enable_trace.

  # With two parameters, the first parameter is to be either a process identifier or the registered name of a process. In this case tracing is turned on for the designated process in the same way as in the Erlang call erlang:trace(P1, true, [P2]), where P1 is the first and P2 is the second argument. The process P1 gets its trace messages sent to the same tracer as the process executing the statement uses. P1 cannot be one of the atoms all, new or existing (unless they are registered names). P2 cannot be cpu_timestamp or tracer.

  # Returns true and can only be used in the MatchBody part when tracing.

  # disable_trace
  # With one parameter this function disables tracing like the Erlang call erlang:trace(self(), false, [P2]), where P2 is the parameter to disable_trace.

  # With two parameters this function works as the Erlang call erlang:trace(P1, false, [P2]), where P1 can be either a process identifier or a registered name and is specified as the first argument to the match specification function. P2 cannot be cpu_timestamp or tracer.

  # Returns true and can only be used in the MatchBody part when tracing.

  # trace
  # With two parameters this function takes a list of trace flags to disable as first parameter and a list of trace flags to enable as second parameter. Logically, the disable list is applied first, but effectively all changes are applied atomically. The trace flags are the same as for erlang:trace/3, not including cpu_timestamp, but including tracer.

  # If a tracer is specified in both lists, the tracer in the enable list takes precedence. If no tracer is specified, the same tracer as the process executing the match specification is used (not the meta tracer). If that process doesn't have tracer either, then trace flags are ignored.

  # When using a tracer module, the module must be loaded before the match specification is executed. If it is not loaded, the match fails.

  # With three parameters to this function, the first is either a process identifier or the registered name of a process to set trace flags on, the second is the disable list, and the third is the enable list.

  # Returns true if any trace property was changed for the trace target process, otherwise false. Can only be used in the MatchBody part when tracing.

  # caller
  # Returns the calling function as a tuple {Module, Function, Arity} or the atom undefined if the calling function cannot be determined. Can only be used in the MatchBody part when tracing.

  # Notice that if a "technically built in function" (that is, a function not written in Erlang) is traced, the caller function sometimes returns the atom undefined. The calling Erlang function is not available during such calls.

  # display
  # For debugging purposes only. Displays the single argument as an Erlang term on stdout, which is seldom what is wanted. Returns true and can only be used in the MatchBody part when tracing.

  # get_tcw
  # Takes no argument and returns the value of the node's trace control word. The same is done by erlang:system_info(trace_control_word).

  # The trace control word is a 32-bit unsigned integer intended for generic trace control. The trace control word can be tested and set both from within trace match specifications and with BIFs. This call is only allowed when tracing.

  # set_tcw
  # Takes one unsigned integer argument, sets the value of the node's trace control word to the value of the argument, and returns the previous value. The same is done by erlang:system_flag(trace_control_word, Value). It is only allowed to use set_tcw in the MatchBody part when tracing.

  # silent
  # Takes one argument. If the argument is true, the call trace message mode for the current process is set to silent for this call and all later calls, that is, call trace messages are inhibited even if {message, true} is called in the MatchBody part for a traced function.

  # This mode can also be activated with flag silent to erlang:trace/3.

  # If the argument is false, the call trace message mode for the current process is set to normal (non-silent) for this call and all later calls.

  # If the argument is not true or false, the call trace message mode is unaffected.
end
