defmodule ErlangGuards.UsageTest do
  @moduledoc false

  use UsageTest

  alias Matcha.Spec

  describe ":erlang guards" do
    # NOTE: you'd think erlang could handle this, but it does not.
    #       likely related to https://github.com/elixir-lang/elixir/blob/f4b05d178d7b9bb5356beae7ef8e01c32324d476/lib/elixir/src/elixir_rewrite.erl#L337-L338
    # test "is_record/2", test_context do
    #   spec = Spec.from_source!([{:"$1", [{:is_record, :"$1", :record_tag}], [:"$1"]}])

    #   assert Spec.call!(spec, {:record_tag, :foo}) == {:record_tag, :foo}
    #   assert Spec.call!(spec, {:not_record_tag, :foo}) == false

    #   assert Spec.run!(spec, [
    #            {:record_tag, :foo},
    #            {:not_record_tag, :foo}
    #          ]) == [{:record_tag, :foo}]

    #   spec = Spec.from_source!([{:"$1", [], [{:is_record, :"$1", :record_tag}]}])

    #   assert Spec.call!(spec, {:record_tag, :foo}) == true
    #   assert Spec.call!(spec, {:not_record_tag, :foo}) == false

    #   assert Spec.run!(spec, [
    #            {:record_tag, :foo},
    #            {:not_record_tag, :foo}
    #          ]) == [true, false]
    # end

    test "is_record/3" do
      spec = Spec.from_source!([{:"$1", [{:is_record, :"$1", :record_tag, 2}], [:"$1"]}])

      assert Spec.call!(spec, {:record_tag, :foo}) == {:record_tag, :foo}
      assert Spec.call!(spec, {:record_tag, :foo, :bar}) == false
      assert Spec.call!(spec, {:not_record_tag, :foo}) == false

      assert Spec.run!(spec, [
               {:record_tag, :foo},
               {:record_tag, :foo, :bar},
               {:not_record_tag, :foo}
             ]) == [{:record_tag, :foo}]

      spec = Spec.from_source!([{:"$1", [], [{:is_record, :"$1", :record_tag, 2}]}])

      assert Spec.call!(spec, {:record_tag, :foo}) == true
      assert Spec.call!(spec, {:record_tag, :foo, :bar}) == false
      assert Spec.call!(spec, {:not_record_tag, :foo}) == false

      assert Spec.run!(spec, [
               {:record_tag, :foo},
               {:record_tag, :foo, :bar},
               {:not_record_tag, :foo}
             ]) == [true, false, false]
    end
  end
end
