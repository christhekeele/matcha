defmodule Matcha.Context.Match.UnitTest do
  @moduledoc false

  use UnitTest

  import Matcha

  import TestGuards

  import TestHelpers

  describe "no-op functions" do
    for {function, arity} <- module_importable_functions(Matcha.Context.Match) do
      arguments = Enum.drop(0..arity, 1)

      test "#{function}/#{arity}" do
        assert unquote({{:., [], [Matcha.Context.Match, function]}, [], arguments}) == :noop
      end
    end
  end

  test "basic spec" do
    spec =
      spec(:match) do
        x -> x
      end

    assert Matcha.Spec.call(spec, :x) == {:ok, {:matched, :x}}
    assert Matcha.Spec.run(spec, [:x, :y]) == {:ok, [matched: :x, matched: :y]}
  end

  describe "cons operator (`|`) in matches" do
    test "at the top-level of a list" do
      spec =
        spec(:match) do
          [head | tail] -> {head, tail}
        end

      assert Matcha.Spec.call(spec, [:head, :tail]) ==
               {:ok, {:matched, {:head, [:tail]}}}

      assert Matcha.Spec.call(spec, [:head | :improper]) ==
               {:ok, {:matched, {:head, :improper}}}
    end

    test "at the end of a list" do
      spec =
        spec(:match) do
          [first, second | tail] -> {first, second, tail}
        end

      assert Matcha.Spec.call(spec, [:first, :second, :tail]) ==
               {:ok, {:matched, {:first, :second, [:tail]}}}

      assert Matcha.Spec.call(spec, [:first, :second | :improper]) ==
               {:ok, {:matched, {:first, :second, :improper}}}
    end
  end

  test "char literals in matches" do
    spec =
      spec(:match) do
        {[?5, ?5, ?5, ?- | rest], name} -> {rest, name}
      end

    assert Matcha.Spec.call(spec, {'555-1234', 'John Smith'}) ==
             {:ok, {:matched, {'1234', 'John Smith'}}}
  end

  test "char lists in matches" do
    spec =
      spec(:match) do
        {{'555', rest}, name} -> {rest, name}
      end

    assert Matcha.Spec.call(spec, {{'555', '1234'}, 'John Smith'}) ==
             {:ok, {:matched, {'1234', 'John Smith'}}}
  end

  describe "map literals in matches" do
    test "work as entire match head" do
      spec =
        spec(:match) do
          %{x: z} -> z
        end

      assert Matcha.Spec.call(spec, %{x: 2}) == {:ok, {:matched, 2}}
    end

    test "work inside matches" do
      spec =
        spec(:match) do
          {x, %{a: z, c: y}} -> {x, y, z}
        end

      assert Matcha.Spec.call(spec, {1, %{a: 3, c: 2}}) == {:ok, {:matched, {1, 2, 3}}}
    end
  end

  describe "guards" do
    test "boolean in guard" do
      spec =
        spec(:match) do
          _x when true -> 0
        end

      assert {:ok, {:matched, 0}} == Matcha.Spec.call(spec, {1})
    end

    test "not logic" do
      spec =
        spec(:match) do
          _x when not true -> 0
        end

      assert {:ok, :no_match} == Matcha.Spec.call(spec, {1})
    end

    test "and logic" do
      spec =
        spec(:match) do
          _x when true and false -> 0
        end

      assert {:ok, :no_match} == Matcha.Spec.call(spec, {1})
    end

    test "or logic" do
      spec =
        spec(:match) do
          _x when true or false -> 0
        end

      assert {:ok, {:matched, 0}} == Matcha.Spec.call(spec, {1})
    end

    test "stdlib guard" do
      spec =
        spec(:match) do
          {x} when is_number(x) -> x
        end

      assert {:ok, {:matched, 1}} == Matcha.Spec.call(spec, {1})
    end

    test "multiple clauses" do
      spec =
        spec(:match) do
          _x -> 0
          y -> y
        end

      assert {:ok, {:matched, 0}} == Matcha.Spec.call(spec, {1})
    end

    test "multiple guard clauses" do
      spec =
        spec(:match) do
          x when x == 1 when x == 2 -> x
        end

      assert {:ok, :no_match} == Matcha.Spec.call(spec, 1)
    end

    test "custom guard macro" do
      spec =
        spec(:match) do
          x when custom_gt_3_neq_5_guard(x) -> x
        end

      assert {:ok, {:matched, 7}} == Matcha.Spec.call(spec, 7)
      assert {:ok, :no_match} == Matcha.Spec.call(spec, 1)
    end

    test "nested custom guard macro" do
      spec =
        spec(:match) do
          x when nested_custom_gt_3_neq_5_guard(x) -> x
        end

      assert {:ok, {:matched, 7}} == Matcha.Spec.call(spec, 7)
      assert {:ok, :no_match} == Matcha.Spec.call(spec, 1)
    end

    test "composite bound variables in guards" do
      bound = {1, 2, 3}

      spec =
        spec(:match) do
          arg when arg < bound -> arg
        end

      assert {:ok, {:matched, {:some, :record}}} ==
               Matcha.Spec.call(spec, {:some, :record})
    end
  end

  describe "cons operator (`|`) in bodies" do
    test "at the top-level of a list" do
      expected_source = [{{:"$1", :"$2"}, [], [[:"$1" | :"$2"]]}]

      spec =
        spec(:match) do
          {head, tail} -> [head | tail]
        end

      assert spec.source == expected_source

      assert Matcha.Spec.call(spec, {:head, [:tail]}) ==
               {:ok, {:matched, [:head, :tail]}}

      assert Matcha.Spec.call(spec, {:head, :improper}) ==
               {:ok, {:matched, [:head | :improper]}}
    end

    test "at the end of a list" do
      expected_source = [{{:"$1", :"$2", :"$3"}, [], [[:"$1", :"$2" | :"$3"]]}]

      spec =
        spec(:match) do
          {first, second, tail} -> [first, second | tail]
        end

      assert spec.source == expected_source

      assert Matcha.Spec.call(spec, {:first, :second, [:tail]}) ==
               {:ok, {:matched, [:first, :second, :tail]}}

      assert Matcha.Spec.call(spec, {:first, :second, :improper}) ==
               {:ok, {:matched, [:first, :second | :improper]}}
    end
  end
end
