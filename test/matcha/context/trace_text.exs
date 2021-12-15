defmodule Matcha.Context.Trace.Test do
  @moduledoc false

  use ExUnit.Case, async: true
  doctest Matcha.Context.Trace

  describe "action functions" do
    test "return_trace/0" do
      spec =
        Matcha.spec :trace do
          _ -> return_trace()
        end

      assert spec.source == [{:_, [], [{:return_trace}]}]
    end

    test "set_seq_token/2" do
      literal = 11

      spec =
        Matcha.spec :trace do
          {arg, ^literal} when arg == :foo -> set_seq_token(:label, arg)
        end

      assert spec.source == [
               {{:"$1", 11}, [{:==, :"$1", :foo}], [{:set_seq_token, :label, :"$1"}]}
             ]
    end
  end
end
