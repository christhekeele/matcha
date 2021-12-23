defmodule Matcha.Rewrite.Bodies.Test do
  @moduledoc false

  use ExUnit.Case, async: true
  doctest Matcha.Rewrite

  import TestHelpers

  require Matcha

  describe "cons operator (`|`)" do
    test "in bodies at the top-level of a list" do
      expected_source = [{{:"$1", :"$2"}, [], [[:"$1" | :"$2"]]}]

      spec =
        Matcha.spec do
          {head, tail} -> [head | tail]
        end

      assert spec.source == expected_source

      assert Matcha.Spec.call(spec, {:head, [:tail]}) ==
               {:ok, {:matched, [:head, :tail]}}

      assert Matcha.Spec.call(spec, {:head, :improper}) ==
               {:ok, {:matched, [:head | :improper]}}
    end

    test "in bodies at the end of a list" do
      expected_source = [{{:"$1", :"$2", :"$3"}, [], [[:"$1", :"$2" | :"$3"]]}]

      spec =
        Matcha.spec do
          {first, second, tail} -> [first, second | tail]
        end

      assert spec.source == expected_source

      assert Matcha.Spec.call(spec, {:first, :second, [:tail]}) ==
               {:ok, {:matched, [:first, :second, :tail]}}

      assert Matcha.Spec.call(spec, {:first, :second, :improper}) ==
               {:ok, {:matched, [:first, :second | :improper]}}
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

  test "char literals in bodies" do
    expected_source = [{:"$1", [], [[?5, ?5, ?5 | :"$1"]]}]

    spec =
      Matcha.spec do
        char -> [?5, ?5, ?5 | char]
      end

    assert spec.source == expected_source

    assert Matcha.Spec.call(spec, '-') ==
             {:ok, {:matched, '555-'}}
  end

  test "char lists in bodies" do
    expected_source = [{:"$1", [], [{{[53, 53, 53], :"$1"}}]}]

    spec =
      Matcha.spec do
        name -> {'555', name}
      end

    assert spec.source == expected_source

    assert Matcha.Spec.call(spec, :foobar) ==
             {:ok, {:matched, {'555', :foobar}}}
  end

  test "return full capture in body" do
    raw_spec =
      Matcha.spec do
        {x, x} = z -> z
      end

    assert raw_spec.source == [{{:"$1", :"$1"}, [], [:"$_"]}]

    spec =
      Matcha.spec do
        {x, x} = z -> z
      end

    assert {:ok, {:matched, {:x, :x}}} == Matcha.Spec.call(spec, {:x, :x})
    assert {:ok, :no_match} == Matcha.Spec.call(spec, {:x, :y})
    assert {:ok, :no_match} == Matcha.Spec.call(spec, {:other})
  end

  test "multiple exprs in body" do
    spec =
      Matcha.spec do
        x ->
          _ = 0
          x
      end

    assert spec.source == [{:"$1", [], [0, :"$1"]}]

    assert {:ok, {:matched, 1}} == Matcha.Spec.call(spec, 1)
  end

  describe "map literals in body" do
    test "map in head tuple" do
      spec =
        Matcha.spec do
          {x, %{a: y, c: z}} -> {x, y, z}
        end

      assert spec.source == [{{:"$1", %{a: :"$2", c: :"$3"}}, [], [{{:"$1", :"$2", :"$3"}}]}]
    end

    test "map is allowed in the head of function" do
      spec =
        Matcha.spec do
          %{x: z} -> z
        end

      assert [2] == Matcha.Spec.run(spec, [%{x: 2}])
    end
  end

  describe "unbound variables" do
    test "in body", context do
      assert_raise CompileError, ~r"undefined function meant_to_not_exist/0", fn ->
        defmodule test_module_name(context) do
          Matcha.spec do
            x -> meant_to_not_exist
          end
        end
      end
    end

    test "in body when matched from", context do
      assert_raise CompileError, ~r"undefined function meant_to_not_exist/0", fn ->
        defmodule test_module_name(context) do
          Matcha.spec do
            x -> x = meant_to_not_exist
          end
        end
      end
    end

    test "in body when assigned to", context do
      assert_raise Matcha.Rewrite.Error,
                   ~r"variable `meant_to_be_unused` was not bound in the match head",
                   fn ->
                     defmodule test_module_name(context) do
                       Matcha.spec do
                         x -> meant_to_be_unused = x
                       end
                     end
                   end
    end

    test "in body when assigned to and used", context do
      assert_raise Matcha.Rewrite.Error, ~r"variable `y` was not bound in the match head", fn ->
        defmodule test_module_name(context) do
          Matcha.spec do
            x ->
              y = x
              y
          end
        end
      end
    end
  end

  describe "matches in bodies" do
    test "with literals", context do
      assert_raise Matcha.Rewrite.Error,
                   ~r"cannot use the match operator in match spec bodies",
                   fn ->
                     defmodule test_module_name(context) do
                       Matcha.spec do
                         _ ->
                           {:foo} = {:foo}
                       end
                     end
                   end
    end

    test "with tuples", context do
      assert_raise Matcha.Rewrite.Error,
                   ~r"cannot match `{:foo}` to `{:foo}`",
                   fn ->
                     defmodule test_module_name(context) do
                       Matcha.spec do
                         _ ->
                           {:foo} = {:foo}
                       end
                     end
                   end
    end
  end
end
