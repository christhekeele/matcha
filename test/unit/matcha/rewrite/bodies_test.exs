defmodule Matcha.Rewrite.Bodies.UnitTest do
  @moduledoc false

  use ExUnit.Case, async: true
  doctest Matcha.Rewrite

  import TestHelpers

  import Matcha

  describe "cons operator (`|`) in bodies:" do
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

    test "with bad usage in middle of list", context do
      assert_raise CompileError, ~r"misplaced operator |/2", fn ->
        defmodule test_module_name(context) do
          import Matcha

          spec do
            {first, second, third, fourth} -> [first, second | third, fourth]
          end
        end
      end
    end

    test "with bad usage twice in list", context do
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

  describe "invalid calls in bodies:" do
    test "local calls", context do
      assert_raise CompileError, ~r"undefined function meant_to_not_exist/0", fn ->
        defmodule test_module_name(context) do
          import Matcha

          spec do
            x -> meant_to_not_exist()
          end
        end
      end
    end

    @tag :skip
    test "remote calls", context do
      assert_raise CompileError, ~r"cannot invoke remote function.*?inside guards", fn ->
        defmodule test_module_name(context) do
          import Matcha

          spec do
            x -> Module.meant_to_not_exist()
          end
        end
      end
    end
  end

  describe "unbound variables in bodies:" do
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

  describe "matches in bodies:" do
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

  describe "stlib guards" do
    test "-/1" do
      spec =
        spec do
          x -> -x
        end

      assert spec.source == [{:"$1", [], [-: :"$1"]}]
    end

    test "-/2" do
      spec =
        spec do
          x -> x - 1
        end

      assert spec.source == [{:"$1", [], [{:-, :"$1", 1}]}]
    end

    test "!=/2" do
      spec =
        spec do
          x -> x != 1.0
        end

      assert spec.source == [{:"$1", [], [{:"/=", :"$1", 1.0}]}]
    end

    test "!==/2" do
      spec =
        spec do
          x -> x !== 1.0
        end

      assert spec.source == [{:"$1", [], [{:"=/=", :"$1", 1.0}]}]
    end

    test "*/2" do
      spec =
        spec do
          x -> x * 2
        end

      assert spec.source == [{:"$1", [], [{:*, :"$1", 2}]}]
    end

    test "//2" do
      spec =
        spec do
          x -> x / 2
        end

      assert spec.source == [{:"$1", [], [{:/, :"$1", 2}]}]
    end

    test "+/1" do
      spec =
        spec do
          x -> +x
        end

      assert spec.source == [{:"$1", [], [+: :"$1"]}]
    end

    # TODO: figure this failing syntax thing out
    # @tag :skip
    # test "weird +/1" do
    #   spec =
    #     spec do
    #       x -> +:foo
    #     end

    #   assert spec.source == [{:"$1", [], [+: :foo]}]
    # end

    test "+/2" do
      spec =
        spec do
          x -> x + 2
        end

      assert spec.source == [{:"$1", [], [{:+, :"$1", 2}]}]
    end

    test "</2" do
      spec =
        spec do
          x -> x < 2
        end

      assert spec.source == [{:"$1", [], [{:<, :"$1", 2}]}]
    end

    test "<=/2" do
      spec =
        spec do
          x -> x <= 2
        end

      assert spec.source == [{:"$1", [], [{:"=<", :"$1", 2}]}]
    end

    test "==/2" do
      spec =
        spec do
          x -> x == 1.0
        end

      assert spec.source == [{:"$1", [], [{:==, :"$1", 1.0}]}]
    end

    test "===/2" do
      spec =
        spec do
          x -> x === 1.0
        end

      assert spec.source == [{:"$1", [], [{:"=:=", :"$1", 1.0}]}]
    end

    test ">/2" do
      spec =
        spec do
          x -> x > 2
        end

      assert spec.source == [{:"$1", [], [{:>, :"$1", 2}]}]
    end

    test ">=/2" do
      spec =
        spec do
          x -> x >= 2
        end

      assert spec.source == [{:"$1", [], [{:>=, :"$1", 2}]}]
    end

    test "abs/1" do
      spec =
        spec do
          x -> abs(x)
        end

      assert spec.source == [{:"$1", [], [{:abs, :"$1"}]}]
    end

    # FIXME: fix `and/2` in bodies
    # @tag :skip
    # test "and/2" do
    #   spec =
    #     spec do
    #       _x -> true and false
    #     end

    #   assert spec.source == [{:"$1", [{:andalso, true, false}], [0]}]

    #   spec =
    #     spec do
    #       {x, y} -> x and y
    #     end

    #   assert spec.source == [{{:"$1", :"$2"}, [{:andalso, :"$1", :"$2"}], [{{:"$1", :"$2"}}]}]
    # end

    # TODO: figure out binary_part/3
    # @tag :skip
    # test "binary_part/3" do
    #   spec =
    #     spec do
    #       _ -> binary_part("abc", 1, 2)
    #     end

    #   assert spec.source == [{:"$1", [{:andalso, true, false}], [0]}]

    #   spec =
    #     spec do
    #       string -> binary_part(string, 1, 2)
    #     end

    #   assert spec.source == [{:"$1", [{:andalso, true, false}], [0]}]
    # end

    test "bit_size/1" do
      spec =
        spec do
          _ -> bit_size("abc")
        end

      assert spec.source == [{:_, [], [{:bit_size, "abc"}]}]

      spec =
        spec do
          string -> bit_size(string)
        end

      assert spec.source == [{:"$1", [], [bit_size: :"$1"]}]
    end

    # TODO: figure out byte_size/1
    # @tag :skip
    # test "byte_size/1" do
    #   spec =
    #     spec do
    #       _ -> byte_size("abc")
    #     end

    #   assert spec.source == [{:_, [], [{:byte_size, "abc"}]}]

    #   spec =
    #     spec do
    #       string -> byte_size(string)
    #     end

    #   assert spec.source == [{:"$1", [], [byte_size: :"$1"]}]
    # end

    test "div/2" do
      spec =
        spec do
          _ -> div(8, 2)
        end

      assert spec.source == [{:_, [], [{:div, 8, 2}]}]

      spec =
        spec do
          x -> div(x, 2)
        end

      assert spec.source == [{:"$1", [], [{:div, :"$1", 2}]}]
    end

    test "elem/2" do
      spec =
        spec do
          _x -> elem({:one}, 0)
        end

      assert spec.source == [{:"$1", [], [{:element, 1, {{:one}}}]}]

      spec =
        spec do
          x -> elem(x, 0)
        end

      assert spec.source == [{:"$1", [], [{:element, 1, :"$1"}]}]
    end

    test "hd/1" do
      spec =
        spec do
          _x -> hd([:one])
        end

      assert spec.source == [{:"$1", [], [{:hd, [:one]}]}]

      spec =
        spec do
          x -> hd(x)
        end

      assert spec.source == [{:"$1", [], [{:hd, :"$1"}]}]
    end

    test "in/2 with compile-time list" do
      spec =
        spec do
          x -> x in [:one, :two, :three]
        end

      assert spec.source == [
               {:"$1", [],
                [
                  {:orelse, {:orelse, {:"=:=", :"$1", :one}, {:"=:=", :"$1", :two}},
                   {:"=:=", :"$1", :three}}
                ]}
             ]

      spec =
        spec do
          x -> x in 1..3
        end

      assert spec.source == [
               {:"$1", [],
                [{:andalso, {:is_integer, :"$1"}, {:andalso, {:>=, :"$1", 1}, {:"=<", :"$1", 3}}}]}
             ]

      spec =
        spec do
          x -> x in ?a..?z
        end

      assert spec.source == [
               {:"$1", [],
                [
                  {:andalso, {:is_integer, :"$1"},
                   {:andalso, {:>=, :"$1", 97}, {:"=<", :"$1", 122}}}
                ]}
             ]
    end

    # FIXME: make dynamic lists in "in/2" invalid
    @tag :skip
    test "in/2 with dynamic list", test_context do
      assert_raise ArgumentError, ~r"for operator \"in\"", fn ->
        defmodule test_module_name(test_context) do
          import Matcha

          spec do
            x -> 1 in x
          end
        end
      end
    end

    test "is_atom/1" do
      spec =
        spec do
          x -> is_atom(x)
        end

      assert spec.source == [{:"$1", [], [{:is_atom, :"$1"}]}]
    end

    test "is_binary/1" do
      spec =
        spec do
          x -> is_binary(x)
        end

      assert spec.source == [{:"$1", [], [{:is_binary, :"$1"}]}]
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
