defmodule Matcha.Context.Table.UnitTest do
  @moduledoc false

  use ExUnit.Case, async: true

  import Matcha

  test "basic table spec" do
    spec =
      spec(:table) do
        x -> x
      end

    assert {:ok, {:x}} == Matcha.Spec.call(spec, {:x})
  end
end
