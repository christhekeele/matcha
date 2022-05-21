defmodule Matcha.Rewrite.Kernel.UnitTest do
  @moduledoc false

  use ExUnit.Case, async: true

  import Matcha

  test "is_boolean/1" do
    expected_source = [
      {:"$1", [{:andalso, {:is_atom, :"$1"}, {:orelse, {:==, :"$1", true}, {:==, :"$1", false}}}],
       [:"$1"]}
    ]

    spec =
      spec(:match) do
        x when is_boolean(x) -> x
      end

    assert spec.source == expected_source

    assert Matcha.Spec.call(spec, true) == {:ok, {:matched, true}}
    assert Matcha.Spec.call(spec, false) == {:ok, {:matched, false}}
    assert Matcha.Spec.call(spec, nil) == {:ok, :no_match}

    assert Matcha.Spec.run(spec, [true, false, nil]) ==
             {:ok, [{:matched, true}, {:matched, false}, :no_match]}
  end
end
