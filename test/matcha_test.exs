defmodule MatchaTest do
  use ExUnit.Case, async: false
  # TODO: async: true
  # use ExUnit.Case, async: true

  require Record
  Record.defrecordp(:user, [:name, :age])

  import TestHelpers
  require Matcha

  doctest Matcha

  test "basic" do
    raw_spec =
      Matcha.spec :raw do
        x -> x
      end

    assert raw_spec.source == [{:"$1", [], [:"$1"]}]

    table_spec =
      Matcha.spec :table do
        x -> x
      end

    assert {:ok, {:returned, {:x}}} == Matcha.Spec.test(table_spec, {:x})

    trace_spec =
      Matcha.spec :trace do
        x -> x
      end

    assert {:ok, {:traced, true, []}} == Matcha.Spec.test(trace_spec, [:x])
  end

  test "full capture with `$_`" do
    raw_spec =
      Matcha.spec :raw do
        {x, x} = z -> z
      end

    assert raw_spec.source == [{{:"$1", :"$1"}, [], [:"$_"]}]

    table_spec =
      Matcha.spec :table do
        {x, x} = z -> z
      end

    assert {:ok, {:returned, {:x, :x}}} == Matcha.Spec.test(table_spec, {:x, :x})
    assert {:ok, {:returned, false}} == Matcha.Spec.test(table_spec, {:x, :y})
    assert {:ok, {:returned, false}} == Matcha.Spec.test(table_spec, {:other})

    # trace_spec =
    #   Matcha.spec :trace do
    #     {x, x} = z -> z
    #   end

    # assert {:ok, {:traced, true, []}} == Matcha.Spec.test(trace_spec, [{:x, :x}])
    # assert {:ok, {:traced, false, []}} == Matcha.Spec.test(trace_spec, [{:x, :y}])
    # assert {:ok, {:traced, false, []}} == Matcha.Spec.test(trace_spec, [{:other}])
  end

  test "gproc" do
    spec =
      Matcha.spec :raw do
        {{:n, :l, {:client, id}}, pid, _} -> {id, pid}
      end

    assert spec.source == [{{{:n, :l, {:client, :"$1"}}, :"$2", :_}, [], [{{:"$1", :"$2"}}]}]

    table_spec =
      Matcha.spec :table do
        {{:n, :l, {:client, id}}, pid, _} -> {id, pid}
      end

    assert {:ok, {:returned, {:id, :pid}}} ==
             Matcha.Spec.test(table_spec, {{:n, :l, {:client, :id}}, :pid, :other})

    # assert {:ok, {:returned, false}} == Matcha.Spec.test(table_spec, {:x, :y})
    # assert {:ok, {:returned, false}} == Matcha.Spec.test(table_spec, {:other})
  end

  test "gproc with bound variables" do
    id = 5

    spec =
      Matcha.spec :table do
        {{:n, :l, {:client, ^id}}, pid, _} -> pid
      end

    assert spec.source == [{{{:n, :l, {:client, 5}}, :"$1", :_}, [], [:"$1"]}]
  end

  test "gproc with 3 variables" do
    spec =
      Matcha.spec :table do
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
      Matcha.spec :table do
        {{:n, :l, {:client, ^one}}, pid, ^two} -> {one, pid}
      end

    self_pid = self()
    assert spec.source == [{{{:n, :l, {:client, 11}}, :"$1", 22}, [], [{{{:const, 11}, :"$1"}}]}]

    assert {:ok, {one, self_pid}} ===
             :ets.test_ms({{:n, :l, {:client, 11}}, self_pid, two}, spec.source)
  end

  test "simple boolean guard" do
    raw_spec =
      Matcha.spec :raw do
        _x when true -> 0
      end

    assert raw_spec.source == [{:"$1", [true], [0]}]

    table_spec =
      Matcha.spec :table do
        _x when true -> 0
      end

    assert {:ok, {:returned, 0}} == Matcha.Spec.test(table_spec, {1})

    trace_spec =
      Matcha.spec :trace do
        _x when true -> 0
      end

    assert {:ok, {:traced, true, []}} == Matcha.Spec.test(trace_spec, [1])
  end

  test "compound boolean guard" do
    raw_spec =
      Matcha.spec :raw do
        _x when true and false -> 0
      end

    assert raw_spec.source == [{:"$1", [{:andalso, true, false}], [0]}]

    table_spec =
      Matcha.spec :table do
        _x when true and false -> 0
      end

    assert {:ok, {:returned, false}} == Matcha.Spec.test(table_spec, {1})

    trace_spec =
      Matcha.spec :trace do
        _x when true and false -> 0
      end

    assert {:ok, {:traced, false, []}} == Matcha.Spec.test(trace_spec, [1])
  end

  test "actual guard" do
    raw_spec =
      Matcha.spec :raw do
        {x} when is_number(x) -> x
      end

    assert raw_spec.source == [{{:"$1"}, [{:is_number, :"$1"}], [:"$1"]}]

    table_spec =
      Matcha.spec :table do
        {x} when is_number(x) -> x
      end

    assert {:ok, {:returned, 1}} == Matcha.Spec.test(table_spec, {1})
  end

  test "multiple clauses" do
    spec =
      Matcha.spec :table do
        _x -> 0
        y -> y
      end

    assert spec.source == [{:"$1", [], [0]}, {:"$1", [], [:"$1"]}]
  end

  test "multiple exprs in body" do
    spec =
      Matcha.spec :table do
        x ->
          _ = 0
          x
      end

    assert spec.source == [{:"$1", [], [0, :"$1"]}]
  end

  test "custom guard macro" do
    spec =
      Matcha.spec :table do
        x when custom_guard(x) -> x
      end

    assert spec.source == [{:"$1", [{:andalso, {:>, :"$1", 3}, {:"/=", :"$1", 5}}], [:"$1"]}]
  end

  test "nested custom guard macro" do
    spec =
      Matcha.spec :table do
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
      Matcha.spec :table do
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

  test "invalid fun args" do
    assert_raise FunctionClauseError, fn ->
      delay_compile(Matcha.spec(:table, 123))
    end
  end

  test "test matching in spec matches" do
    spec =
      Matcha.spec :table do
        {x, y = x} -> {x, y}
      end

    assert spec.source == [{{:"$1", :"$1"}, [], [{{:"$1", :"$1"}}]}]

    spec =
      Matcha.spec :table do
        {x, y = z} -> {x, y, z}
      end

    assert spec.source == [{{:"$1", :"$2"}, [], [{{:"$1", :"$2", :"$2"}}]}]

    z = 33

    spec =
      Matcha.spec :table do
        {x, y = z} -> {x, y, z}
      end

    assert spec.source == [{{:"$1", 33}, [], [{{:"$1", {:const, 33}, {:const, 33}}}]}]

    match_already_bound = fn ->
      delay_compile(
        Matcha.spec :table do
          {x, y, y = x} -> {x, y}
        end
      )
    end

    assert_raise Matcha.Rewrite.Error, ~r"rewrite into guard later", match_already_bound
  end

  test "raise on invalid fun head" do
    multi_arity_spec = fn ->
      delay_compile(
        Matcha.spec :table do
          x, y -> {x, y}
        end
      )
    end

    assert_raise Matcha.Rewrite.Error, ~r"match spec clauses must be of arity 1", multi_arity_spec

    spec =
      Matcha.spec do
        123 -> 0
      end

    assert [0] = Matcha.Spec.run(spec, [123])
  end

  # These are actually working, but our delay_compile somehow swallows them
  @tag :skip
  test "unbound variables" do
    assert_raise CompileError, "undefined function y/0", fn ->
      delay_compile(
        Matcha.spec :table do
          x -> x = y
        end
      )
    end

    assert_raise CompileError, "undefined function y/0", fn ->
      delay_compile(
        Matcha.spec :table do
          x -> y
        end
      )
    end
  end

  # These are actually working, but our delay_compile somehow swallows them
  @tag :skip
  test "undefined functions" do
    assert_raise CompileError, "undefined function abc/1", fn ->
      delay_compile(
        Matcha.spec :table do
          x -> abc(x)
        end
      )
    end
  end

  test "record" do
    spec =
      Matcha.spec :table do
        user(age: x) = n when x > 18 -> n
      end

    assert spec.source == [{{:user, :_, :"$1"}, [{:>, :"$1", 18}], [:"$_"]}]

    x = 18

    spec =
      Matcha.spec :table do
        user(name: name, age: ^x) -> name
      end

    assert spec.source == [{{:user, :"$1", 18}, [], [:"$1"]}]

    # Records nils will be converted to :_, if nils are needed, we should explicitly match on it
    spec =
      Matcha.spec :table do
        user(age: age) = n when age == nil -> n
      end

    assert spec.source == [{{:user, :_, :"$1"}, [{:==, :"$1", nil}], [:"$_"]}]
  end

  test "composite bound variables in guards" do
    one = {1, 2, 3}

    spec =
      Matcha.spec :table do
        arg when arg < one -> arg
      end

    assert spec.source == [{:"$1", [{:<, :"$1", {:const, {1, 2, 3}}}], [:"$1"]}]
  end

  test "composite bound variables in return value" do
    bound = {1, 2, 3}

    spec =
      Matcha.spec :table do
        arg -> {bound, arg}
      end

    assert spec.source == [{:"$1", [], [{{{:const, {1, 2, 3}}, :"$1"}}]}]

    assert {:ok, {:returned, {bound, {:some, :record}}}} ==
             Matcha.Spec.test(spec, {:some, :record})
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
end
