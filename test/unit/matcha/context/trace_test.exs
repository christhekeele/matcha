defmodule Matcha.Context.Trace.UnitTest do
  @moduledoc false

  use ExUnit.Case, async: true

  import Matcha

  test "basic trace spec" do
    spec =
      spec :trace do
        x -> x
      end

    assert {:ok, {:traced, true, []}} == Matcha.Spec.call(spec, [:x])
  end

  describe "action functions" do
    test "return_trace/0" do
      spec =
        spec :trace do
          _ -> return_trace()
        end

      assert spec.source == [{:_, [], [{:return_trace}]}]
    end

    test "set_seq_token/2" do
      literal = 11

      spec =
        spec :trace do
          {arg, ^literal} when arg == :foo -> set_seq_token(:label, arg)
        end

      assert spec.source == [
               {{:"$1", 11}, [{:==, :"$1", :foo}], [{:set_seq_token, :label, :"$1"}]}
             ]
    end
  end
end
