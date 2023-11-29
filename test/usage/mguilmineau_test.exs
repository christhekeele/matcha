defmodule Mguilmineau.UsageTest do
  @moduledoc """
  Test suite derived from examples contributed by [`mguilmineau`](https://elixirforum.com/t/calling-all-matchspecs/44217/2).
  """

  use UsageTest

  import Matcha

  alias Matcha.Spec

  test "customer job matching", %{module: _module, test: _test} do
    customer = :customer
    job_a = "a"
    job_b = "b"

    _original_source = [
      {{{customer, :_}, {true, :"$1", :_, :"$2"}},
       [
         {:andalso, {:==, {:map_get, :a, {:map_get, :job, :"$2"}}, job_a},
          {:==, {:map_get, :b, {:map_get, :job, :"$2"}}, job_b}}
       ], [[:"$1", :"$2"]]}
    ]

    desired_source = [
      {{{customer, :_}, {true, :"$1", :_, :"$2"}},
       [
         {:andalso,
          {:andalso, {:==, {:map_get, :job, {:map_get, :a, :"$2"}}, {:const, job_a}},
           {:==, {:map_get, :job, {:map_get, :b, :"$2"}}, {:const, job_b}}},
          {:andalso,
           {:andalso,
            {:andalso,
             {:andalso,
              {:andalso, {:andalso, {:is_map, :"$2"}, {:is_map_key, :a, :"$2"}},
               {:is_map, {:map_get, :a, :"$2"}}}, {:is_map_key, :job, {:map_get, :a, :"$2"}}},
             {:is_map_key, :b, :"$2"}}, {:is_map, {:map_get, :b, :"$2"}}},
           {:is_map_key, :job, {:map_get, :b, :"$2"}}}}
       ], [[:"$1", :"$2"]]}
    ]

    spec =
      spec(:table) do
        {{^customer, _}, {true, var1, _, var2 = %{a: %{job: match_a}, b: %{job: match_b}}}}
        when match_a == job_a and match_b == job_b ->
          [var1, var2]
      end

    assert Spec.raw(spec) == desired_source
  end

  test "customer job deleting", %{module: _module, test: _test} do
    customer = :customer
    task_ids = [:task_1, :task_2]

    _original_source = [
      {{{customer, :_}, :"$1"}, [{:==, {:map_get, :id, :"$1"}, :task_1}], [true]},
      {{{customer, :_}, :"$1"}, [{:==, {:map_get, :id, :"$1"}, :task_2}], [true]}
    ]

    desired_source = [
      {{{customer, :_}, %{id: :"$1"}},
       [{:orelse, {:"=:=", :"$1", :task_1}, {:"=:=", :"$1", :task_2}}], [true]}
    ]

    # TODO: Can we trick the Elixir compiler into being happy with the
    #  "dynamic" `in/2` pre-expansion? Or make ^task_ids work?
    # spec =
    #   spec(:table) do
    #     {{customer, _}, %{id: matched_id}} when matched_id in task_ids ->
    #       true
    #   end

    spec =
      spec(:table) do
        {{^customer, _}, %{id: matched_id}} when matched_id in [:task_1, :task_2] ->
          true
      end

    assert Spec.raw(spec) == desired_source
  end

  test "customer date range selecting", %{module: _module, test: _test} do
    customer = :customer
    dets_date = :dets_date
    dets_tomorrow = :dets_tomorrow

    _original_source = [
      {{{customer, :_}, {:_, :"$1", :_, :"$2"}},
       [
         {:andalso, {:>=, :"$1", dets_date}, {:<, :"$1", dets_tomorrow}}
       ], [:"$2"]}
    ]

    desired_source = [
      {{{customer, :_}, {:_, :"$1", :_, :"$2"}},
       [
         {:andalso, {:>=, :"$1", {:const, dets_date}}, {:<, :"$1", {:const, dets_tomorrow}}}
       ], [:"$2"]}
    ]

    spec =
      spec(:table) do
        {{^customer, _}, {_, var1, _, var2}} when var1 >= dets_date and var1 < dets_tomorrow ->
          var2
      end

    assert Spec.raw(spec) == desired_source
  end

  test "customer job status select", %{module: _module, test: _test} do
    customer = :customer
    auto = :auto
    manual = :manual
    paused = :paused
    deleted = :deleted

    Enum.map([true, false], fn for_seeding ->
      _original_source = [
        {{{customer, :_}, :"$1", :"$2", :_, :_},
         [
           {:orelse, {:==, {:map_get, :reattempt, :"$1"}, auto},
            {:==, {:map_get, :reattempt, :"$1"}, manual}}
         ], [:"$1"]},
        {{{customer, :_}, :"$1", paused, :_, :_}, [], [:"$1"]},
        {{{customer, :_}, :"$1", deleted, :_, :_}, [], [:"$1"]},
        if for_seeding do
          {false, [], [true]}
        else
          {{{customer, :_}, :"$1", :_, :_, true}, [], [:"$1"]}
        end
      ]

      desired_source = [
        {{{customer, :_}, :"$1", :_, :_, :_},
         [
           {:andalso,
            {:orelse, {:"=:=", {:map_get, :reattempt, :"$1"}, auto},
             {:"=:=", {:map_get, :reattempt, :"$1"}, manual}},
            {:andalso, {:is_map, :"$1"}, {:is_map_key, :reattempt, :"$1"}}}
         ], [:"$1"]},
        {{{customer, :_}, :"$1", paused, :_, :_}, [], [:"$1"]},
        {{{customer, :_}, :"$1", deleted, :_, :_}, [], [:"$1"]},
        {{{customer, :_}, :"$1", :_, :_, true}, [], [:"$1"]}
      ]

      # TODO: Can we trick the Elixir compiler into being happy with the
      #  "dynamic" `in/2` pre-expansion? Or make [^auto, ^manual]  work?
      # spec =
      #   spec(:table) do
      #     {{^customer, _}, var1 = %{reattempt: reattempt}, _, _, _}
      #     when reattempt in [auto, manual] ->
      #       var1

      #     {{^customer, _}, var1, ^paused, _, _} ->
      #       var1

      #     {{^customer, _}, var1, ^deleted, _, _} ->
      #       var1

      #     {{^customer, _}, var1, _, _, true} ->
      #       var1
      #   end

      spec =
        spec(:table) do
          {{^customer, _}, var1 = %{reattempt: reattempt}, _, _, _}
          when reattempt in [:auto, :manual] ->
            var1

          {{^customer, _}, var1, ^paused, _, _} ->
            var1

          {{^customer, _}, var1, ^deleted, _, _} ->
            var1

          {{^customer, _}, var1, _, _, true} ->
            var1
        end

      assert Spec.raw(spec) == desired_source
    end)
  end
end
