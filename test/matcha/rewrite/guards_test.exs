defmodule Matcha.Rewrite.Guards.Test do
  @moduledoc false

  use ExUnit.Case, async: true
  doctest Matcha.Rewrite

  require Record
  Record.defrecordp(:user, [:name, :age])

  import TestGuards

  require Matcha

  describe "guard logic" do
    test "boolean in guard" do
      spec =
        Matcha.spec do
          _x when true -> 0
        end

      assert spec.source == [{:"$1", [true], [0]}]

      assert {:ok, {:returned, 0}} == Matcha.Spec.run(spec, {1})
    end

    test "not logic" do
      spec =
        Matcha.spec do
          _x when not true -> 0
        end

      assert spec.source == [{:"$1", [not: true], [0]}]

      assert {:ok, {:returned, false}} == Matcha.Spec.run(spec, {1})
    end

    test "and logic" do
      spec =
        Matcha.spec do
          _x when true and false -> 0
        end

      assert spec.source == [{:"$1", [{:andalso, true, false}], [0]}]

      assert {:ok, {:returned, false}} == Matcha.Spec.run(spec, {1})
    end

    test "or logic" do
      spec =
        Matcha.spec do
          _x when true or false -> 0
        end

      assert spec.source == [{:"$1", [{:orelse, true, false}], [0]}]

      assert {:ok, {:returned, 0}} == Matcha.Spec.run(spec, {1})
    end
  end

  test "stdlib guard" do
    spec =
      Matcha.spec do
        {x} when is_number(x) -> x
      end

    assert spec.source == [{{:"$1"}, [{:is_number, :"$1"}], [:"$1"]}]

    assert {:ok, {:returned, 1}} == Matcha.Spec.run(spec, {1})
  end

  test "multiple clauses" do
    spec =
      Matcha.spec do
        _x -> 0
        y -> y
      end

    assert spec.source == [{:"$1", [], [0]}, {:"$1", [], [:"$1"]}]
  end

  test "multiple guard clauses" do
    spec =
      Matcha.spec do
        x when x == 1 when x == 2 -> x
      end

    assert spec.source == [{:"$1", [{:==, :"$1", 1}, {:==, :"$1", 2}], [:"$1"]}]

    assert {:ok, {:returned, false}} == Matcha.Spec.run(spec, 1)
  end

  test "custom guard macro" do
    spec =
      Matcha.spec do
        x when custom_gt_3_neq_5_guard(x) -> x
      end

    assert spec.source == [{:"$1", [{:andalso, {:>, :"$1", 3}, {:"/=", :"$1", 5}}], [:"$1"]}]

    assert {:ok, {:returned, 7}} == Matcha.Spec.run(spec, 7)
    assert {:ok, {:returned, false}} == Matcha.Spec.run(spec, 1)
  end

  test "nested custom guard macro" do
    spec =
      Matcha.spec do
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

    assert {:ok, {:returned, 7}} == Matcha.Spec.run(spec, 7)
    assert {:ok, {:returned, false}} == Matcha.Spec.run(spec, 1)
  end

  test "composite bound variables in guards" do
    one = {1, 2, 3}

    spec =
      Matcha.spec do
        arg when arg < one -> arg
      end

    assert spec.source == [{:"$1", [{:<, :"$1", {:const, {1, 2, 3}}}], [:"$1"]}]
  end

  test "composite bound variables in return value" do
    bound = {1, 2, 3}

    spec =
      Matcha.spec do
        arg -> {bound, arg}
      end

    assert spec.source == [{:"$1", [], [{{{:const, {1, 2, 3}}, :"$1"}}]}]

    assert {:ok, {:returned, {bound, {:some, :record}}}} ==
             Matcha.Spec.run(spec, {:some, :record})
  end
end
