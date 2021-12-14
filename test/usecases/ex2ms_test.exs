defmodule Ex2msTest do
  @moduledoc """
  Test suite derived from ex2ms (https://github.com/ericmj/ex2ms)
  """

  use ExUnit.Case, async: true

  require Record
  Record.defrecordp(:user, [:name, :age])

  import TestGuards
  import TestHelpers

  require Matcha

  test "basic" do
    raw_spec =
      Matcha.spec do
        x -> x
      end

    assert raw_spec.source == [{:"$1", [], [:"$1"]}]

    table_spec =
      Matcha.spec do
        x -> x
      end

    assert {:ok, {:returned, {:x}}} == Matcha.Spec.run(table_spec, {:x})

    trace_spec =
      Matcha.spec :trace do
        x -> x
      end

    assert {:ok, {:traced, true, []}} == Matcha.Spec.run(trace_spec, [:x])
  end

  test "full capture with `$_`" do
    raw_spec =
      Matcha.spec do
        {x, x} = z -> z
      end

    assert raw_spec.source == [{{:"$1", :"$1"}, [], [:"$_"]}]

    table_spec =
      Matcha.spec do
        {x, x} = z -> z
      end

    assert {:ok, {:returned, {:x, :x}}} == Matcha.Spec.run(table_spec, {:x, :x})
    assert {:ok, {:returned, false}} == Matcha.Spec.run(table_spec, {:x, :y})
    assert {:ok, {:returned, false}} == Matcha.Spec.run(table_spec, {:other})

    # trace_spec =
    #   Matcha.spec :trace do
    #     {x, x} = z -> z
    #   end

    # assert {:ok, {:traced, true, []}} == Matcha.Spec.run(trace_spec, [{:x, :x}])
    # assert {:ok, {:traced, false, []}} == Matcha.Spec.run(trace_spec, [{:x, :y}])
    # assert {:ok, {:traced, false, []}} == Matcha.Spec.run(trace_spec, [{:other}])
  end

  test "gproc" do
    spec =
      Matcha.spec do
        {{:n, :l, {:client, id}}, pid, _} -> {id, pid}
      end

    assert spec.source == [{{{:n, :l, {:client, :"$1"}}, :"$2", :_}, [], [{{:"$1", :"$2"}}]}]

    table_spec =
      Matcha.spec do
        {{:n, :l, {:client, id}}, pid, _} -> {id, pid}
      end

    assert {:ok, {:returned, {:id, :pid}}} ==
             Matcha.Spec.run(table_spec, {{:n, :l, {:client, :id}}, :pid, :other})

    # assert {:ok, {:returned, false}} == Matcha.Spec.run(table_spec, {:x, :y})
    # assert {:ok, {:returned, false}} == Matcha.Spec.run(table_spec, {:other})
  end

  test "gproc with bound variables" do
    id = 5

    spec =
      Matcha.spec do
        {{:n, :l, {:client, ^id}}, pid, _} -> pid
      end

    assert spec.source == [{{{:n, :l, {:client, 5}}, :"$1", :_}, [], [:"$1"]}]
  end

  test "gproc with 3 variables" do
    spec =
      Matcha.spec do
        {{:n, :l, {:client, id}}, pid, third} -> {id, pid, third}
      end

    assert spec.source == [
             {{{:n, :l, {:client, :"$1"}}, :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}
           ]
  end

  test "gproc with 1 variable and 2 bound variables" do
    one = 11
    two = 22

    spec =
      Matcha.spec do
        {{:n, :l, {:client, ^one}}, pid, ^two} -> {one, pid}
      end

    self_pid = self()
    assert spec.source == [{{{:n, :l, {:client, 11}}, :"$1", 22}, [], [{{{:const, 11}, :"$1"}}]}]

    assert {:ok, {one, self_pid}} ===
             :ets.test_ms({{:n, :l, {:client, 11}}, self_pid, two}, spec.source)
  end

  test "simple boolean guard" do
    raw_spec =
      Matcha.spec do
        _x when true -> 0
      end

    assert raw_spec.source == [{:"$1", [true], [0]}]

    table_spec =
      Matcha.spec do
        _x when true -> 0
      end

    assert {:ok, {:returned, 0}} == Matcha.Spec.run(table_spec, {1})

    trace_spec =
      Matcha.spec :trace do
        _x when true -> 0
      end

    assert {:ok, {:traced, true, []}} == Matcha.Spec.run(trace_spec, [1])
  end

  test "compound boolean guard" do
    raw_spec =
      Matcha.spec do
        _x when true and false -> 0
      end

    assert raw_spec.source == [{:"$1", [{:andalso, true, false}], [0]}]

    table_spec =
      Matcha.spec do
        _x when true and false -> 0
      end

    assert {:ok, {:returned, false}} == Matcha.Spec.run(table_spec, {1})

    trace_spec =
      Matcha.spec :trace do
        _x when true and false -> 0
      end

    assert {:ok, {:traced, false, []}} == Matcha.Spec.run(trace_spec, [1])
  end

  test "actual guard" do
    raw_spec =
      Matcha.spec do
        {x} when is_number(x) -> x
      end

    assert raw_spec.source == [{{:"$1"}, [{:is_number, :"$1"}], [:"$1"]}]

    table_spec =
      Matcha.spec do
        {x} when is_number(x) -> x
      end

    assert {:ok, {:returned, 1}} == Matcha.Spec.run(table_spec, {1})
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
  end

  test "multiple exprs in body" do
    spec =
      Matcha.spec do
        x ->
          _ = 0
          x
      end

    assert spec.source == [{:"$1", [], [0, :"$1"]}]
  end

  test "custom guard macro" do
    spec =
      Matcha.spec do
        x when custom_guard(x) -> x
      end

    assert spec.source == [{:"$1", [{:andalso, {:>, :"$1", 3}, {:"/=", :"$1", 5}}], [:"$1"]}]
  end

  test "nested custom guard macro" do
    spec =
      Matcha.spec do
        x when nested_custom_guard(x) -> x
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
  end

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

    assert [2] == Matcha.Spec.filter_map(spec, [%{x: 2}])
  end

  test "invalid fun args", context do
    assert_raise FunctionClauseError, fn ->
      defmodule test_module_name(context) do
        Matcha.spec(:table, 123)
      end
    end
  end

  test "test matching in spec matches" do
    spec =
      Matcha.spec do
        {x, y = x} -> {x, y}
      end

    assert spec.source == [{{:"$1", :"$1"}, [], [{{:"$1", :"$1"}}]}]

    spec =
      Matcha.spec do
        {x, y = z} -> {x, y, z}
      end

    assert spec.source == [{{:"$1", :"$2"}, [], [{{:"$1", :"$2", :"$2"}}]}]

    z = 33

    spec =
      Matcha.spec do
        {x, y = z} -> {x, y, z}
      end

    assert spec.source == [{{:"$1", 33}, [], [{{:"$1", {:const, 33}, {:const, 33}}}]}]

    spec =
      Matcha.spec do
        {x, y, y = x} -> {x, y}
      end

    assert spec.source == [{{:"$2", :"$2", :"$2"}, [], [{{:"$2", :"$2"}}]}]

    # TODO: think about if we should allow this
    # spec =
    #   Matcha.spec do
    #     {x, y = 33} -> {x, y}
    #   end

    # assert spec.source == [{{:"$1", 33}, [], [{{:"$1", 33}}]}]
  end

  test "raise on invalid fun head", context do
    multi_arity_spec = fn ->
      defmodule test_module_name(context) do
        Matcha.spec do
          x, y -> {x, y}
        end
      end
    end

    assert_raise Matcha.Rewrite.Error, ~r"match spec clauses must be of arity 1", multi_arity_spec

    spec =
      Matcha.spec do
        123 -> 0
      end

    assert [0] = Matcha.Spec.filter_map(spec, [123])
  end

  describe "unbound variables" do
    test "in body", context do
      assert_raise CompileError, ~r"undefined function y/0", fn ->
        defmodule test_module_name(context) do
          Matcha.spec do
            x -> y
          end
        end
      end
    end

    test "in body when matched from", context do
      assert_raise CompileError, ~r"undefined function y/0", fn ->
        defmodule test_module_name(context) do
          Matcha.spec do
            x -> x = y
          end
        end
      end
    end

    test "in body when assigned to", context do
      assert_raise Matcha.Rewrite.Error, ~r"variable `y` was not bound in the match head", fn ->
        defmodule test_module_name(context) do
          Matcha.spec do
            x -> y = x
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
                         x ->
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
                         x ->
                           {:foo} = {:foo}
                       end
                     end
                   end
    end
  end

  test "undefined functions", context do
    assert_raise CompileError, ~r"undefined function abc/1", fn ->
      defmodule test_module_name(context) do
        Matcha.spec do
          x -> abc(x)
        end
      end
    end
  end

  test "record" do
    spec =
      Matcha.spec do
        user(age: x) = n when x > 18 -> n
      end

    assert spec.source == [{{:user, :_, :"$1"}, [{:>, :"$1", 18}], [:"$_"]}]

    x = 18

    spec =
      Matcha.spec do
        user(name: name, age: ^x) -> name
      end

    assert spec.source == [{{:user, :"$1", 18}, [], [:"$1"]}]

    # Records nils will be converted to :_, if nils are needed, we should explicitly match on it
    spec =
      Matcha.spec do
        user(age: age) = n when age == nil -> n
      end

    assert spec.source == [{{:user, :_, :"$1"}, [{:==, :"$1", nil}], [:"$_"]}]
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

  test "action function" do
    spec =
      Matcha.spec :trace do
        _ -> return_trace()
      end

    assert spec.source == [{:_, [], [{:return_trace}]}]

    # action functions with arguments get turned into :atom, args... tuples
    literal = 11

    spec =
      Matcha.spec :trace do
        {arg, ^literal} when arg == :foo -> set_seq_token(:label, arg)
      end

    assert spec.source == [{{:"$1", 11}, [{:==, :"$1", :foo}], [{:set_seq_token, :label, :"$1"}]}]
  end

  # TODO: structs
  # TODO: raise on inner bindings, ie the 'd' in {a, b = %{c: d}}, or
  # spec =
  #   Matcha.spec do
  #     {a, b = {a, d}} -> {b, d}
  #   end
end
