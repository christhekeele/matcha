defmodule Matcha.Rewrite.Test do
  @moduledoc false

  use ExUnit.Case, async: true
  doctest Matcha.Rewrite

  import TestHelpers

  require Matcha

  describe "cons operator (`|`)" do
    test "in matches at the top-level of a list" do
      expected_source = [{[:"$1" | :"$2"], [], [{{:"$1", :"$2"}}]}]

      spec =
        Matcha.spec do
          [head | tail] -> {head, tail}
        end

      assert spec.source == expected_source

      assert Matcha.Spec.run(spec, [:head, :tail]) ==
               {:ok, {:returned, {:head, [:tail]}}}

      assert Matcha.Spec.run(spec, [:head | :improper]) ==
               {:ok, {:returned, {:head, :improper}}}
    end

    test "in matches at the end of a list" do
      expected_source = [{[:"$1", :"$2" | :"$3"], [], [{{:"$1", :"$2", :"$3"}}]}]

      spec =
        Matcha.spec do
          [first, second | tail] -> {first, second, tail}
        end

      assert spec.source == expected_source

      assert Matcha.Spec.run(spec, [:first, :second, :tail]) ==
               {:ok, {:returned, {:first, :second, [:tail]}}}

      assert Matcha.Spec.run(spec, [:first, :second | :improper]) ==
               {:ok, {:returned, {:first, :second, :improper}}}
    end

    test "in matches with bad usage in middle of list", context do
      assert_raise CompileError, ~r"misplaced operator |/2", fn ->
        defmodule test_module_name(context) do
          Matcha.spec do
            [first, second | third, fourth] -> {first, second, third, fourth}
          end
        end
      end
    end

    test "in matches with bad usage twice in list", context do
      assert_raise CompileError, ~r"misplaced operator |/2", fn ->
        defmodule test_module_name(context) do
          Matcha.spec do
            [first, second | third, fourth | fifth] -> {first, second, third, fourth, fifth}
          end
        end
      end
    end

    test "in bodies at the top-level of a list" do
      expected_source = [{{:"$1", :"$2"}, [], [[:"$1" | :"$2"]]}]

      spec =
        Matcha.spec do
          {head, tail} -> [head | tail]
        end

      assert spec.source == expected_source

      assert Matcha.Spec.run(spec, {:head, [:tail]}) ==
               {:ok, {:returned, [:head, :tail]}}

      assert Matcha.Spec.run(spec, {:head, :improper}) ==
               {:ok, {:returned, [:head | :improper]}}
    end

    test "in bodies at the end of a list" do
      expected_source = [{{:"$1", :"$2", :"$3"}, [], [[:"$1", :"$2" | :"$3"]]}]

      spec =
        Matcha.spec do
          {first, second, tail} -> [first, second | tail]
        end

      assert spec.source == expected_source

      assert Matcha.Spec.run(spec, {:first, :second, [:tail]}) ==
               {:ok, {:returned, [:first, :second, :tail]}}

      assert Matcha.Spec.run(spec, {:first, :second, :improper}) ==
               {:ok, {:returned, [:first, :second | :improper]}}
    end

    test "in bodies with bad usage in middle of list", context do
      assert_raise CompileError, ~r"misplaced operator |/2", fn ->
        defmodule test_module_name(context) do
          Matcha.spec do
            {first, second, third, fourth} -> [first, second | third, fourth]
          end
        end
      end
    end

    test "in bodies with bad usage twice in list", context do
      assert_raise CompileError, ~r"misplaced operator |/2", fn ->
        defmodule test_module_name(context) do
          Matcha.spec do
            {first, second, third, fourth, fifth} -> [first, second | third, fourth | fifth]
          end
        end
      end
    end
  end

  test "char literals" do
    expected_source = [{{[53, 53, 53, 45 | :"$1"], :"$2"}, [], [{{:"$1", :"$2"}}]}]

    spec =
      Matcha.spec do
        {[?5, ?5, ?5, ?- | rest], name} -> {rest, name}
      end

    assert spec.source == expected_source

    assert Matcha.Spec.run(spec, {'555-1234', 'John Smith'}) ==
             {:ok, {:returned, {'1234', 'John Smith'}}}
  end

  test "char lists" do
    expected_source = [{{{[53, 53, 53], :"$1"}, :"$2"}, [], [{{:"$1", :"$2"}}]}]

    spec =
      Matcha.spec do
        {{'555', rest}, name} -> {rest, name}
      end

    assert spec.source == expected_source

    assert Matcha.Spec.run(spec, {{'555', '1234'}, 'John Smith'}) ==
             {:ok, {:returned, {'1234', 'John Smith'}}}
  end
end
