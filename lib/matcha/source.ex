defmodule Matcha.Source do
  @moduledoc """
  Functions that work with the raw erlang terms representing a match spec.

  The "source" of a match specification is what Matcha calls data that fits the erlang
  [match specification](https://www.erlang.org/doc/apps/erts/match_spec.html) grammar.

  Matcha compiles Elixir code into such data, and wraps that data in structs.
  This module is the bridge between those structs and the erlang functions that
  know how to operate on them.
  """

  @match_all :"$_"
  @all_matches :"$$"

  @type match_all :: unquote(@match_all)
  @type all_matches :: unquote(@all_matches)

  @type pattern :: tuple
  @type conditions :: [condition]
  @type condition :: expression
  @type body :: [expression] | any
  @type expression :: tuple | match_all | all_matches | any
  @type clause :: {pattern, conditions, body}
  @type source :: [clause]

  @type type :: :table | :trace

  @type trace_flags :: list()
  @type trace_message :: charlist()

  @type test_target :: tuple() | list(tuple()) | term()
  @type test_result ::
          {:ok, any, trace_flags, [{:error | :warning, charlist}]}
          | {:error, [{:error | :warning, charlist}]}

  @type table_test_result ::
          {:ok, any, [], [{:error | :warning, charlist}]}
          | {:error, [{:error | :warning, charlist}]}
  @type trace_test_result ::
          {:ok, boolean | trace_message, trace_flags, [{:error | :warning, charlist}]}
          | {:error, [{:error | :warning, charlist}]}

  @type compiled :: :ets.comp_match_spec()

  def match_all, do: @match_all
  def all_matches, do: @all_matches

  @spec compile(source) :: compiled | no_return
  @doc """
  Compiles matchspec `source` into an opaque internal representation.
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

  @spec run(source, list) :: list
  @doc """
  Runs a match spec `source` against a list of values.
  """
  def run(source, list) do
    :ets.match_spec_run(list, compile(source))
  end

  @spec test(source, type, test_target) :: test_result
  @doc """
  Checks if a match spec `source` is valid, and returns if it matches the `test_target`.
  """
  def test(source, type, test_target) do
    :erlang.match_spec_test(test_target, source, type)
  end
end
