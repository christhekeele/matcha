defmodule Matcha.Spec.Source do
  @type pattern :: tuple
  @type conditions :: [condition]
  @type condition :: expression
  @type body :: [expression]
  @type expression :: tuple
  @type clause :: {pattern, conditions, body}
  @type spec :: [clause]
  @type t :: spec

  def compile(_source, :trace) do
    {:error, [error: "cannot compile trace specs"]}
  end

  def compile(source, :table) do
    {:ok, :ets.match_spec_compile(source)}
  rescue
    error in ArgumentError ->
      {:error, [error: "error compiling table spec: " <> error.message]}
  end

  def test(source, :table, test) when is_tuple(test) do
    case do_erl_test(source, :table, test) do
      {:ok, result} -> {:ok, result}
      {:error, problems} -> {:error, problems}
    end
  end

  def test(_source, :table, test) do
    {:error, [error: "tests for table specs must be a tuple, got: `#{inspect(test)}`"]}
  end

  def test(source, :trace, test) when is_list(test) do
    case do_erl_test(source, :trace, test) do
      {:ok, result} -> {:ok, result}
      {:error, problems} -> {:error, problems}
    end
  end

  def test(_source, :trace, test) do
    {:error, [{:error, "tests for trace specs must be a list, got: `#{inspect(test)}`"}]}
  end

  defp do_erl_test(source, :table, test) do
    case :erlang.match_spec_test(test, source, :table) do
      {:ok, result, [], _warnings} -> {:ok, {:returned, result}}
      {:error, problems} -> {:error, problems}
    end
  end

  defp do_erl_test(source, :trace, test) do
    case :erlang.match_spec_test(test, source, :trace) do
      {:ok, result, flags, _warnings} ->
        {:ok, {:traced, result, flags}}

      {:error, problems} ->
        {errors, _warnings} = Keyword.split(problems, [:warnings])
        {:error, errors}
    end
  end

  # defp do_erl_test_warnings(warnings) do
  #   Logger.warn
  # end
end
