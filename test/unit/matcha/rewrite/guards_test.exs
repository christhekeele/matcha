defmodule Matcha.Rewrite.Guards.Test do
  @moduledoc false

  use ExUnit.Case, async: true
  doctest Matcha.Rewrite

  require Record
  Record.defrecordp(:user, [:name, :age])

  import TestGuards
  import TestHelpers

  import Matcha

  describe "guard logic" do
    test "boolean in guard" do
      spec =
        spec do
          _x when true -> 0
        end

      assert spec.source == [{:"$1", [true], [0]}]
    end

    test "not logic" do
      spec =
        spec do
          _x when not true -> 0
        end

      assert spec.source == [{:"$1", [not: true], [0]}]
    end

    test "and logic" do
      spec =
        spec do
          _x when true and false -> 0
        end

      assert spec.source == [{:"$1", [{:andalso, true, false}], [0]}]
    end

    test "or logic" do
      spec =
        spec do
          _x when true or false -> 0
        end

      assert spec.source == [{:"$1", [{:orelse, true, false}], [0]}]
    end
  end

  describe "predicate guards" do
    test "is_atom" do
      spec =
        spec do
          x when is_atom(x) -> x
        end

      assert spec.source == [{:"$1", [{:is_atom, :"$1"}], [:"$1"]}]
    end

    test "is_binary" do
      spec =
        spec do
          x when is_binary(x) -> x
        end

      assert spec.source == [{:"$1", [{:is_binary, :"$1"}], [:"$1"]}]
    end
  end

  describe "unallowed guards" do
    test "is_bitstring/1", test_context do
      assert_raise Matcha.Rewrite.Error, ~r|unsupported function call.*?is_bitstring/1|s, fn ->
        defmodule test_module_name(test_context) do
          import Matcha

          spec do
            x when is_bitstring(x) -> x
          end
        end
      end
    end
  end

  test "stdlib guard" do
    spec =
      spec do
        {x} when is_number(x) -> x
      end

    assert spec.source == [{{:"$1"}, [{:is_number, :"$1"}], [:"$1"]}]
  end

  test "multiple clauses" do
    spec =
      spec do
        _x -> 0
        y -> y
      end

    assert spec.source == [{:"$1", [], [0]}, {:"$1", [], [:"$1"]}]
  end

  test "multiple guard clauses" do
    spec =
      spec do
        x when x == 1 when x == 2 -> x
      end

    assert spec.source == [{:"$1", [{:==, :"$1", 1}, {:==, :"$1", 2}], [:"$1"]}]
  end

  test "custom guard macro" do
    spec =
      spec do
        x when custom_gt_3_neq_5_guard(x) -> x
      end

    assert spec.source == [{:"$1", [{:andalso, {:>, :"$1", 3}, {:"/=", :"$1", 5}}], [:"$1"]}]
  end

  test "nested custom guard macro" do
    spec =
      spec do
        x when nested_custom_gt_3_neq_5_guard(x) -> x
      end

    assert spec.source == [
             {
               :"$1",
               [
                 {
                   :andalso,
                   {:andalso, {:>, :"$1", 3}, {:"/=", :"$1", 5}},
                   {:andalso, {:>, {:+, :"$1", 1}, 3}, {:"/=", {:+, :"$1", 1}, 5}}
                 }
               ],
               [:"$1"]
             }
           ]
  end

  test "composite bound variables in guards" do
    bound = {1, 2, 3}

    spec =
      spec do
        arg when arg < bound -> arg
      end

    assert spec.source == [{:"$1", [{:<, :"$1", {:const, {1, 2, 3}}}], [:"$1"]}]
  end
end
