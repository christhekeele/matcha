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

    test "size/1" do
      spec = Spec.from_source!([{{:"$1"}, [{:==, {:size, :"$1"}, 1}], [:"$1"]}])

      assert Spec.call!(spec, {{:one}}) == {:one}
      assert Spec.call!(spec, {{:one, :two}}) == false
      assert Spec.call!(spec, {"1"}) == "1"
      assert Spec.call!(spec, {"11"}) == false
      assert Spec.call!(spec, {:not_valid}) == false

      assert Spec.run!(spec, [
               {{:one}},
               {{:one, :two}},
               {"1"},
               {"11"},
               {:not_valid}
             ]) == [{:one}, "1"]

      spec = Spec.from_source!([{{:"$1"}, [], [{:size, :"$1"}]}])

      assert Spec.call!(spec, {{:one}}) == 1
      assert Spec.call!(spec, {{:one, :two}}) == 2
      assert Spec.call!(spec, {"1"}) == 1
      assert Spec.call!(spec, {"11"}) == 2
      assert Spec.call!(spec, {:not_valid}) == :EXIT

      assert Spec.run!(spec, [
               {{:one}},
               {{:one, :two}},
               {"1"},
               {"11"},
               {:not_valid}
             ]) == [1, 2, 1, 2, :EXIT]
    end

    test "xor/2" do
      spec = Spec.from_source!([{{:"$1", :"$2"}, [{:xor, :"$1", :"$2"}], [{{:"$1", :"$2"}}]}])

      assert Spec.call!(spec, {true, true}) == false
      assert Spec.call!(spec, {false, true}) == {false, true}
      assert Spec.call!(spec, {true, false}) == {true, false}
      assert Spec.call!(spec, {false, false}) == false
      assert Spec.call!(spec, {:not_boolean, :not_boolean}) == false

      assert Spec.run!(spec, [
               {true, true},
               {false, true},
               {true, false},
               {false, false},
               {:not_boolean, :not_boolean}
             ]) == [{false, true}, {true, false}]

      spec = Spec.from_source!([{{:"$1", :"$2"}, [], [{:xor, :"$1", :"$2"}]}])

      assert Spec.call!(spec, {true, true}) == false
      assert Spec.call!(spec, {false, true}) == true
      assert Spec.call!(spec, {true, false}) == true
      assert Spec.call!(spec, {false, false}) == false
      assert Spec.call!(spec, {:not_boolean, :not_boolean}) == :EXIT

      assert Spec.run!(spec, [
               {true, true},
               {false, true},
               {true, false},
               {false, false},
               {:not_boolean, :not_boolean}
             ]) == [false, true, true, false, :EXIT]
    end
  end
end
