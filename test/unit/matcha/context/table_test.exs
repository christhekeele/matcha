defmodule Matcha.Context.Table.UnitTest do
  @moduledoc false

  use UnitTest

  import Matcha
  import TestHelpers

  describe "no-op functions" do
    for {function, arity} <- module_importable_functions(Matcha.Context.Table) do
      arguments = Enum.drop(0..arity, 1)

      test "#{function}/#{arity}" do
        assert unquote({{:., [], [Matcha.Context.Table, function]}, [], arguments}) == :noop
      end
    end
  end

  test "basic table spec" do
    spec =
      spec(:table) do
        x -> x
      end

    assert {:ok, {:x}} == Matcha.Spec.call(spec, {:x})
  end
end
