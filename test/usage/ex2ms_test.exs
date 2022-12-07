defmodule Ex2ms.UsageTest do
  @moduledoc """
  Use-case test suite derived from ex2ms (https://github.com/ericmj/ex2ms).

  Tests here are ex2ms tests that don't have equivalents elsewhere in the test suite.
  """

  use UsageTest

  import Matcha

  describe "gproc usage" do
    test "basic" do
      spec =
        spec(:table) do
          {{:n, :l, {:client, id}}, pid, _} -> {id, pid}
        end

      assert spec.source == [{{{:n, :l, {:client, :"$1"}}, :"$2", :_}, [], [{{:"$1", :"$2"}}]}]
    end

    test "with bound variables" do
      id = 5

      spec =
        spec(:table) do
          {{:n, :l, {:client, ^id}}, pid, _} -> pid
        end

      assert spec.source == [{{{:n, :l, {:client, 5}}, :"$1", :_}, [], [:"$1"]}]
    end

    test "with 3 variables" do
      spec =
        spec(:table) do
          {{:n, :l, {:client, id}}, pid, third} -> {id, pid, third}
        end

      assert spec.source == [
               {{{:n, :l, {:client, :"$1"}}, :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}
             ]
    end

    test "with 1 variable and 2 bound variables" do
      one = 11
      two = 22

      spec =
        spec(:table) do
          {{:n, :l, {:client, ^one}}, pid, ^two} -> {one, pid}
        end

      self_pid = self()

      assert spec.source == [
               {{{:n, :l, {:client, 11}}, :"$1", 22}, [], [{{{:const, 11}, :"$1"}}]}
             ]

      assert {:ok, {one, self_pid}} ===
               :ets.test_ms({{:n, :l, {:client, 11}}, self_pid, two}, spec.source)
    end
  end
end
