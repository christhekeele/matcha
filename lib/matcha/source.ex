defmodule Matcha.Source do
  @moduledoc """
  Information about sources.
  """

  alias Matcha.Error

  @type type :: :table | :trace

  @type pattern :: tuple
  @type conditions :: [condition]
  @type condition :: expression
  @type body :: [expression]
  @type expression :: tuple
  @type clause :: {pattern, conditions, body}
  @type spec :: [clause]

  @type trace_flags :: list()

  @type test_target :: tuple() | list(tuple())
  @type test_result :: {:returned, any()} | {:traced, boolean | String.t(), trace_flags}

  @type compiled :: :ets.comp_match_spec()

  @spec compile(spec, type) :: {:ok, compiled} | {:error, Error.problems()}
  def compile(spec_source, type)

  def compile(_source, :trace) do
    {:error, [error: "cannot compile trace specs"]}
  end

  def compile(source, :table) do
    {:ok, :ets.match_spec_compile(source)}
  rescue
    error in ArgumentError ->
      {:error, [error: "error compiling table spec: " <> error.message]}
  end

  @spec run(compiled(), list()) :: list()
  def run(compiled, list) do
    :ets.match_spec_run(list, compiled)
  end

  @spec test(spec, type, test_target()) ::
          {:ok, test_target()} | {:error, Matcha.Error.problems()}
  def test(source, type, test_target)

  def test(source, :table, test_target) when is_tuple(test_target) do
    case do_erl_test(source, :table, test_target) do
      {:ok, result} -> {:ok, result}
      {:error, problems} -> {:error, problems}
    end
  end

  def test(_source, :table, test_target) do
    {:error,
     [
       error: "test targets for table specs must be a tuple, got: `#{inspect(test_target)}`"
     ]}
  end

  def test(source, :trace, test_target) when is_list(test_target) do
    case do_erl_test(source, :trace, test_target) do
      {:ok, result} -> {:ok, result}
      {:error, problems} -> {:error, problems}
    end
  end

  def test(_source, :trace, test_target) do
    {:error,
     [
       error: "test targets for trace specs must be a list, got: `#{inspect(test_target)}`"
     ]}
  end

  @spec do_erl_test(spec, type, test_target()) ::
          {:ok, test_target()} | {:error, Matcha.Error.problems()}
  defp do_erl_test(source, type, test)

  defp do_erl_test(source, :table, test) do
    case :erlang.match_spec_test(test, source, :table) do
      {:ok, result, [], _warnings} -> {:ok, {:returned, result}}
      {:error, problems} -> {:error, problems}
    end
  end

  defp do_erl_test(source, :trace, test) do
    case :erlang.match_spec_test(test, source, :trace) do
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
end
