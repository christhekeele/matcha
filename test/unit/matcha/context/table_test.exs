defmodule Matcha.Context.Table.Test do
  @moduledoc false

  use ExUnit.Case, async: true
  doctest Matcha.Context.Table

  import Matcha

  test "basic table spec" do
    spec =
      spec(:table) do
        x -> x
      end

    assert {:ok, {:x}} == Matcha.Spec.call(spec, {:x})
  end
end
