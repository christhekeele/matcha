defmodule Matcha.Context.FilterMap.UnitTest do
  @moduledoc false

  use ExUnit.Case, async: true

  import Matcha

  import TestGuards

  test "basic spec" do
    spec =
      spec(:filter_map) do
        x -> x
      end

    assert {:ok, :x} == Matcha.Spec.call(spec, :x)
  end

  describe "cons operator (`|`) in matches" do
    test "at the top-level of a list" do
      spec =
        spec(:filter_map) do
          [head | tail] -> {head, tail}
        end

      assert Matcha.Spec.call(spec, [:head, :tail]) ==
               {:ok, {:head, [:tail]}}

      assert Matcha.Spec.call(spec, [:head | :improper]) ==
               {:ok, {:head, :improper}}
    end

    test "at the end of a list" do
      spec =
        spec(:filter_map) do
          [first, second | tail] -> {first, second, tail}
        end

      assert Matcha.Spec.call(spec, [:first, :second, :tail]) ==
               {:ok, {:first, :second, [:tail]}}

      assert Matcha.Spec.call(spec, [:first, :second | :improper]) ==
               {:ok, {:first, :second, :improper}}
    end
  end

  test "char literals in matches" do
    spec =
      spec(:filter_map) do
        {[?5, ?5, ?5, ?- | rest], name} -> {rest, name}
      end

    assert Matcha.Spec.call(spec, {'555-1234', 'John Smith'}) ==
             {:ok, {'1234', 'John Smith'}}
  end

  test "char lists in matches" do
    spec =
      spec(:filter_map) do
        {{'555', rest}, name} -> {rest, name}
      end

    assert Matcha.Spec.call(spec, {{'555', '1234'}, 'John Smith'}) ==
             {:ok, {'1234', 'John Smith'}}
  end

  describe "map literals in matches" do
    test "work as entire match head" do
      spec =
        spec(:filter_map) do
          %{x: z} -> z
        end

      assert Matcha.Spec.call(spec, %{x: 2}) == {:ok, 2}
    end

    test "work inside matches" do
      spec =
        spec(:filter_map) do
          {x, %{a: z, c: y}} -> {x, y, z}
        end

      assert Matcha.Spec.call(spec, {1, %{a: 3, c: 2}}) == {:ok, {1, 2, 3}}
    end
  end

  describe "guards" do
    test "boolean in guard" do
      spec =
        spec(:filter_map) do
          _x when true -> 0
        end

      assert {:ok, 0} == Matcha.Spec.call(spec, {1})
    end

    test "not logic" do
      spec =
        spec(:filter_map) do
          _x when not true -> 0
        end

      assert {:ok, nil} == Matcha.Spec.call(spec, {1})
    end

    test "and logic" do
      spec =
        spec(:filter_map) do
          _x when true and false -> 0
        end

      assert {:ok, nil} == Matcha.Spec.call(spec, {1})
    end

    test "or logic" do
      spec =
        spec(:filter_map) do
          _x when true or false -> 0
        end

      assert {:ok, 0} == Matcha.Spec.call(spec, {1})
    end

    test "stdlib guard" do
      spec =
        spec(:filter_map) do
          {x} when is_number(x) -> x
        end

      assert {:ok, 1} == Matcha.Spec.call(spec, {1})
    end

    test "multiple clauses" do
      spec =
        spec(:filter_map) do
          _x -> 0
          y -> y
        end

      assert {:ok, 0} == Matcha.Spec.call(spec, {1})
    end

    test "multiple guard clauses" do
      spec =
        spec(:filter_map) do
          x when x == 1 when x == 2 -> x
        end

      assert {:ok, nil} == Matcha.Spec.call(spec, 1)
    end

    test "custom guard macro" do
      spec =
        spec(:filter_map) do
          x when custom_gt_3_neq_5_guard(x) -> x
        end

      assert {:ok, 7} == Matcha.Spec.call(spec, 7)
      assert {:ok, nil} == Matcha.Spec.call(spec, 1)
    end

    test "nested custom guard macro" do
      spec =
        spec(:filter_map) do
          x when nested_custom_gt_3_neq_5_guard(x) -> x
        end

      assert {:ok, 7} == Matcha.Spec.call(spec, 7)
      assert {:ok, nil} == Matcha.Spec.call(spec, 1)
    end

    test "composite bound variables in guards" do
      one = {1, 2, 3}

      spec =
        spec(:filter_map) do
          arg when arg < one -> arg
        end

      assert {:ok, {:some, :record}} ==
               Matcha.Spec.call(spec, {:some, :record})
    end

    test "composite bound variables in return value" do
      bound = {1, 2, 3}

      spec =
        spec(:filter_map) do
          arg -> {bound, arg}
        end

      assert {:ok, {bound, {:some, :record}}} ==
               Matcha.Spec.call(spec, {:some, :record})
    end
  end

  describe "cons operator (`|`) in bodies" do
    test "at the top-level of a list" do
      expected_source = [{{:"$1", :"$2"}, [], [[:"$1" | :"$2"]]}]

      spec =
        spec(:filter_map) do
          {head, tail} -> [head | tail]
        end

      assert Matcha.Spec.call(spec, {:head, [:tail]}) ==
               {:ok, [:head, :tail]}

      assert Matcha.Spec.call(spec, {:head, :improper}) ==
               {:ok, [:head | :improper]}
    end

    test "at the end of a list" do
      expected_source = [{{:"$1", :"$2", :"$3"}, [], [[:"$1", :"$2" | :"$3"]]}]

      spec =
        spec(:filter_map) do
          {first, second, tail} -> [first, second | tail]
        end

      assert Matcha.Spec.call(spec, {:first, :second, [:tail]}) ==
               {:ok, [:first, :second, :tail]}

      assert Matcha.Spec.call(spec, {:first, :second, :improper}) ==
               {:ok, [:first, :second | :improper]}
    end
  end
end
