defmodule Matcha.Trace do
  @moduledoc """
  About tracing.
  """

  require Matcha

  @default_trace_limit 1

  @doc """
  Trace all calls to a `module`.
  """
  def module(module, opts \\ [])
      when is_atom(module) and is_list(opts) do
    limit = Keyword.get(opts, :limit, @default_trace_limit)
    :recon_trace.calls({module, :_, :_}, limit)
  end

  @doc """
  Trace all `function` calls to a `module`.
  """
  def function(module, function)
      when is_atom(module) and is_atom(function) do
    do_function(module, function, :_, [])
  end

  @doc """
  Trace all `function` calls to `module` with given `arity`.

  `arity` may be `:_`, in which case all arities will be traced.
  """
  def function(module, function, arity)
      when is_atom(module) and is_atom(function) and is_integer(arity) and arity >= 0 do
    do_function(module, function, arity, [])
  end

  @doc """
  Trace all `function` calls to `module` with given `arity` using provided `opts`.

  `arity` may be `:_`, in which case all arities will be traced.
  """
  def function(module, function, arity, opts)
      when is_atom(module) and is_atom(function) and is_integer(arity) and arity >= 0 and
             is_list(opts) do
    do_function(module, function, arity, opts)
  end

  defp do_function(module, function, arity, opts)
       when is_atom(module) and is_atom(function) and
              ((is_integer(arity) and arity >= 0) or arity == :_) and
              is_list(opts) do
    limit = Keyword.get(opts, :limit, @default_trace_limit)
    :recon_trace.calls({module, function, arity}, limit)
  end

  # defmacro calls(module, function, opts \\ [], code)
  #          when is_atom(module) and is_atom(function) and is_list(opts) do
  #   limit = Keyword.get(opts, :limit, @default_trace_limit)
  #   spec = Matcha.spec(:trace, code)

  #   quote do
  #     :recon_trace.calls({module, function, unquotespec}, limit)
  #   end
  # end
end
