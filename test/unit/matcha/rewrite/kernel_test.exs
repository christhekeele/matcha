defmodule Matcha.Rewrite.Kernel.Test do
  @moduledoc false

  use ExUnit.Case, async: true
  doctest Matcha.Rewrite.Kernel

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

  test "tmp filter_map test" do
    expected_source = [
      {:"$1", [{:andalso, {:is_atom, :"$1"}, {:orelse, {:==, :"$1", true}, {:==, :"$1", false}}}],
       [:"$1"]}
    ]

    spec =
      spec(:filter_map) do
        x when is_boolean(x) -> x
      end

    assert spec.source == expected_source

    assert Matcha.Spec.call(spec, true) == {:ok, true}
    assert Matcha.Spec.call(spec, false) == {:ok, false}
    assert Matcha.Spec.call(spec, nil) == {:ok, nil}
    assert Matcha.Spec.call(spec, 1) == {:ok, nil}

    assert Matcha.Spec.run(spec, [true, false, nil]) ==
             {:ok, [true, false]}
  end
end
