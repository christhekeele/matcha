defmodule Matcha.Source do
  @moduledoc """
  About sources.
  """

  alias Matcha.Error
  alias Matcha.Rewrite

  @match_all :"$_"
  @all_matches :"$$"

  @type context :: module()

  @type match_all :: unquote(@match_all)
  @type all_matches :: unquote(@all_matches)

  @type pattern :: tuple
  @type conditions :: [condition]
  @type condition :: expression
  @type body :: [expression] | any
  @type expression :: tuple | match_all | all_matches | any
  @type clause :: {pattern, conditions, body}
  @type spec :: [clause]

  @type erl_test_type :: :table | :trace

  @type trace_flags :: list()

  # TODO: docs say only the first two are allowed, but any term seems to work
  @type test_target :: tuple() | list(tuple()) | term()
  @type test_result :: {:returned, any()} | {:traced, boolean | String.t(), trace_flags} | any()

  @type compiled :: :ets.comp_match_spec()

  def match_all, do: @match_all
  def all_matches, do: @all_matches

  @spec compile(spec, context) :: {:ok, compiled} | {:error, Error.problems()}
  def compile(spec, context) do
    {:ok, :ets.match_spec_compile(spec)}
  rescue
    error in ArgumentError ->
      {:error, [error: "error compiling #{context.__context_name__()} spec: " <> error.message]}
  end

  @spec run(compiled(), list()) :: list()
  def run(compiled, list) do
    :ets.match_spec_run(list, compiled)
  end

  @spec test(spec, context, test_target()) ::
          {:ok, test_target()} | {:error, Matcha.Error.problems()}
  def test(source, context, test_target) do
    context = Rewrite.resolve_context(context)

    if context.__valid_test_target__(test_target) do
      do_erl_test(source, context, test_target)
    else
      {:error,
       [
         error: context.__invalid_test_target_error_message__(test_target)
       ]}
    end
  end

  @spec do_erl_test(spec(), context(), test_target()) ::
          {:ok, test_target()} | {:error, Matcha.Error.problems()}
  defp do_erl_test(source, context, test) do
    test
    |> :erlang.match_spec_test(source, context.__erl_test_type__())
    |> context.__handle_erl_test_results__()
  end
end
