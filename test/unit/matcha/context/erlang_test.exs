defmodule Matcha.Context.Erlang.UnitTest do
  @moduledoc """
  Exercises auto-generated functions just to ensure
  the meta-programming of the no-ops is correct.
  """

  use ExUnit.Case, async: true
  @moduletag :unit

  import TestHelpers

  describe "no-op functions" do
    for {function, arity} <- module_importable_functions(Matcha.Context.Erlang) do
      arguments = Enum.drop(0..arity, 1)

      test "#{function}/#{arity}" do
        assert unquote({{:., [], [Matcha.Context.Erlang, function]}, [], arguments}) == :noop
      end
    end
  end
end
