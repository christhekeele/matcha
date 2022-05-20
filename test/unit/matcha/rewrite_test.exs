defmodule Matcha.Rewrite.Test do
  @moduledoc false

  use ExUnit.Case, async: true
  doctest Matcha.Rewrite

  require Record
  Record.defrecordp(:user, [:name, :age])

  import TestHelpers

  import Matcha

  test "basic spec rewrite" do
    spec =
      spec do
        x -> x
      end

    assert spec.source == [{:"$1", [], [:"$1"]}]
  end

  test "undefined functions", context do
    assert_raise CompileError, ~r"undefined function abc/1", fn ->
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

      assert spec.source == [{{:user, :_, :"$1"}, [{:>, :"$1", 18}], [:"$_"]}]
    end

    test "can use external vars" do
      x = 18

      spec =
        spec do
          user(name: name, age: ^x) -> name
        end

      assert spec.source == [{{:user, :"$1", 18}, [], [:"$1"]}]
    end

    test "can handle nils" do
      # Records nils will be converted to :_, if nils are needed, we should explicitly match on it
      spec =
        spec do
          user(age: age) = n when age == nil -> n
        end

      assert spec.source == [{{:user, :_, :"$1"}, [{:==, :"$1", nil}], [:"$_"]}]
    end
  end

  # TODO: structs
end
