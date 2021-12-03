defmodule Matcha.Source do
  @moduledoc """
  About sources.
  """

  alias Matcha.Error

  @type context :: module()

  @type pattern :: tuple
  @type conditions :: [condition]
  @type condition :: expression
  @type body :: [expression]
  @type expression :: tuple
  @type clause :: {pattern, conditions, body}
  @type spec :: [clause]

  @type erl_test_type :: :table | :trace

  @type trace_flags :: list()

  # TODO: docs say only the first two are allowed, but any term seems to work
  @type test_target :: tuple() | list(tuple()) | term()
  @type test_result :: {:returned, any()} | {:traced, boolean | String.t(), trace_flags} | any()

  @type compiled :: :ets.comp_match_spec()

  @spec compile(spec, context) :: {:ok, compiled} | {:error, Error.problems()}
  def compile(spec, context) do
    {:ok, :ets.match_spec_compile(spec)}
  rescue
    error in ArgumentError ->
      {:error, [error: "error compiling #{context.__name__()} spec: " <> error.message]}
  end

  @spec run(compiled(), list()) :: list()
  def run(compiled, list) do
    :ets.match_spec_run(list, compiled)
  end

  @spec test(spec, context, test_target()) ::
          {:ok, test_target()} | {:error, Matcha.Error.problems()}
  def test(source, context, test_target) do
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
