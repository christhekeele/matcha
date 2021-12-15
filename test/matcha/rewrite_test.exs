defmodule Matcha.Rewrite.Test do
  @moduledoc false

  use ExUnit.Case, async: true
  doctest Matcha.Rewrite

  require Record
  Record.defrecordp(:user, [:name, :age])

  import TestHelpers

  require Matcha

  test "basic filter_map spec rewrite" do
    spec =
      Matcha.spec do
        x -> x
      end

    assert spec.source == [{:"$1", [], [:"$1"]}]

    assert {:ok, {:returned, :x}} == Matcha.Spec.run(spec, :x)
  end

  test "basic table spec rewrite" do
    spec =
      Matcha.spec do
        x -> x
      end

    assert spec.source == [{:"$1", [], [:"$1"]}]

    assert {:ok, {:returned, {:x}}} == Matcha.Spec.run(spec, {:x})
  end

  test "basic trace spec rewrite" do
    spec =
      Matcha.spec :trace do
        x -> x
      end

    assert spec.source == [{:"$1", [], [:"$1"]}]

    assert {:ok, {:traced, true, []}} == Matcha.Spec.run(spec, [:x])
  end

  #
  #
  #
  #

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
