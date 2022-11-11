defmodule BenchmarkUnitTest do
  use ExUnit.Case
  alias Application.TestHelper
  require Matcha

  @scenario_data_member 0
  @expected_max_average 50_000_000

  @tag :benchmark
  test "benchmark tuple pattern" do
    output =
      Benchee.run(%{
        "tuple_pattern" => fn ->
          _tuple_pattern =
            Matcha.spec do
              {a, b} -> a + b
            end
        end
      })

    results = Enum.at(output.scenarios, @scenario_data_member)
    assert results.run_time_data.statistics.average <= @expected_max_average
  end

  @tag :benchmark
  test "benchmark list pattern" do
    output =
      Benchee.run(%{
        "list_pattern" => fn ->
          _list_pattern =
            Matcha.spec do
              [h | t] -> h + t
            end
        end
      })

    results = Enum.at(output.scenarios, @scenario_data_member)
    assert results.run_time_data.statistics.average <= @expected_max_average
  end

  @tag :benchmark
  test "benchmark list of tuples" do
    output =
      Benchee.run(%{
        "list_of_tuples" => fn ->
          _list_of_tuples =
            Matcha.spec do
              [{a, b}, {c, d}] -> a * c + b * d
            end
        end
      })

    results = Enum.at(output.scenarios, @scenario_data_member)
    assert results.run_time_data.statistics.average <= @expected_max_average
  end
end
