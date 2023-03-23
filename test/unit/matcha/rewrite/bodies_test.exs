defmodule Matcha.Rewrite.Bodies.UnitTest do
  @moduledoc false

  use UnitTest

  import TestHelpers

  import Matcha

  describe ":erlang functions" do
    # These tests ensure:
    #  - all these calls are permitted in bodies through our rewrite phase
    #  - that they are accepted by Erlang's match spec validator
    for {function, arity} <- Matcha.Context.Erlang.__info__(:functions) do
      arguments = Macro.generate_unique_arguments(arity, __MODULE__)
      source_arguments = for n <- Enum.drop(0..arity, 1), do: :"$#{n}"

      test ":erlang.#{function}/#{arity}" do
        spec =
          spec do
            {unquote_splicing(arguments)} ->
              unquote({{:., [], [:erlang, function]}, [], arguments})
          end

        assert spec.source == [
                 {{unquote_splicing(source_arguments)}, [],
                  [{unquote(function), unquote_splicing(source_arguments)}]}
               ]
      end
    end
  end

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

    # TODO: Figure this out, it's passing through to the spec compiler
    @tag :skip
    test "remote calls", context do
      assert_raise Matcha.Error.Rewrite,
                   ~r"unsupported function call.*?cannot call remote function",
                   fn ->
                     defmodule test_module_name(context) do
                       import Matcha

                       spec do
                         x when is_binary(x) -> String.length(x)
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
      assert_raise Matcha.Error.Rewrite,
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
      assert_raise Matcha.Error.Rewrite, ~r"variable `y` was not bound in the match head", fn ->
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
      assert_raise Matcha.Error.Rewrite,
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
      assert_raise Matcha.Error.Rewrite,
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

    # TODO: figure this failing syntax thing out
    @tag :skip
    test "weird +/1", context do
      assert_raise ArithmeticError, ~r"bad argument in arithmetic expression", fn ->
        defmodule test_module_name(context) do
          spec =
            spec do
              x -> +:foo
            end
        end
      end
    end
  end

  describe "elixir guards" do
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

    test "and/2" do
      spec =
        spec do
          x -> true and x
        end

      assert spec.source == [{:"$1", [], [{:andalso, true, :"$1"}]}]

      spec =
        spec do
          {x, y} -> x and y
        end

      assert spec.source == [{{:"$1", :"$2"}, [], [{:andalso, :"$1", :"$2"}]}]
    end

    if Matcha.Helpers.erlang_version() >= 25 do
      test "binary_part/3" do
        spec =
          spec do
            _ -> binary_part("abc", 1, 2)
          end

        assert spec.source == [{:_, [], [{:binary_part, "abc", 1, 2}]}]

        spec =
          spec do
            string -> binary_part(string, 1, 2)
          end

        assert spec.source == [{:"$1", [], [{:binary_part, :"$1", 1, 2}]}]
      end
    end

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

    # FIXME: is_boolean/1 expansion with defguard is messing up
    # @tag :skip
    # test "is_boolean/1" do
    #   spec =
    #     spec do
    #       x -> is_boolean(x)
    #     end

    #   assert spec.source == [
    #            {:"$1",
    #             [
    #               {:andalso, {:is_atom, :"$1"},
    #                {:orelse, {:==, :"$1", true}, {:==, :"$1", false}}}
    #             ], [:"$1"]}
    #          ]
    # end

    # FIXME: is_exception/1 expansion in bodies does something we can't support
    # @tag :skip
    # test "is_exception/1" do
    #   spec =
    #     spec do
    #       x -> is_exception(x)
    #     end

    #   assert spec.source == [
    #            {
    #              :"$1",
    #              [
    #                {
    #                  :andalso,
    #                  {
    #                    :andalso,
    #                    {:andalso, {:andalso, {:is_map, :"$1"}, {:is_map_key, :__struct__, :"$1"}},
    #                     {:is_atom, {:map_get, :__struct__, :"$1"}}},
    #                    {:is_map_key, :__exception__, :"$1"}
    #                  },
    #                  {:==, {:map_get, :__exception__, :"$1"}, true}
    #                }
    #              ],
    #              [:"$1"]
    #            }
    #          ]
    # end

    # FIXME: is_exception/2 expansion with is messing up
    # @tag :skip
    # test "is_exception/2" do
    #   spec =
    #     spec do
    #       x -> is_exception(x, ArgumentError)
    #     end

    #   assert spec.source == []
    # end

    test "is_float/1" do
      spec =
        spec do
          x -> is_float(x)
        end

      assert spec.source == [{:"$1", [], [{:is_float, :"$1"}]}]
    end

    test "is_function/1" do
      spec =
        spec do
          x -> is_function(x)
        end

      assert spec.source == [{:"$1", [], [{:is_function, :"$1"}]}]
    end

    test "is_integer/1" do
      spec =
        spec do
          x -> is_integer(x)
        end

      assert spec.source == [{:"$1", [], [{:is_integer, :"$1"}]}]
    end

    test "is_list/1" do
      spec =
        spec do
          x -> is_list(x)
        end

      assert spec.source == [{:"$1", [], [{:is_list, :"$1"}]}]
    end

    test "is_map_key/2" do
      spec =
        spec do
          x -> is_map_key(x, :key)
        end

      assert spec.source == [{:"$1", [], [{:is_map_key, :key, :"$1"}]}]
    end

    test "is_map/1" do
      spec =
        spec do
          x -> is_map(x)
        end

      assert spec.source == [{:"$1", [], [{:is_map, :"$1"}]}]
    end

    test "is_nil/1" do
      spec =
        spec do
          x -> is_nil(x)
        end

      assert spec.source == [{:"$1", [], [{:==, :"$1", nil}]}]
    end

    test "is_number/1" do
      spec =
        spec do
          x -> is_number(x)
        end

      assert spec.source == [{:"$1", [], [{:is_number, :"$1"}]}]
    end

    test "is_pid/1" do
      spec =
        spec do
          x -> is_pid(x)
        end

      assert spec.source == [{:"$1", [], [{:is_pid, :"$1"}]}]
    end

    test "is_port/1" do
      spec =
        spec do
          x -> is_port(x)
        end

      assert spec.source == [{:"$1", [], [{:is_port, :"$1"}]}]
    end

    test "is_reference/1" do
      spec =
        spec do
          x -> is_reference(x)
        end

      assert spec.source == [{:"$1", [], [{:is_reference, :"$1"}]}]
    end

    # FIXME: handling of is_struct/1 in bodies
    # @tag :skip
    # test "is_struct/1" do
    #   spec =
    #     spec do
    #       x -> is_struct(x)
    #     end

    #   assert spec.source == [
    #            {
    #              :"$1",
    #              [
    #                {
    #                  :andalso,
    #                  {:andalso, {:is_map, :"$1"}, {:is_map_key, :__struct__, :"$1"}},
    #                  {:is_atom, {:map_get, :__struct__, :"$1"}}
    #                }
    #              ],
    #              [:"$1"]
    #            }
    #          ]
    # end

    # FIXME: handling of is_struct/2 in bodies
    # @tag :skip
    # test "is_struct/2" do
    #   spec =
    #     spec do
    #       x -> is_struct(x, Range)
    #     end

    #   assert spec.source == [
    #            {
    #              :"$1",
    #              [
    #                {
    #                  :andalso,
    #                  {
    #                    :andalso,
    #                    {:andalso, {:is_map, :"$1"}, {:orelse, {:is_atom, Range}, :fail}},
    #                    {:is_map_key, :__struct__, :"$1"}
    #                  },
    #                  {:==, {:map_get, :__struct__, :"$1"}, Range}
    #                }
    #              ],
    #              [:"$1"]
    #            }
    #          ]
    # end

    test "is_tuple/1" do
      spec =
        spec do
          x -> is_tuple(x)
        end

      assert spec.source == [{:"$1", [], [{:is_tuple, :"$1"}]}]
    end

    test "length/1" do
      spec =
        spec do
          x -> length(x)
        end

      assert spec.source == [{:"$1", [], [{:length, :"$1"}]}]
    end

    test "map_size/1" do
      spec =
        spec do
          x -> map_size(x)
        end

      assert spec.source == [{:"$1", [], [{:map_size, :"$1"}]}]
    end

    test "node/0" do
      spec =
        spec do
          x when x == 1 -> node()
        end

      assert spec.source == [{:"$1", [{:==, :"$1", 1}], [{:node}]}]
    end

    test "node/1" do
      spec =
        spec do
          x -> node(x)
        end

      assert spec.source == [{:"$1", [], [{:node, :"$1"}]}]
    end

    test "not/1" do
      spec =
        spec do
          x -> not x
        end

      assert spec.source == [{:"$1", [], [{:not, :"$1"}]}]
    end

    test "or/2" do
      spec =
        spec do
          x -> false or x
        end

      assert spec.source == [{:"$1", [], [{:orelse, false, :"$1"}]}]

      spec =
        spec do
          {x, y} -> x or y
        end

      assert spec.source == [{{:"$1", :"$2"}, [], [{:orelse, :"$1", :"$2"}]}]
    end

    test "rem/2" do
      spec =
        spec do
          x -> rem(x, 2)
        end

      assert spec.source == [{:"$1", [], [{:rem, :"$1", 2}]}]
    end

    test "round/1" do
      spec =
        spec do
          x -> round(x)
        end

      assert spec.source == [{:"$1", [], [{:round, :"$1"}]}]
    end

    test "self/0" do
      spec =
        spec do
          x when self() == x -> true
        end

      assert spec.source == [{:"$1", [{:==, {:self}, :"$1"}], [true]}]
    end

    test "tl/1" do
      spec =
        spec do
          _x -> tl([:one])
        end

      assert spec.source == [{:"$1", [], [{:tl, [:one]}]}]

      spec =
        spec do
          x -> tl(x)
        end

      assert spec.source == [{:"$1", [], [{:tl, :"$1"}]}]
    end

    test "trunc/1" do
      spec =
        spec do
          x -> trunc(x)
        end

      assert spec.source == [{:"$1", [], [{:trunc, :"$1"}]}]
    end
  end

  describe "in/2" do
    test "with compile-time lists/ranges" do
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

      spec =
        spec do
          x -> x in 1..3//2
        end

      assert spec.source == [
               {:"$1", [],
                [
                  {:andalso,
                   {:andalso, {:is_integer, :"$1"},
                    {:andalso, {:>=, :"$1", 1}, {:"=<", :"$1", 3}}},
                   {:"=:=", {:rem, {:-, :"$1", 1}, 2}, 0}}
                ]}
             ]

      spec =
        spec do
          x -> x in ?a..?z//2
        end

      assert spec.source == [
               {:"$1", [],
                [
                  {:andalso,
                   {:andalso, {:is_integer, :"$1"},
                    {:andalso, {:>=, :"$1", 97}, {:"=<", :"$1", 122}}},
                   {:"=:=", {:rem, {:-, :"$1", 97}, 2}, 0}}
                ]}
             ]
    end

    test "with dynamic argument", test_context do
      assert_raise ArgumentError, ~r"for operator \"in\"", fn ->
        defmodule test_module_name(test_context) do
          import Matcha

          spec do
            x -> 1 in x
          end
        end
      end
    end

    test "with non-list literal argument", test_context do
      assert_raise ArgumentError, ~r"for operator \"in\"", fn ->
        defmodule test_module_name(test_context) do
          import Matcha

          spec do
            x -> x in 1
          end
        end
      end
    end

    test "with non-literal Range argument", test_context do
      assert_raise ArgumentError, ~r"for operator \"in\"", fn ->
        defmodule test_module_name(test_context) do
          import Matcha

          spec do
            x -> x in %Range{left: 1, right: 2, step: 1}
          end
        end
      end
    end
  end

  describe "not in/2" do
    test "with compile-time lists/ranges" do
      spec =
        spec do
          x -> x not in [:one, :two, :three]
        end

      assert spec.source == [
               {:"$1", [],
                [
                  {:not,
                   {:orelse, {:orelse, {:"=:=", :"$1", :one}, {:"=:=", :"$1", :two}},
                    {:"=:=", :"$1", :three}}}
                ]}
             ]

      spec =
        spec do
          x -> x not in 1..3
        end

      assert spec.source == [
               {:"$1", [],
                [
                  {:not,
                   {:andalso, {:is_integer, :"$1"},
                    {:andalso, {:>=, :"$1", 1}, {:"=<", :"$1", 3}}}}
                ]}
             ]

      spec =
        spec do
          x -> x not in ?a..?z
        end

      assert spec.source == [
               {:"$1", [],
                [
                  {:not,
                   {:andalso, {:is_integer, :"$1"},
                    {:andalso, {:>=, :"$1", 97}, {:"=<", :"$1", 122}}}}
                ]}
             ]

      spec =
        spec do
          x -> x not in 1..3//2
        end

      assert spec.source == [
               {:"$1", [],
                [
                  {:not,
                   {:andalso,
                    {:andalso, {:is_integer, :"$1"},
                     {:andalso, {:>=, :"$1", 1}, {:"=<", :"$1", 3}}},
                    {:"=:=", {:rem, {:-, :"$1", 1}, 2}, 0}}}
                ]}
             ]

      spec =
        spec do
          x -> x not in ?a..?z//2
        end

      assert spec.source == [
               {:"$1", [],
                [
                  {:not,
                   {:andalso,
                    {:andalso, {:is_integer, :"$1"},
                     {:andalso, {:>=, :"$1", 97}, {:"=<", :"$1", 122}}},
                    {:"=:=", {:rem, {:-, :"$1", 97}, 2}, 0}}}
                ]}
             ]
    end

    test "with dynamic argument", test_context do
      assert_raise ArgumentError, ~r"for operator \"in\"", fn ->
        defmodule test_module_name(test_context) do
          import Matcha

          spec do
            x -> 1 not in x
          end
        end
      end
    end

    test "with non-list literal argument", test_context do
      assert_raise ArgumentError, ~r"for operator \"in\"", fn ->
        defmodule test_module_name(test_context) do
          import Matcha

          spec do
            x -> x not in 1
          end
        end
      end
    end

    test "with non-literal Range argument", test_context do
      assert_raise ArgumentError, ~r"for operator \"in\"", fn ->
        defmodule test_module_name(test_context) do
          import Matcha

          spec do
            x -> x not in %Range{left: 1, right: 2, step: 1}
          end
        end
      end
    end
  end

  describe "Bitwise guards" do
    test "band/2" do
      require Bitwise

      spec =
        spec do
          x -> Bitwise.band(x, 1)
        end

      assert spec.source == [{:"$1", [], [{:band, :"$1", 1}]}]

      spec =
        spec do
          x -> Bitwise.&&&(x, 1)
        end

      assert spec.source == [{:"$1", [], [{:band, :"$1", 1}]}]

      import Bitwise

      spec =
        spec do
          x -> band(x, 1)
        end

      assert spec.source == [{:"$1", [], [{:band, :"$1", 1}]}]

      spec =
        spec do
          x -> x &&& 1
        end

      assert spec.source == [{:"$1", [], [{:band, :"$1", 1}]}]
    end

    test "bor/2" do
      require Bitwise

      spec =
        spec do
          x -> Bitwise.bor(x, 1)
        end

      assert spec.source == [{:"$1", [], [{:bor, :"$1", 1}]}]

      spec =
        spec do
          x -> Bitwise.|||(x, 1)
        end

      assert spec.source == [{:"$1", [], [{:bor, :"$1", 1}]}]

      import Bitwise

      spec =
        spec do
          x -> bor(x, 1)
        end

      assert spec.source == [{:"$1", [], [{:bor, :"$1", 1}]}]

      spec =
        spec do
          x -> x ||| 1
        end

      assert spec.source == [{:"$1", [], [{:bor, :"$1", 1}]}]
    end

    test "bnot/1" do
      require Bitwise

      spec =
        spec do
          x -> Bitwise.bnot(x)
        end

      assert spec.source == [{:"$1", [], [{:bnot, :"$1"}]}]

      spec =
        spec do
          x -> Bitwise.~~~(x)
        end

      assert spec.source == [{:"$1", [], [{:bnot, :"$1"}]}]

      import Bitwise

      spec =
        spec do
          x -> bnot(x)
        end

      assert spec.source == [{:"$1", [], [{:bnot, :"$1"}]}]

      spec =
        spec do
          x -> ~~~x
        end

      assert spec.source == [{:"$1", [], [{:bnot, :"$1"}]}]
    end

    test "bsl/2" do
      require Bitwise

      spec =
        spec do
          x -> Bitwise.bsl(x, 1)
        end

      assert spec.source == [{:"$1", [], [{:bsl, :"$1", 1}]}]

      spec =
        spec do
          x -> Bitwise.<<<(x, 1)
        end

      assert spec.source == [{:"$1", [], [{:bsl, :"$1", 1}]}]

      import Bitwise

      spec =
        spec do
          x -> bsl(x, 1)
        end

      assert spec.source == [{:"$1", [], [{:bsl, :"$1", 1}]}]

      spec =
        spec do
          x -> x <<< 1
        end

      assert spec.source == [{:"$1", [], [{:bsl, :"$1", 1}]}]
    end

    test "bsr/2" do
      require Bitwise

      spec =
        spec do
          x -> Bitwise.bsr(x, 1)
        end

      assert spec.source == [{:"$1", [], [{:bsr, :"$1", 1}]}]

      spec =
        spec do
          x -> Bitwise.>>>(x, 1)
        end

      assert spec.source == [{:"$1", [], [{:bsr, :"$1", 1}]}]

      import Bitwise

      spec =
        spec do
          x -> bsr(x, 1)
        end

      assert spec.source == [{:"$1", [], [{:bsr, :"$1", 1}]}]

      spec =
        spec do
          x -> x >>> 1
        end

      assert spec.source == [{:"$1", [], [{:bsr, :"$1", 1}]}]
    end

    test "bxor/2" do
      require Bitwise

      spec =
        spec do
          x -> Bitwise.bxor(x, 1)
        end

      assert spec.source == [{:"$1", [], [{:bxor, :"$1", 1}]}]

      import Bitwise

      spec =
        spec do
          x -> bxor(x, 1)
        end

      assert spec.source == [{:"$1", [], [{:bxor, :"$1", 1}]}]
    end
  end
end
