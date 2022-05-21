defmodule StdlibGuards.UsageTest do
  @moduledoc false

  use ExUnit.Case, async: true

  import Matcha

  import TestHelpers

  alias Matcha.Spec

  test "-/1" do
    spec =
      spec do
        x when x == -1 -> x
      end

    assert Spec.call!(spec, -1) == -1
    assert Spec.call!(spec, 1) == nil
    assert Spec.run!(spec, [-1, 1]) == [-1]

    spec =
      spec do
        x -> -x
      end

    assert Spec.call!(spec, -1) == 1
    assert Spec.call!(spec, 1) == -1
    assert Spec.run!(spec, [-1, 1]) == [1, -1]
  end

  test "-/2" do
    spec =
      spec do
        x when x - 1 == 0 -> x
      end

    assert Spec.call!(spec, 1) == 1
    assert Spec.call!(spec, -1) == nil
    assert Spec.run!(spec, [1, -1]) == [1]

    spec =
      spec do
        x -> x - 1
      end

    assert Spec.call!(spec, 1) == 0
    assert Spec.call!(spec, 0) == -1
    assert Spec.run!(spec, [1, 0]) == [0, -1]
  end

  test "!=/2" do
    spec =
      spec do
        x when x != 1.0 -> x
      end

    assert Spec.call!(spec, 1.0) == nil
    assert Spec.call!(spec, 1) == nil
    assert Spec.call!(spec, 2.0) == 2.0
    assert Spec.call!(spec, 2) == 2
    assert Spec.run!(spec, [1, 1.0, 2, 2.0]) == [2, 2.0]

    spec =
      spec do
        x -> x != 1.0
      end

    assert Spec.call!(spec, 1) == false
    assert Spec.call!(spec, 1.0) == false
    assert Spec.call!(spec, 2) == true
    assert Spec.call!(spec, 2.0) == true
    assert Spec.run!(spec, [1, 1.0, 2, 2.0]) == [false, false, true, true]
  end

  test "!==/2" do
    spec =
      spec do
        x when x !== 1.0 -> x
      end

    assert Spec.call!(spec, 1) == 1
    assert Spec.call!(spec, 1.0) == nil
    assert Spec.call!(spec, 2) == 2
    assert Spec.call!(spec, 2.0) == 2.0
    assert Spec.run!(spec, [1, 1.0, 2, 2.0]) == [1, 2, 2.0]

    spec =
      spec do
        x -> x !== 1.0
      end

    assert Spec.call!(spec, 1) == true
    assert Spec.call!(spec, 1.0) == false
    assert Spec.call!(spec, 2) == true
    assert Spec.call!(spec, 2.0) == true
    assert Spec.run!(spec, [1, 1.0, 2, 2.0]) == [true, false, true, true]
  end

  test "*/2" do
    spec =
      spec do
        x when x * 2 == 4 -> x
      end

    assert Spec.call!(spec, 1) == nil
    assert Spec.call!(spec, 2) == 2
    assert Spec.run!(spec, [1, 2]) == [2]

    spec =
      spec do
        x -> x * 2
      end

    assert Spec.call!(spec, 1) == 2
    assert Spec.call!(spec, 2) == 4
    assert Spec.run!(spec, [1, 2]) == [2, 4]
  end

  test "//2" do
    spec =
      spec do
        x when x / 2 == 4 -> x
      end

    assert Spec.call!(spec, 8) == 8
    assert Spec.call!(spec, 9) == nil
    assert Spec.run!(spec, [8, 9]) == [8]

    spec =
      spec do
        x -> x / 2
      end

    assert Spec.call!(spec, 8) == 4
    assert Spec.call!(spec, 9) == 4.5
    assert Spec.run!(spec, [8, 9]) == [4, 4.5]
  end

  test "+/1" do
    spec =
      spec do
        x when x == +1 -> x
      end

    assert Spec.call!(spec, 1) == 1
    assert Spec.call!(spec, -1) == nil
    assert Spec.run!(spec, [1, -1]) == [1]

    spec =
      spec do
        x -> +x
      end

    assert Spec.call!(spec, -1) == -1
    assert Spec.call!(spec, 1) == 1
    assert Spec.run!(spec, [1, -1]) == [1, -1]
  end

  test "+/2" do
    spec =
      spec do
        x when x + 2 == 4 -> x
      end

    assert Spec.call!(spec, 2) == 2
    assert Spec.call!(spec, 3) == nil
    assert Spec.run!(spec, [2, 3]) == [2]

    spec =
      spec do
        x -> x + 2
      end

    assert Spec.call!(spec, 2) == 4
    assert Spec.call!(spec, 3) == 5
    assert Spec.run!(spec, [2, 3]) == [4, 5]
  end

  test "</2" do
    spec =
      spec do
        x when x < 2 -> x
      end

    assert Spec.call!(spec, 1) == 1
    assert Spec.call!(spec, 2) == nil
    assert Spec.call!(spec, 3) == nil
    assert Spec.run!(spec, [1, 2, 3]) == [1]

    spec =
      spec do
        x -> x < 2
      end

    assert Spec.call!(spec, 1) == true
    assert Spec.call!(spec, 2) == false
    assert Spec.call!(spec, 3) == false
    assert Spec.run!(spec, [1, 2, 3]) == [true, false, false]
  end

  test "<=/2" do
    spec =
      spec do
        x when x <= 2 -> x
      end

    assert Spec.call!(spec, 1) == 1
    assert Spec.call!(spec, 2) == 2
    assert Spec.call!(spec, 3) == nil
    assert Spec.run!(spec, [1, 2, 3]) == [1, 2]

    spec =
      spec do
        x -> x <= 2
      end

    assert Spec.call!(spec, 1) == true
    assert Spec.call!(spec, 2) == true
    assert Spec.call!(spec, 3) == false
    assert Spec.run!(spec, [1, 2, 3]) == [true, true, false]
  end

  test "==/2" do
    spec =
      spec do
        x when x == 1.0 -> x
      end

    assert Spec.call!(spec, 1) == 1
    assert Spec.call!(spec, 1.0) == 1.0
    assert Spec.call!(spec, 2) == nil
    assert Spec.call!(spec, 2.0) == nil
    assert Spec.run!(spec, [1, 1.0, 2, 2.0]) == [1, 1.0]

    spec =
      spec do
        x -> x == 1.0
      end

    assert Spec.call!(spec, 1) == true
    assert Spec.call!(spec, 1.0) == true
    assert Spec.call!(spec, 2) == false
    assert Spec.call!(spec, 2.0) == false
    assert Spec.run!(spec, [1, 1.0, 2, 2.0]) == [true, true, false, false]
  end

  test "===/2" do
    spec =
      spec do
        x when x === 1.0 -> x
      end

    assert Spec.call!(spec, 1) == nil
    assert Spec.call!(spec, 1.0) == 1.0
    assert Spec.call!(spec, 2) == nil
    assert Spec.call!(spec, 2.0) == nil
    assert Spec.run!(spec, [1, 1.0, 2, 2.0]) == [1.0]

    spec =
      spec do
        x -> x === 1.0
      end

    assert Spec.call!(spec, 1) == false
    assert Spec.call!(spec, 1.0) == true
    assert Spec.call!(spec, 2) == false
    assert Spec.call!(spec, 2.0) == false
    assert Spec.run!(spec, [1, 1.0, 2, 2.0]) == [false, true, false, false]
  end

  test ">/2" do
    spec =
      spec do
        x when x > 2 -> x
      end

    assert Spec.call!(spec, 1) == nil
    assert Spec.call!(spec, 2) == nil
    assert Spec.call!(spec, 3) == 3
    assert Spec.run!(spec, [1, 2, 3]) == [3]

    spec =
      spec do
        x -> x > 2
      end

    assert Spec.call!(spec, 1) == false
    assert Spec.call!(spec, 2) == false
    assert Spec.call!(spec, 3) == true
    assert Spec.run!(spec, [1, 2, 3]) == [false, false, true]
  end

  test ">=/2" do
    spec =
      spec do
        x when x >= 2 -> x
      end

    assert Spec.call!(spec, 1) == nil
    assert Spec.call!(spec, 2) == 2
    assert Spec.call!(spec, 3) == 3
    assert Spec.run!(spec, [1, 2, 3]) == [2, 3]

    spec =
      spec do
        x -> x >= 2
      end

    assert Spec.call!(spec, 1) == false
    assert Spec.call!(spec, 2) == true
    assert Spec.call!(spec, 3) == true
    assert Spec.run!(spec, [1, 2, 3]) == [false, true, true]
  end

  test "abs/1" do
    spec =
      spec do
        x when abs(x) == 1 -> x
      end

    assert Spec.call!(spec, 1) == 1
    assert Spec.call!(spec, 0) == nil
    assert Spec.call!(spec, -1) == -1
    assert Spec.run!(spec, [1, 0, -1]) == [1, -1]

    spec =
      spec do
        x -> abs(x)
      end

    assert Spec.call!(spec, 1) == 1
    assert Spec.call!(spec, 0) == 0
    assert Spec.call!(spec, -1) == 1
    assert Spec.run!(spec, [1, 0, -1]) == [1, 0, 1]
  end

  test "and/2" do
    spec =
      spec do
        x when true and false -> x
      end

    assert Spec.call!(spec, :anything) == nil
    assert Spec.run!(spec, [:anything, :at, :all]) == []

    spec =
      spec do
        {x, y} when x and y -> {x, y}
      end

    assert Spec.call!(spec, {true, true}) == {true, true}
    assert Spec.call!(spec, {true, false}) == nil
    assert Spec.call!(spec, {false, true}) == nil
    assert Spec.call!(spec, {false, false}) == nil

    assert Spec.run!(spec, [{true, true}, {true, false}, {false, true}, {false, false}]) == [
             {true, true}
           ]

    # TODO: Use and/2 in bodies
  end

  # TODO: figure out binary_part/

  test "binary_part/3", test_context do
    assert_raise Matcha.Rewrite.Error, ~r|unsupported function call.*?binary_part/3|s, fn ->
      defmodule test_module_name(test_context) do
        import Matcha

        spec do
          string when binary_part(string, 1, 2) == "bc" -> string
        end
      end
    end
  end

  # @tag :skip
  # test "binary_part/3" do
  # end

  test "bit_size/1" do
    spec =
      spec do
        x when bit_size("abc") == 24 -> x
      end

    assert Spec.call!(spec, :anything) == :anything
    assert Spec.run!(spec, [:anything, :at, :all]) == [:anything, :at, :all]

    spec =
      spec do
        string when bit_size(string) == 24 -> string
      end

    assert Spec.call!(spec, "ab") == nil
    assert Spec.call!(spec, "abc") == "abc"
    assert Spec.call!(spec, "abcd") == nil
    assert Spec.run!(spec, ["ab", "abc", "abcd"]) == ["abc"]

    spec =
      spec do
        _ -> bit_size("abc")
      end

    assert Spec.call!(spec, :anything) == 24
    assert Spec.run!(spec, [:anything, :at, :all]) == [24, 24, 24]

    spec =
      spec do
        string -> bit_size(string)
      end

    assert Spec.call!(spec, "ab") == 16
    assert Spec.call!(spec, "abc") == 24
    assert Spec.call!(spec, "abcd") == 32
    assert Spec.run!(spec, ["ab", "abc", "abcd"]) == [16, 24, 32]
  end

  # TODO: figure out byte_size/1

  test "byte_size/1", test_context do
    assert_raise Matcha.Rewrite.Error, ~r|unsupported function call.*?byte_size/1|s, fn ->
      defmodule test_module_name(test_context) do
        import Matcha

        spec do
          string when byte_size(string) == 3 -> string
        end
      end
    end
  end

  # @tag :skip
  # test "byte_size/1" do
  #   spec =
  #     spec do
  #       x when byte_size("abc") == 3 -> x
  #     end

  #   assert Spec.call!(spec, :anything) == :anything
  #   assert Spec.run!(spec, [:anything, :at, :all]) == [:anything, :at, :all]

  #   spec =
  #     spec do
  #       string when byte_size(string) == 3 -> string
  #     end

  #   assert Spec.call!(spec, "ab") == nil
  #   assert Spec.call!(spec, "abc") == "abc"
  #   assert Spec.call!(spec, "abcd") == nil
  #   assert Spec.run!(spec, ["ab", "abc", "abcd"]) == ["abc"]

  #   spec =
  #     spec do
  #       _ -> byte_size("abc")
  #     end

  #   assert Spec.call!(spec, :anything) == 3
  #   assert Spec.run!(spec, [:anything, :at, :all]) == [3, 3, 3]

  #   spec =
  #     spec do
  #       string -> byte_size(string)
  #     end

  #   assert Spec.call!(spec, "ab") == 2
  #   assert Spec.call!(spec, "abc") == 3
  #   assert Spec.call!(spec, "abcd") == 4
  #   assert Spec.run!(spec, ["ab", "abc", "abcd"]) == [2, 3, 4]
  # end

  test "ceil/1", test_context do
    assert_raise Matcha.Rewrite.Error, ~r|unsupported function call.*?ceil/1|s, fn ->
      defmodule test_module_name(test_context) do
        import Matcha

        spec do
          num when ceil(num) == 5 -> num
        end
      end
    end
  end

  test "div/2" do
    spec =
      spec do
        x when div(9, 2) == 4 -> x
      end

    assert Spec.call!(spec, :anything) == :anything
    assert Spec.run!(spec, [:anything, :at, :all]) == [:anything, :at, :all]

    spec =
      spec do
        x when div(x, 2) == 4 -> x
      end

    assert Spec.call!(spec, 7) == nil
    assert Spec.call!(spec, 8) == 8
    assert Spec.call!(spec, 9) == 9
    assert Spec.call!(spec, 10) == nil
    assert Spec.run!(spec, [7, 8, 9, 10]) == [8, 9]

    spec =
      spec do
        _ -> div(9, 2)
      end

    assert Spec.call!(spec, :anything) == 4
    assert Spec.run!(spec, [:anything, :at, :all]) == [4, 4, 4]

    spec =
      spec do
        x -> div(x, 2)
      end

    assert Spec.call!(spec, 7) == 3
    assert Spec.call!(spec, 8) == 4
    assert Spec.call!(spec, 9) == 4
    assert Spec.call!(spec, 10) == 5
    assert Spec.run!(spec, [7, 8, 9, 10]) == [3, 4, 4, 5]
  end

  test "elem/2" do
    spec =
      spec do
        x when elem({:one}, 0) == :one -> x
      end

    assert Spec.call!(spec, :anything) == :anything
    assert Spec.run!(spec, [:anything, :at, :all]) == [:anything, :at, :all]

    spec =
      spec do
        x when elem(x, 0) == :one -> x
      end

    assert Spec.call!(spec, {:one, :two}) == {:one, :two}
    assert Spec.call!(spec, {:three, :four}) == nil
    assert Spec.run!(spec, one: :two, three: :four) == [one: :two]

    spec =
      spec do
        x -> elem({:one}, 0)
      end

    assert Spec.call!(spec, :anything) == :one
    assert Spec.run!(spec, [:anything, :at, :all]) == [:one, :one, :one]

    spec =
      spec do
        x -> elem(x, 0)
      end

    assert Spec.call!(spec, {:one, :two}) == :one
    assert Spec.call!(spec, {:three, :four}) == :three
    assert Spec.run!(spec, one: :two, three: :four) == [:one, :three]
  end

  test "floor/1", test_context do
    assert_raise Matcha.Rewrite.Error, ~r|unsupported function call.*?floor/1|s, fn ->
      defmodule test_module_name(test_context) do
        import Matcha

        spec do
          num when floor(num) == 5 -> num
        end
      end
    end
  end

  test "hd/1" do
    spec =
      spec do
        x when hd([:one]) == :one -> x
      end

    assert Spec.call!(spec, :anything) == :anything
    assert Spec.run!(spec, [:anything, :at, :all]) == [:anything, :at, :all]

    spec =
      spec do
        x when hd(x) == :one -> x
      end

    assert Spec.call!(spec, [:one, :two]) == [:one, :two]
    assert Spec.call!(spec, [:three, :four]) == nil
    assert Spec.run!(spec, [[:one, :two], [:three, :four]]) == [[:one, :two]]

    spec =
      spec do
        x -> hd([:one])
      end

    assert Spec.call!(spec, :anything) == :one
    assert Spec.run!(spec, [:anything, :at, :all]) == [:one, :one, :one]

    spec =
      spec do
        x -> hd(x)
      end

    assert Spec.call!(spec, [:one, :two]) == :one
    assert Spec.call!(spec, [:three, :four]) == :three
    assert Spec.run!(spec, [[:one, :two], [:three, :four]]) == [:one, :three]
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

  test "is_number/1" do
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
