defmodule Matcha.Rewrite.Guards.UnitTest do
  @moduledoc """
  """

  use UnitTest

  require Record
  Record.defrecordp(:user, [:name, :age])

  import TestGuards
  import TestHelpers

  import Matcha

  alias Matcha.Spec

  defmodule Struct do
    defstruct [:x, :y, :z]
  end

  describe "literals" do
    test "boolean in guard" do
      spec =
        spec do
          _x when true -> 0
        end

      assert Spec.raw(spec) == [{:"$1", [true], [0]}]
    end

    test "atom in guard" do
      spec =
        spec do
          _x when :foo -> 0
        end

      assert Spec.raw(spec) == [{:"$1", [:foo], [0]}]
    end

    test "number in guard" do
      spec =
        spec do
          _x when 1 -> 0
        end

      assert Spec.raw(spec) == [{:"$1", [1], [0]}]
    end

    test "float in guard" do
      spec =
        spec do
          _x when 1.0 -> 0
        end

      assert Spec.raw(spec) == [{:"$1", [1.0], [0]}]
    end
  end

  test "multiple guard clauses" do
    spec =
      spec do
        x when x == 1 when x == 2 -> x
      end

    assert Spec.raw(spec) == [{:"$1", [{:==, :"$1", 1}, {:==, :"$1", 2}], [:"$1"]}]
  end

  test "custom guard macro" do
    spec =
      spec do
        x when custom_gt_3_neq_5_guard(x) -> x
      end

    assert Spec.raw(spec) == [
             {:"$1", [{:andalso, {:>, :"$1", 3}, {:"/=", :"$1", 5}}], [:"$1"]}
           ]
  end

  test "nested custom guard macro" do
    spec =
      spec do
        x when nested_custom_gt_3_neq_5_guard(x) -> x
      end

    assert Spec.raw(spec) == [
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

    assert Spec.raw(spec) == [{:"$1", [{:<, :"$1", {:const, {1, 2, 3}}}], [:"$1"]}]
  end

  describe "invalid calls in guards" do
    test "local calls", context do
      assert_raise CompileError, fn ->
        defmodule test_module_name(context) do
          import Matcha

          spec do
            x when meant_to_not_exist() -> x
          end
        end
      end
    end

    test "remote calls", context do
      assert_raise CompileError, fn ->
        defmodule test_module_name(context) do
          import Matcha

          spec do
            x when Module.meant_to_not_exist() -> x
          end
        end
      end
    end
  end

  describe "Kernel guards" do
    test "-/1" do
      spec =
        spec do
          x when x == -1 -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:==, :"$1", {:-, 1}}], [:"$1"]}]
    end

    test "-/2" do
      spec =
        spec do
          x when x - 1 == 0 -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:==, {:-, :"$1", 1}, 0}], [:"$1"]}]
    end

    test "!=/2" do
      spec =
        spec do
          x when x != 1.0 -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:"/=", :"$1", 1.0}], [:"$1"]}]
    end

    test "!==/2" do
      spec =
        spec do
          x when x !== 1.0 -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:"=/=", :"$1", 1.0}], [:"$1"]}]
    end

    test "*/2" do
      spec =
        spec do
          x when x * 2 == 4 -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:==, {:*, :"$1", 2}, 4}], [:"$1"]}]
    end

    test "//2" do
      spec =
        spec do
          x when x / 2 == 4 -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:==, {:/, :"$1", 2}, 4}], [:"$1"]}]
    end

    test "+/1" do
      spec =
        spec do
          x when x == +1 -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:==, :"$1", {:+, 1}}], [:"$1"]}]
    end

    test "+/2" do
      spec =
        spec do
          x when x + 2 == 4 -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:==, {:+, :"$1", 2}, 4}], [:"$1"]}]
    end

    test "</2" do
      spec =
        spec do
          x when x < 2 -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:<, :"$1", 2}], [:"$1"]}]
    end

    test "<=/2" do
      spec =
        spec do
          x when x <= 2 -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:"=<", :"$1", 2}], [:"$1"]}]
    end

    test "==/2" do
      spec =
        spec do
          x when x == 1.0 -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:==, :"$1", 1.0}], [:"$1"]}]
    end

    test "===/2" do
      spec =
        spec do
          x when x === 1.0 -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:"=:=", :"$1", 1.0}], [:"$1"]}]
    end

    test ">/2" do
      spec =
        spec do
          x when x > 2 -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:>, :"$1", 2}], [:"$1"]}]
    end

    test ">=/2" do
      spec =
        spec do
          x when x >= 2 -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:>=, :"$1", 2}], [:"$1"]}]
    end

    test "abs/1" do
      spec =
        spec do
          x when abs(x) == 1 -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:==, {:abs, :"$1"}, 1}], [:"$1"]}]
    end

    test "and/2" do
      spec =
        spec do
          _x when true and false -> 0
        end

      assert Spec.raw(spec) == [{:"$1", [{:andalso, true, false}], [0]}]

      spec =
        spec do
          {x, y} when x and y -> {x, y}
        end

      assert Spec.raw(spec) == [
               {{:"$1", :"$2"}, [{:andalso, :"$1", :"$2"}], [{{:"$1", :"$2"}}]}
             ]
    end

    if Matcha.Helpers.erlang_version() >= 25 do
      test "binary_part/3" do
        spec =
          spec do
            x when binary_part("abc", 1, 2) == "bc" -> x
          end

        assert Spec.raw(spec) == [{:"$1", [{:==, {:binary_part, "abc", 1, 2}, "bc"}], [:"$1"]}]

        spec =
          spec do
            string when binary_part(string, 1, 2) == "bc" -> string
          end

        assert Spec.raw(spec) == [{:"$1", [{:==, {:binary_part, :"$1", 1, 2}, "bc"}], [:"$1"]}]
      end
    end

    test "bit_size/1" do
      spec =
        spec do
          x when bit_size("abc") == 24 -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:==, {:bit_size, "abc"}, 24}], [:"$1"]}]

      spec =
        spec do
          string when bit_size(string) == 24 -> string
        end

      assert Spec.raw(spec) == [{:"$1", [{:==, {:bit_size, :"$1"}, 24}], [:"$1"]}]
    end

    if Matcha.Helpers.erlang_version() >= 25 do
      test "byte_size/1" do
        spec =
          spec do
            x when byte_size("abc") == 3 -> x
          end

        assert Spec.raw(spec) == [{:"$1", [{:==, {:byte_size, "abc"}, 3}], [:"$1"]}]

        spec =
          spec do
            string when byte_size(string) == 3 -> string
          end

        assert Spec.raw(spec) == [{:"$1", [{:==, {:byte_size, :"$1"}, 3}], [:"$1"]}]
      end
    end

    test "div/2" do
      spec =
        spec do
          x when div(8, 2) == 4 -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:==, {:div, 8, 2}, 4}], [:"$1"]}]

      spec =
        spec do
          x when div(x, 2) == 4 -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:==, {:div, :"$1", 2}, 4}], [:"$1"]}]
    end

    test "elem/2" do
      spec =
        spec do
          x when elem({:one}, 0) == :one -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:==, {:element, 1, {{:one}}}, :one}], [:"$1"]}]

      spec =
        spec do
          x when elem(x, 0) == :one -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:==, {:element, 1, :"$1"}, :one}], [:"$1"]}]
    end

    test "hd/1" do
      spec =
        spec do
          x when hd([:one]) == :one -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:==, {:hd, [:one]}, :one}], [:"$1"]}]

      spec =
        spec do
          x when hd(x) == :one -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:==, {:hd, :"$1"}, :one}], [:"$1"]}]
    end

    test "is_atom/1" do
      spec =
        spec do
          x when is_atom(x) -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:is_atom, :"$1"}], [:"$1"]}]
    end

    test "is_binary/1" do
      spec =
        spec do
          x when is_binary(x) -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:is_binary, :"$1"}], [:"$1"]}]
    end

    test "is_boolean/1" do
      spec =
        spec do
          x when is_boolean(x) -> x
        end

      assert Spec.raw(spec) == [
               {:"$1", [{:orelse, {:==, :"$1", true}, {:==, :"$1", false}}], [:"$1"]}
             ]
    end

    test "is_exception/1" do
      spec =
        spec do
          x when is_exception(x) -> x
        end

      assert Spec.raw(spec) == [
               {
                 :"$1",
                 [
                   {
                     :andalso,
                     {
                       :andalso,
                       {:andalso, {:andalso, {:is_map, :"$1"}, {:is_map_key, :__struct__, :"$1"}},
                        {:is_atom, {:map_get, :__struct__, :"$1"}}},
                       {:is_map_key, :__exception__, :"$1"}
                     },
                     {:==, {:map_get, :__exception__, :"$1"}, true}
                   }
                 ],
                 [:"$1"]
               }
             ]
    end

    test "is_exception/2" do
      spec =
        spec do
          x when is_exception(x, ArgumentError) -> x
        end

      assert Spec.raw(spec) == [
               {
                 :"$1",
                 [
                   {
                     :andalso,
                     {
                       :andalso,
                       {
                         :andalso,
                         {
                           :andalso,
                           {:andalso, {:is_map, :"$1"},
                            {:orelse, {:is_atom, ArgumentError}, :fail}},
                           {:is_map_key, :__struct__, :"$1"}
                         },
                         {:==, {:map_get, :__struct__, :"$1"}, ArgumentError}
                       },
                       {:is_map_key, :__exception__, :"$1"}
                     },
                     {:==, {:map_get, :__exception__, :"$1"}, true}
                   }
                 ],
                 [:"$1"]
               }
             ]
    end

    test "is_float/1" do
      spec =
        spec do
          x when is_float(x) -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:is_float, :"$1"}], [:"$1"]}]
    end

    test "is_function/1" do
      spec =
        spec do
          x when is_function(x) -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:is_function, :"$1"}], [:"$1"]}]
    end

    test "is_integer/1" do
      spec =
        spec do
          x when is_integer(x) -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:is_integer, :"$1"}], [:"$1"]}]
    end

    test "is_list/1" do
      spec =
        spec do
          x when is_list(x) -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:is_list, :"$1"}], [:"$1"]}]
    end

    test "is_map_key/2" do
      spec =
        spec do
          x when is_map_key(x, :key) -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:is_map_key, :key, :"$1"}], [:"$1"]}]
    end

    test "is_map/1" do
      spec =
        spec do
          x when is_map(x) -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:is_map, :"$1"}], [:"$1"]}]
    end

    test "is_nil/1" do
      spec =
        spec do
          x when is_nil(x) -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:==, :"$1", nil}], [:"$1"]}]
    end

    test "is_number/1" do
      spec =
        spec do
          x when is_number(x) -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:is_number, :"$1"}], [:"$1"]}]
    end

    test "is_pid/1" do
      spec =
        spec do
          x when is_pid(x) -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:is_pid, :"$1"}], [:"$1"]}]
    end

    test "is_port/1" do
      spec =
        spec do
          x when is_port(x) -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:is_port, :"$1"}], [:"$1"]}]
    end

    test "is_reference/1" do
      spec =
        spec do
          x when is_reference(x) -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:is_reference, :"$1"}], [:"$1"]}]
    end

    test "is_struct/1" do
      spec =
        spec do
          x when is_struct(x) -> x
        end

      assert Spec.raw(spec) == [
               {
                 :"$1",
                 [
                   {
                     :andalso,
                     {:andalso, {:is_map, :"$1"}, {:is_map_key, :__struct__, :"$1"}},
                     {:is_atom, {:map_get, :__struct__, :"$1"}}
                   }
                 ],
                 [:"$1"]
               }
             ]
    end

    test "is_struct/2" do
      spec =
        spec do
          x when is_struct(x, Range) -> x
        end

      assert Spec.raw(spec) == [
               {
                 :"$1",
                 [
                   {
                     :andalso,
                     {
                       :andalso,
                       {:andalso, {:is_map, :"$1"}, {:orelse, {:is_atom, Range}, :fail}},
                       {:is_map_key, :__struct__, :"$1"}
                     },
                     {:==, {:map_get, :__struct__, :"$1"}, Range}
                   }
                 ],
                 [:"$1"]
               }
             ]
    end

    test "is_tuple/1" do
      spec =
        spec do
          x when is_tuple(x) -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:is_tuple, :"$1"}], [:"$1"]}]
    end

    test "length/1" do
      spec =
        spec do
          x when length(x) == 1 -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:==, {:length, :"$1"}, 1}], [:"$1"]}]
    end

    test "map_size/1" do
      spec =
        spec do
          x when map_size(x) == 0 -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:==, {:map_size, :"$1"}, 0}], [:"$1"]}]
    end

    test "node/0" do
      spec =
        spec do
          x when node() == x -> true
        end

      assert Spec.raw(spec) == [{:"$1", [{:==, {:node}, :"$1"}], [true]}]
    end

    test "node/1" do
      spec =
        spec do
          x when node(self()) == x -> true
        end

      assert Spec.raw(spec) == [{:"$1", [{:==, {:node, {:self}}, :"$1"}], [true]}]
    end

    test "not/1" do
      spec =
        spec do
          x when not x -> x
        end

      assert Spec.raw(spec) == [{:"$1", [not: :"$1"], [:"$1"]}]
    end

    test "or/2" do
      spec =
        spec do
          x when false or x -> :success
        end

      assert Spec.raw(spec) == [{:"$1", [{:orelse, false, :"$1"}], [:success]}]
    end
  end

  test "rem/2" do
    spec =
      spec do
        x when rem(x, 2) == 0 -> x
      end

    assert Spec.raw(spec) == [{:"$1", [{:==, {:rem, :"$1", 2}, 0}], [:"$1"]}]
  end

  test "round/1" do
    spec =
      spec do
        x when round(x) == 0 -> x
      end

    assert Spec.raw(spec) == [{:"$1", [{:==, {:round, :"$1"}, 0}], [:"$1"]}]
  end

  test "self/0" do
    spec =
      spec do
        x when self() == x -> true
      end

    assert Spec.raw(spec) == [{:"$1", [{:==, {:self}, :"$1"}], [true]}]
  end

  test "tl/1" do
    spec =
      spec do
        x when tl([:one]) == [] -> x
      end

    assert Spec.raw(spec) == [{:"$1", [{:==, {:tl, [:one]}, []}], [:"$1"]}]

    spec =
      spec do
        x when tl(x) == [:one] -> x
      end

    assert Spec.raw(spec) == [{:"$1", [{:==, {:tl, :"$1"}, [:one]}], [:"$1"]}]
  end

  test "trunc/1" do
    spec =
      spec do
        x when trunc(x) == 0 -> x
      end

    assert Spec.raw(spec) == [{:"$1", [{:==, {:trunc, :"$1"}, 0}], [:"$1"]}]
  end

  if Matcha.Helpers.erlang_version() >= 26 do
    describe "Record guards" do
      test "is_record/1" do
        import Record, only: [is_record: 1]

        spec =
          spec do
            x when is_record(x) -> x
          end

        assert Spec.raw(spec) == [
                 {:"$1",
                  [
                    {:andalso, {:andalso, {:is_tuple, :"$1"}, {:>, {:tuple_size, :"$1"}, 0}},
                     {:is_atom, {:element, 1, :"$1"}}}
                  ], [:"$1"]}
               ]
      end

      test "is_record/2" do
        import Record, only: [is_record: 2]

        spec =
          spec do
            x when is_record(x, :user) -> x
          end

        assert Spec.raw(spec) == [
                 {
                   :"$1",
                   [
                     {
                       :andalso,
                       {:andalso, {:andalso, {:is_atom, :user}, {:is_tuple, :"$1"}},
                        {:>, {:tuple_size, :"$1"}, 0}},
                       {:==, {:element, 1, :"$1"}, :user}
                     }
                   ],
                   [:"$1"]
                 }
               ]
      end
    end
  end

  describe "in/2" do
    test "with compile-time lists/ranges" do
      spec =
        spec do
          x when x in [:one, :two, :three] -> x
        end

      assert Spec.raw(spec) == [
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

      assert Spec.raw(spec) == [
               {:"$1",
                [
                  {:andalso, {:is_integer, :"$1"}, {:andalso, {:>=, :"$1", 1}, {:"=<", :"$1", 3}}}
                ], [:"$1"]}
             ]

      spec =
        spec do
          x when x in ?a..?z -> x
        end

      assert Spec.raw(spec) == [
               {:"$1",
                [
                  {:andalso, {:is_integer, :"$1"},
                   {:andalso, {:>=, :"$1", 97}, {:"=<", :"$1", 122}}}
                ], [:"$1"]}
             ]

      spec =
        spec do
          x when x in 1..3//2 -> x
        end

      assert Spec.raw(spec) == [
               {:"$1",
                [
                  {:andalso,
                   {:andalso, {:is_integer, :"$1"},
                    {:andalso, {:>=, :"$1", 1}, {:"=<", :"$1", 3}}},
                   {:"=:=", {:rem, {:-, :"$1", 1}, 2}, 0}}
                ], [:"$1"]}
             ]

      spec =
        spec do
          x when x in ?a..?z//2 -> x
        end

      assert Spec.raw(spec) == [
               {:"$1",
                [
                  {:andalso,
                   {:andalso, {:is_integer, :"$1"},
                    {:andalso, {:>=, :"$1", 97}, {:"=<", :"$1", 122}}},
                   {:"=:=", {:rem, {:-, :"$1", 97}, 2}, 0}}
                ], [:"$1"]}
             ]
    end

    test "with dynamic argument", test_context do
      assert_raise ArgumentError, ~r"for operator \"in\"", fn ->
        defmodule test_module_name(test_context) do
          import Matcha

          spec do
            x when 1 in x -> x
          end
        end
      end
    end

    test "with non-list literal argument", test_context do
      assert_raise ArgumentError, ~r"for operator \"in\"", fn ->
        defmodule test_module_name(test_context) do
          import Matcha

          spec do
            x when x in 1 -> x
          end
        end
      end
    end

    test "with non-literal Range argument", test_context do
      assert_raise ArgumentError, ~r"for operator \"in\"", fn ->
        defmodule test_module_name(test_context) do
          import Matcha

          spec do
            x when x in %Range{left: 1, right: 2, step: 1} -> x
          end
        end
      end
    end
  end

  describe "not in/2" do
    test "with compile-time lists/ranges" do
      spec =
        spec do
          x when x not in [:one, :two, :three] -> x
        end

      assert Spec.raw(spec) == [
               {:"$1",
                [
                  not:
                    {:orelse, {:orelse, {:"=:=", :"$1", :one}, {:"=:=", :"$1", :two}},
                     {:"=:=", :"$1", :three}}
                ], [:"$1"]}
             ]

      spec =
        spec do
          x when x not in 1..3 -> x
        end

      assert Spec.raw(spec) == [
               {:"$1",
                [
                  not:
                    {:andalso, {:is_integer, :"$1"},
                     {:andalso, {:>=, :"$1", 1}, {:"=<", :"$1", 3}}}
                ], [:"$1"]}
             ]

      spec =
        spec do
          x when x not in ?a..?z -> x
        end

      assert Spec.raw(spec) == [
               {:"$1",
                [
                  not:
                    {:andalso, {:is_integer, :"$1"},
                     {:andalso, {:>=, :"$1", 97}, {:"=<", :"$1", 122}}}
                ], [:"$1"]}
             ]

      spec =
        spec do
          x when x not in 1..3//2 -> x
        end

      assert Spec.raw(spec) == [
               {:"$1",
                [
                  not:
                    {:andalso,
                     {:andalso, {:is_integer, :"$1"},
                      {:andalso, {:>=, :"$1", 1}, {:"=<", :"$1", 3}}},
                     {:"=:=", {:rem, {:-, :"$1", 1}, 2}, 0}}
                ], [:"$1"]}
             ]

      spec =
        spec do
          x when x not in ?a..?z//2 -> x
        end

      assert Spec.raw(spec) == [
               {:"$1",
                [
                  not:
                    {:andalso,
                     {:andalso, {:is_integer, :"$1"},
                      {:andalso, {:>=, :"$1", 97}, {:"=<", :"$1", 122}}},
                     {:"=:=", {:rem, {:-, :"$1", 97}, 2}, 0}}
                ], [:"$1"]}
             ]
    end

    test "with dynamic argument", test_context do
      assert_raise ArgumentError, ~r"for operator \"in\"", fn ->
        defmodule test_module_name(test_context) do
          import Matcha

          spec do
            x when 1 not in x -> x
          end
        end
      end
    end

    test "with non-list literal argument", test_context do
      assert_raise ArgumentError, ~r"for operator \"in\"", fn ->
        defmodule test_module_name(test_context) do
          import Matcha

          spec do
            x when x not in 1 -> x
          end
        end
      end
    end

    test "with non-literal Range argument", test_context do
      assert_raise ArgumentError, ~r"for operator \"in\"", fn ->
        defmodule test_module_name(test_context) do
          import Matcha

          spec do
            x when x not in %Range{left: 1, right: 2, step: 1} -> x
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
          x when Bitwise.band(x, 1) -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:band, :"$1", 1}], [:"$1"]}]

      spec =
        spec do
          x when Bitwise.&&&(x, 1) -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:band, :"$1", 1}], [:"$1"]}]

      import Bitwise

      spec =
        spec do
          x when band(x, 1) -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:band, :"$1", 1}], [:"$1"]}]

      spec =
        spec do
          x when x &&& 1 -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:band, :"$1", 1}], [:"$1"]}]
    end

    test "bor/2" do
      require Bitwise

      spec =
        spec do
          x when Bitwise.bor(x, 1) -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:bor, :"$1", 1}], [:"$1"]}]

      spec =
        spec do
          x when Bitwise.|||(x, 1) -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:bor, :"$1", 1}], [:"$1"]}]

      import Bitwise

      spec =
        spec do
          x when bor(x, 1) -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:bor, :"$1", 1}], [:"$1"]}]

      spec =
        spec do
          x when x ||| 1 -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:bor, :"$1", 1}], [:"$1"]}]
    end

    test "bnot/1" do
      require Bitwise

      spec =
        spec do
          x when Bitwise.bnot(x) -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:bnot, :"$1"}], [:"$1"]}]

      spec =
        spec do
          x when Bitwise.~~~(x) -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:bnot, :"$1"}], [:"$1"]}]

      import Bitwise

      spec =
        spec do
          x when bnot(x) -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:bnot, :"$1"}], [:"$1"]}]

      spec =
        spec do
          x when ~~~x -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:bnot, :"$1"}], [:"$1"]}]
    end

    test "bsl/2" do
      require Bitwise

      spec =
        spec do
          x when Bitwise.bsl(x, 1) -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:bsl, :"$1", 1}], [:"$1"]}]

      spec =
        spec do
          x when Bitwise.<<<(x, 1) -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:bsl, :"$1", 1}], [:"$1"]}]

      import Bitwise

      spec =
        spec do
          x when bsl(x, 1) -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:bsl, :"$1", 1}], [:"$1"]}]

      spec =
        spec do
          x when x <<< 1 -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:bsl, :"$1", 1}], [:"$1"]}]
    end

    test "bsr/2" do
      require Bitwise

      spec =
        spec do
          x when Bitwise.bsr(x, 1) -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:bsr, :"$1", 1}], [:"$1"]}]

      spec =
        spec do
          x when Bitwise.>>>(x, 1) -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:bsr, :"$1", 1}], [:"$1"]}]

      import Bitwise

      spec =
        spec do
          x when bsr(x, 1) -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:bsr, :"$1", 1}], [:"$1"]}]

      spec =
        spec do
          x when x >>> 1 -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:bsr, :"$1", 1}], [:"$1"]}]
    end

    test "bxor/2" do
      require Bitwise

      spec =
        spec do
          x when Bitwise.bxor(x, 1) -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:bxor, :"$1", 1}], [:"$1"]}]

      import Bitwise

      spec =
        spec do
          x when bxor(x, 1) -> x
        end

      assert Spec.raw(spec) == [{:"$1", [{:bxor, :"$1", 1}], [:"$1"]}]
    end
  end

  describe "structs (`%`):" do
    test "work" do
      struct = %Struct{x: 1, y: 2, z: 3}

      spec =
        spec do
          {struct} when struct == %Struct{x: 1, y: 2, z: 3} -> :ok
        end

      assert Spec.raw(spec) == [
               {
                 {%Matcha.Rewrite.Guards.UnitTest.Struct{x: 1, y: 2, z: 3}},
                 [
                   {:==, {:const, %Matcha.Rewrite.Guards.UnitTest.Struct{x: 1, y: 2, z: 3}},
                    %Matcha.Rewrite.Guards.UnitTest.Struct{x: 1, y: 2, z: 3}}
                 ],
                 [:ok]
               }
             ]
    end
  end
end
