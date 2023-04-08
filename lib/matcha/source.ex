defmodule Matcha.Source do
  @moduledoc """
  Functions that work with the raw Erlang terms representing a match spec.

  The "source" of a match specification is what Matcha calls data that fits the Erlang
  [match specification](https://www.erlang.org/doc/apps/erts/match_spec.html) grammar.

  Matcha compiles Elixir code into such data, and wraps that data in structs.
  This module is the bridge between those structs and the Erlang functions that
  know how to operate on them.
  """

  @match_all :"$_"
  @all_matches :"$$"

  @type match_all :: unquote(@match_all)
  @type all_matches :: unquote(@all_matches)

  @type pattern :: tuple | atom
  @type conditions :: [condition]
  @type condition :: expression
  @type body :: [expression] | any
  @type expression :: tuple | match_all | all_matches | any
  @type clause :: {pattern, conditions, body}
  @type spec :: [clause]
  @type uncompiled :: spec

  @type type :: :table | :trace

  @type trace_flags :: list()
  @type trace_message :: charlist()

  @type match_target :: tuple() | list(tuple()) | term()
  @type match_result ::
          {:ok, any, trace_flags, [{:error | :warning, charlist}]}
          | {:error, [{:error | :warning, charlist}]}

  @type table_match_result ::
          {:ok, any, [], [{:error | :warning, charlist}]}
          | {:error, [{:error | :warning, charlist}]}
  @type trace_match_result ::
          {:ok, boolean | trace_message, trace_flags, [{:error | :warning, charlist}]}
          | {:error, [{:error | :warning, charlist}]}

  @type compiled :: :ets.comp_match_spec()

  @compile {:inline, __match_all__: 0, __all_matches__: 0}
  def __match_all__, do: @match_all
  def __all_matches__, do: @all_matches

  @spec compile(source :: uncompiled) :: compiled
  @doc """
  Compiles match spec `source` into an opaque, more efficient internal representation.
  """
  def compile(source) do
    :ets.match_spec_compile(source)
  end

  @spec compiled?(any) :: boolean
  @doc """
  Checks if provided `value` is a compiled match spec source.
  """
  def compiled?(value) do
    :ets.is_compiled_ms(value)
  end

  @spec ensure_compiled(source :: uncompiled | compiled) :: compiled
  @doc """
  Ensures provided match spec `source` is compiled.
  """
  def ensure_compiled(source) do
    if :ets.is_compiled_ms(source) do
      source
    else
      compile(source)
    end
  end

  @spec run(source :: uncompiled | compiled, list) :: list
  @doc """
  Runs a match spec `source` against a list of values.
  """
  def run(source, list) do
    if compiled?(source) do
      :ets.match_spec_run(list, source)
    else
      :ets.match_spec_run(list, compile(source))
    end
  end

  @spec test(source :: uncompiled, type, match_target) :: match_result
  @doc """
  Validates match spec `source` of variant `type` and tries to match it against `match_target`.
  """
  def test(source, type, match_target) do
    :erlang.match_spec_test(match_target, source, type)
  end
end
