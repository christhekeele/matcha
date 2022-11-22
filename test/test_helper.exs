suites = [:benchmark, :doctest, :unit, :usage]
# The test suite to run is re-includeded via CLI flag
ExUnit.start(exclude: [:skip | suites])

defmodule TestGuards do
  defmacro custom_gt_3_neq_5_guard(x) do
    quote do
      unquote(x) > 3 and unquote(x) != 5
    end
  end

  defmacro nested_custom_gt_3_neq_5_guard(x) do
    quote do
      custom_gt_3_neq_5_guard(unquote(x)) and custom_gt_3_neq_5_guard(unquote(x) + 1)
    end
  end
end

defmodule Benchmark.Result do
  defstruct [:average_microseconds]

  def new(scenario = %Benchee.Scenario{}) do
    %__MODULE__{
      average_microseconds: scenario.run_time_data.statistics.average
    }
  end
end

defmodule Benchmark do
  defstruct [:name, :report, measurements: %{}, inputs: nil]

  def new(name, report, opts \\ []) do
    %__MODULE__{
      name: name,
      report: report,
      measurements: Keyword.fetch!(opts, :measurements),
      inputs: Keyword.get(opts, :inputs)
    }
  end

  def run(benchmark = %__MODULE__{}) do
    IO.puts("Starting benchmark #{benchmark.name}...")

    suite =
      if benchmark.inputs do
        Benchee.run(benchmark.measurements,
          formatters: [
            {Benchee.Formatters.HTML, file: benchmark.report, auto_open: false},
            Benchee.Formatters.Console
          ],
          inputs: benchmark.inputs,
          reduction_time: 1
        )
      else
        Benchee.run(benchmark.measurements,
          formatters: [
            {Benchee.Formatters.HTML, file: benchmark.report, auto_open: false},
            Benchee.Formatters.Console
          ],
          reduction_time: 1
        )
      end

    IO.puts("Benchmark concluded.")

    for scenario <- suite.scenarios,
        into: %{},
        do: {String.to_atom(scenario.name), Benchmark.Result.new(scenario)}
  end
end

defmodule BenchmarkTest do
  defmacro __using__(_opts \\ []) do
    quote do
      use ExUnit.Case, async: false
      @moduletag :benchmark
      @moduletag timeout: :infinity
    end
  end
end

defmodule DocTest do
  defmacro __using__(_opts \\ []) do
    quote do
      use ExUnit.Case, async: false
      @moduletag :doctest
    end
  end
end

defmodule UnitTest do
  defmacro __using__(_opts \\ []) do
    quote do
      use ExUnit.Case, async: false
      @moduletag :unit
    end
  end
end

defmodule UsageTest do
  defmacro __using__(_opts \\ []) do
    quote do
      use ExUnit.Case, async: false
      @moduletag :usage
    end
  end
end

defmodule TestHelpers do
  def benchmark_name(%{case: test_case, describe: describe, test: test}, description \\ nil) do
    benchmark_name = [Benchmark, test_case]

    benchmark_name =
      if describe do
        benchmark_name ++ [describe |> String.replace(~r/[^\w]/, "_")]
      else
        benchmark_name
      end

    benchmark_name =
      benchmark_name ++ [test |> Atom.to_string() |> String.replace(~r/[^\w]/, "_")]

    benchmark_name =
      if description do
        benchmark_name ++ [description |> String.replace(~r/[^\w]/, "_")]
      else
        benchmark_name
      end

    benchmark_name |> Enum.join("-")
  end

  def test_module_name(
        %{case: test_case, describe: describe, test: test},
        description \\ nil
      ) do
    module_name = [Test, test_case]

    module_name =
      if describe do
        module_name ++ [describe |> String.replace(~r/[^\w]/, "_")]
      else
        module_name
      end

    module_name = module_name ++ [test |> Atom.to_string() |> String.replace(~r/[^\w]/, "_")]

    module_name =
      if description do
        module_name ++ [description |> String.replace(~r/[^\w]/, "_")]
      else
        module_name
      end

    Module.concat(module_name)
  end

  def module_importable_functions(module) do
    module.__info__(:functions)
    |> Enum.reject(fn {function, _arity} ->
      function |> Atom.to_string() |> String.starts_with?("_")
    end)
  end
end
