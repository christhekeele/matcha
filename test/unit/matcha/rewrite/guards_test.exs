defmodule Matcha.Rewrite.Guards.UnitTest do
  @moduledoc """
  """

  use ExUnit.Case, async: true
  doctest Matcha.Rewrite

  require Record
  Record.defrecordp(:user, [:name, :age])

  import TestGuards
  import TestHelpers

  import Matcha

  describe "literals" do
    test "boolean in guard" do
      spec =
        spec do
          _x when true -> 0
        end

      assert spec.source == [{:"$1", [true], [0]}]
    end

    test "atom in guard" do
      spec =
        spec do
          _x when :foo -> 0
        end

      assert spec.source == [{:"$1", [:foo], [0]}]
    end

    test "number in guard" do
      spec =
        spec do
          _x when 1 -> 0
        end

      assert spec.source == [{:"$1", [1], [0]}]
    end

    test "float in guard" do
      spec =
        spec do
          _x when 1.0 -> 0
        end

      assert spec.source == [{:"$1", [1.0], [0]}]
    end
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

  describe "invalid calls in guards" do
    test "local calls", context do
      assert_raise CompileError, ~r"undefined function meant_to_not_exist/0", fn ->
        defmodule test_module_name(context) do
          import Matcha

          spec do
            x when meant_to_not_exist() -> x
          end
        end
      end
    end

    test "remote calls", context do
      assert_raise CompileError, ~r"cannot invoke remote function.*?inside guards", fn ->
        defmodule test_module_name(context) do
          import Matcha

          spec do
            x when Module.meant_to_not_exist() -> x
          end
        end
      end
    end
  end

  describe "stlib guards" do
    test "-/1" do
      spec =
        spec do
          x when x == -1 -> x
        end

      assert spec.source == [{:"$1", [{:==, :"$1", {:-, 1}}], [:"$1"]}]
    end

    test "-/2" do
      spec =
        spec do
          x when x - 1 == 0 -> x
        end

      assert spec.source == [{:"$1", [{:==, {:-, :"$1", 1}, 0}], [:"$1"]}]
    end

    test "!=/2" do
      spec =
        spec do
          x when x != 1.0 -> x
        end

      assert spec.source == [{:"$1", [{:"/=", :"$1", 1.0}], [:"$1"]}]
    end

    test "!==/2" do
      spec =
        spec do
          x when x !== 1.0 -> x
        end

      assert spec.source == [{:"$1", [{:"=/=", :"$1", 1.0}], [:"$1"]}]
    end

    test "*/2" do
      spec =
        spec do
          x when x * 2 == 4 -> x
        end

      assert spec.source == [{:"$1", [{:==, {:*, :"$1", 2}, 4}], [:"$1"]}]
    end

    test "//2" do
      spec =
        spec do
          x when x / 2 == 4 -> x
        end

      assert spec.source == [{:"$1", [{:==, {:/, :"$1", 2}, 4}], [:"$1"]}]
    end

    test "+/1" do
      spec =
        spec do
          x when x == +1 -> x
        end

      assert spec.source == [{:"$1", [{:==, :"$1", {:+, 1}}], [:"$1"]}]
    end

    test "+/2" do
      spec =
        spec do
          x when x + 2 == 4 -> x
        end

      assert spec.source == [{:"$1", [{:==, {:+, :"$1", 2}, 4}], [:"$1"]}]
    end

    test "</2" do
      spec =
        spec do
          x when x < 2 -> x
        end

      assert spec.source == [{:"$1", [{:<, :"$1", 2}], [:"$1"]}]
    end

    test "<=/2" do
      spec =
        spec do
          x when x <= 2 -> x
        end

      assert spec.source == [{:"$1", [{:"=<", :"$1", 2}], [:"$1"]}]
    end

    test "==/2" do
      spec =
        spec do
          x when x == 1.0 -> x
        end

      assert spec.source == [{:"$1", [{:==, :"$1", 1.0}], [:"$1"]}]
    end

    test "===/2" do
      spec =
        spec do
          x when x === 1.0 -> x
        end

      assert spec.source == [{:"$1", [{:"=:=", :"$1", 1.0}], [:"$1"]}]
    end

    test ">/2" do
      spec =
        spec do
          x when x > 2 -> x
        end

      assert spec.source == [{:"$1", [{:>, :"$1", 2}], [:"$1"]}]
    end

    test ">=/2" do
      spec =
        spec do
          x when x >= 2 -> x
        end

      assert spec.source == [{:"$1", [{:>=, :"$1", 2}], [:"$1"]}]
    end

    test "abs/1" do
      spec =
        spec do
          x when abs(x) == 1 -> x
        end

      assert spec.source == [{:"$1", [{:==, {:abs, :"$1"}, 1}], [:"$1"]}]
    end

    test "and/2" do
      spec =
        spec do
          _x when true and false -> 0
        end

      assert spec.source == [{:"$1", [{:andalso, true, false}], [0]}]

      spec =
        spec do
          {x, y} when x and y -> {x, y}
        end

      assert spec.source == [{{:"$1", :"$2"}, [{:andalso, :"$1", :"$2"}], [{{:"$1", :"$2"}}]}]
    end

    # TODO: figure out binary_part/3
    # @tag :skip
    # test "binary_part/3" do
    #   spec =
    #     spec do
    #       x when binary_part("abc", 1, 2) == "bc" -> x
    #     end

    #   assert spec.source == [{:"$1", [{:binary_part, "abc", 1, 2}], [:"$1"]}]

    #   spec =
    #     spec do
    #       string when binary_part(string, 1, 2) == "bc" -> string
    #     end

    #   assert spec.source == [{:"$1", [{:==, {:binary_part, :"$1", 1, 2}, "bc"}], [:"$1"]}]
    # end

    test "bit_size/1" do
      spec =
        spec do
          x when bit_size("abc") == 24 -> x
        end

      assert spec.source == [{:"$1", [{:==, {:bit_size, "abc"}, 24}], [:"$1"]}]

      spec =
        spec do
          string when bit_size(string) == 24 -> string
        end

      assert spec.source == [{:"$1", [{:==, {:bit_size, :"$1"}, 24}], [:"$1"]}]
    end

    # TODO: figure out byte_size/1
    # @tag :skip
    # test "byte_size/1" do
    #   spec =
    #     spec do
    #       x when byte_size("abc") == 3 -> x
    #     end

    #   assert spec.source == [{:"$1", [{:==, {:byte_size, "abc"}, 3}], [:"$1"]}]

    #   spec =
    #     spec do
    #       string when byte_size(string) == 3 -> string
    #     end

    #   assert spec.source == [{:"$1", [{:==, {:byte_size, :"$1"}, 3}], [:"$1"]}]
    # end

    test "div/2" do
      spec =
        spec do
          x when div(8, 2) == 4 -> x
        end

      assert spec.source == [{:"$1", [{:==, {:div, 8, 2}, 4}], [:"$1"]}]

      spec =
        spec do
          x when div(x, 2) == 4 -> x
        end

      assert spec.source == [{:"$1", [{:==, {:div, :"$1", 2}, 4}], [:"$1"]}]
    end

    test "elem/2" do
      spec =
        spec do
          x when elem({:one}, 0) == :one -> x
        end

      assert spec.source == [{:"$1", [{:==, {:element, 1, {{:one}}}, :one}], [:"$1"]}]

      spec =
        spec do
          x when elem(x, 0) == :one -> x
        end

      assert spec.source == [{:"$1", [{:==, {:element, 1, :"$1"}, :one}], [:"$1"]}]
    end

    test "hd/1" do
      spec =
        spec do
          x when hd([:one]) == :one -> x
        end

      assert spec.source == [{:"$1", [{:==, {:hd, [:one]}, :one}], [:"$1"]}]

      spec =
        spec do
          x when hd(x) == :one -> x
        end

      assert spec.source == [{:"$1", [{:==, {:hd, :"$1"}, :one}], [:"$1"]}]
    end

    test "in/2 with compile-time list" do
      spec =
        spec do
          x when x in [:one, :two, :three] -> x
        end

      assert spec.source == [
               {:"$1",
                [
                  {:orelse, {:orelse, {:"=:=", :"$1", :one}, {:"=:=", :"$1", :two}},
                   {:"=:=", :"$1", :three}}
                ], [:"$1"]}
             ]

      spec =
        spec do
          x when x in 1..3 -> x
        end

      assert spec.source == [
               {:"$1",
                [
                  {:andalso, {:is_integer, :"$1"}, {:andalso, {:>=, :"$1", 1}, {:"=<", :"$1", 3}}}
                ], [:"$1"]}
             ]

      spec =
        spec do
          x when x in ?a..?z -> x
        end

      assert spec.source == [
               {:"$1",
                [
                  {:andalso, {:is_integer, :"$1"},
                   {:andalso, {:>=, :"$1", 97}, {:"=<", :"$1", 122}}}
                ], [:"$1"]}
             ]
    end

    test "in/2 with dynamic list", test_context do
      assert_raise ArgumentError, ~r"for operator \"in\"", fn ->
        defmodule test_module_name(test_context) do
          import Matcha

          spec do
            x when 1 in x -> x
          end
        end
      end
    end

    test "is_atom/1" do
      spec =
        spec do
          x when is_atom(x) -> x
        end

      assert spec.source == [{:"$1", [{:is_atom, :"$1"}], [:"$1"]}]
    end

    test "is_binary/1" do
      spec =
        spec do
          x when is_binary(x) -> x
        end

      assert spec.source == [{:"$1", [{:is_binary, :"$1"}], [:"$1"]}]
    end

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

    test "stdlib guard" do
      spec =
        spec do
          {x} when is_number(x) -> x
        end

      assert spec.source == [{{:"$1"}, [{:is_number, :"$1"}], [:"$1"]}]
    end

    test "not/1" do
      spec =
        spec do
          _x when not true -> 0
        end

      assert spec.source == [{:"$1", [not: true], [0]}]
    end

    test "or/2" do
      spec =
        spec do
          _x when true or false -> 0
        end

      assert spec.source == [{:"$1", [{:orelse, true, false}], [0]}]
    end
  end
end
