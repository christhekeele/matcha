defmodule Matcha.Rewrite.UnitTest do
  @moduledoc false

  use UnitTest

  require Record
  Record.defrecordp(:user, [:name, :age])

  import TestHelpers

  import Matcha

  alias Matcha.Spec

  test "basic spec rewrite" do
    spec =
      spec do
        x -> x
      end

    assert Spec.raw(spec) == [{:"$1", [], [:"$1"]}]
  end

  test "multiple clauses" do
    spec =
      spec do
        _x -> 0
        y -> y
      end

    assert Spec.raw(spec) == [{:"$1", [], [0]}, {:"$1", [], [:"$1"]}]
  end

  test "undefined functions", context do
    assert_raise CompileError, fn ->
      defmodule test_module_name(context) do
        spec do
          x -> abc(x)
        end
      end
    end
  end

  describe "records" do
    test "can be destructured" do
      spec =
        spec do
          user(age: x) = n when x > 18 -> n
        end

      assert Spec.raw(spec) == [{{:user, :_, :"$1"}, [{:>, :"$1", 18}], [:"$_"]}]
    end

    test "can use external vars" do
      x = 18

      spec =
        spec do
          user(name: name, age: ^x) -> name
        end

      assert Spec.raw(spec) == [{{:user, :"$1", 18}, [], [:"$1"]}]
    end

    test "can handle nils" do
      # Records nils will be converted to :_, if nils are needed, we should explicitly match on it
      spec =
        spec do
          user(age: age) = n when age == nil -> n
        end

      assert Spec.raw(spec) == [{{:user, :_, :"$1"}, [{:==, :"$1", nil}], [:"$_"]}]
    end
  end

  test "can handle sigils" do
    spec =
      spec do
        x when x == ~w[one two three]a -> x
      end

    assert Spec.raw(spec) == [{:"$1", [{:==, :"$1", [:one, :two, :three]}], [:"$1"]}]

    spec =
      spec do
        x when x in ~w[one two three]a -> x
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
        x -> x in ~w[one two three]a
      end

    assert Spec.raw(spec) == [
             {:"$1", [],
              [
                {:orelse, {:orelse, {:"=:=", :"$1", :one}, {:"=:=", :"$1", :two}},
                 {:"=:=", :"$1", :three}}
              ]}
           ]

    spec =
      spec do
        x -> x in ~w[one two three]a
      end

    assert Spec.raw(spec) == [
             {:"$1", [],
              [
                {:orelse, {:orelse, {:"=:=", :"$1", :one}, {:"=:=", :"$1", :two}},
                 {:"=:=", :"$1", :three}}
              ]}
           ]
  end

  # TODO: test structs
end
