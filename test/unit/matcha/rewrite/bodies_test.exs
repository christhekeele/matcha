defmodule Matcha.Rewrite.Bodies.Test do
  @moduledoc false

  use ExUnit.Case, async: true
  doctest Matcha.Rewrite

  import TestHelpers

  import Matcha

  describe "cons operator (`|`) in bodies" do
    test "at the top-level of a list" do
      expected_source = [{{:"$1", :"$2"}, [], [[:"$1" | :"$2"]]}]

      spec =
        spec do
          {head, tail} -> [head | tail]
        end

      assert spec.source == expected_source
    end

    test "at the end of a list" do
      expected_source = [{{:"$1", :"$2", :"$3"}, [], [[:"$1", :"$2" | :"$3"]]}]

      spec =
        spec do
          {first, second, tail} -> [first, second | tail]
        end

      assert spec.source == expected_source
    end

    test "in bodies with bad usage in middle of list", context do
      assert_raise CompileError, ~r"misplaced operator |/2", fn ->
        defmodule test_module_name(context) do
          import Matcha

          spec do
            {first, second, third, fourth} -> [first, second | third, fourth]
          end
        end
      end
    end

    test "in bodies with bad usage twice in list", context do
      assert_raise CompileError, ~r"misplaced operator |/2", fn ->
        defmodule test_module_name(context) do
          import Matcha

          spec do
            {first, second, third, fourth, fifth} -> [first, second | third, fourth | fifth]
          end
        end
      end
    end
  end

  test "char literals in bodies" do
    expected_source = [{:"$1", [], [[?5, ?5, ?5 | :"$1"]]}]

    spec =
      spec do
        char -> [?5, ?5, ?5 | char]
      end

    assert spec.source == expected_source
  end

  test "char lists in bodies" do
    expected_source = [{:"$1", [], [{{[53, 53, 53], :"$1"}}]}]

    spec =
      spec do
        name -> {'555', name}
      end

    assert spec.source == expected_source
  end

  test "composite bound variables in return value" do
    bound = {1, 2, 3}
    expected_source = [{:"$1", [], [{{{:const, {1, 2, 3}}, :"$1"}}]}]

    spec =
      spec do
        arg -> {bound, arg}
      end

    assert spec.source == expected_source
  end

  test "return full capture in bodies" do
    expected_source = [{{:"$1", :"$1"}, [], [:"$_"]}]

    spec =
      spec do
        {x, x} = z -> z
      end

    assert spec.source == expected_source
  end

  test "multiple exprs in bodies" do
    expected_source = [{:"$1", [], [0, :"$1"]}]

    spec =
      spec do
        x ->
          _ = 0
          x
      end

    assert spec.source == expected_source
  end

  describe "map literals in bodies" do
    test "map in head tuple" do
      expected_source = [{{:"$1", %{a: :"$2", c: :"$3"}}, [], [{{:"$1", :"$2", :"$3"}}]}]

      spec =
        spec do
          {x, %{a: y, c: z}} -> {x, y, z}
        end

      assert spec.source == expected_source
    end

    test "map is allowed in the head of function" do
      expected_source = [{%{x: :"$1"}, [], [:"$1"]}]

      spec =
        spec do
          %{x: z} -> z
        end

      assert spec.source == expected_source
    end
  end

  describe "unbound variables in bodies" do
    test "when referenced", context do
      assert_raise CompileError, ~r"undefined function meant_to_not_exist/0", fn ->
        defmodule test_module_name(context) do
          import Matcha

          spec do
            x -> meant_to_not_exist
          end
        end
      end
    end

    test "when matched on", context do
      assert_raise CompileError, ~r"undefined function meant_to_not_exist/0", fn ->
        defmodule test_module_name(context) do
          import Matcha

          spec do
            x -> x = meant_to_not_exist
          end
        end
      end
    end

    test "when assigned to", context do
      assert_raise Matcha.Rewrite.Error,
                   ~r"variable `meant_to_be_unused` was not bound in the match head",
                   fn ->
                     defmodule test_module_name(context) do
                       spec do
                         x -> meant_to_be_unused = x
                       end
                     end
                   end
    end

    test "when assigned to and used", context do
      assert_raise Matcha.Rewrite.Error, ~r"variable `y` was not bound in the match head", fn ->
        defmodule test_module_name(context) do
          import Matcha

          spec do
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
                       spec do
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
                       spec do
                         _ ->
                           {:foo} = {:foo}
                       end
                     end
                   end
    end
  end
end
