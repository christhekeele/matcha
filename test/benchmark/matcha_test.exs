defmodule Matcha.BenchmarkTest do
  @moduledoc false

  use BenchmarkTest

  import TestHelpers

  require Matcha

  describe "Matcha.spec" do
    test "creation time", context do
      benchmark =
        Benchmark.new(benchmark_name(context), "./bench/matcha/spec_creation.html",
          measurements: %{
            tuple_pattern: fn ->
              Matcha.spec do
                {a, b} -> a + b
              end
            end,
            list_pattern: fn ->
              Matcha.spec do
                [h | t] -> h + t
              end
            end
          }
        )

      results = Benchmark.run(benchmark)

      # Specs are usually created at compile-time.
      # While they do a bit of lifting and checking,
      #  they should never add more than 10 milliseconds per spec
      #  to the user's compilation time.
      # 10 ms is also more than reasonable for runtime usage.
      assert results.tuple_pattern.average_microseconds <= 10_000
      assert results.list_pattern.average_microseconds <= 10_000
    end
  end
end
