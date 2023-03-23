defmodule Mguilmineau.UsageTest do
  @moduledoc """
  Test suite derived from examples contributed by [`mguilmineau`](https://elixirforum.com/t/calling-all-matchspecs/44217/2).
  """

  use UsageTest

  import Matcha

  # TODO: investigate map binding expansion via map_get automatically
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
      {
        {{:customer, :_}, {true, :"$1", :_, :"$2"}},
        [
          {
            :andalso,
            {:==, {:map_get, :job, {:map_get, :a, :"$2"}}, {:const, job_a}},
            {:==, {:map_get, :job, {:map_get, :b, :"$2"}}, {:const, job_b}}
          }
        ],
        [[:"$1", :"$2"]]
      }
    ]

    # _desired_spec =
    #   spec(:table) do
    #     {{^customer, _}, {true, var1, _, var2 = %{a: %{job: match_a}, b: %{job: match_b}}}}
    #     when match_a == job_a and match_b == job_b ->
    #       [var1, var2]
    #   end

    spec =
      spec(:table) do
        {{^customer, _}, {true, var1, _, var2}}
        when :erlang.map_get(:job, :erlang.map_get(:a, var2)) == job_a and
               :erlang.map_get(:job, :erlang.map_get(:b, var2)) == job_b ->
          [var1, var2]
      end

    assert spec.source == desired_source
  end

  # TODO: investigate map binding expansion via map_get automatically
  test "customer job deleting", %{module: _module, test: _test} do
    customer = :customer
    task_ids = [:task_1, :task_2]

    _original_spec =
      for task_id <- task_ids do
        {{{customer, :_}, :"$1"}, [{:==, {:map_get, :id, :"$1"}, task_id}], [true]}
      end

    desired_source =
      for task_id <- task_ids do
        {{{customer, :_}, :"$1"}, [{:==, {:map_get, :id, :"$1"}, task_id}], [true]}
      end

    # _desired_spec =
    #   spec(:table) do
    #     for task_id <- task_ids do
    #       {{customer, _}, %{id: matched_id}} when matched_id == task_id ->
    #         true
    #     end
    #   end

    _original_source = [
      {{{customer, :_}, :"$1"}, [{:==, {:map_get, :id, :"$1"}, :task_id}], [true]}
    ]

    desired_source = [{{{:customer, :_}, %{id: :"$1"}}, [{:==, :"$1", :task_id}], [true]}]

    spec =
      spec(:table) do
        {{^customer, _}, %{id: matched_id}} when matched_id == :task_id ->
          true
      end

    assert spec.source == desired_source
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

    assert spec.source == desired_source

    # :ets.select(ets_name(customer), desired_source)
    # :ets.select(ets_name(customer), spec.source)
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
        {
          {{:customer, :_}, :"$1", :_, :_, :_},
          [
            {
              :orelse,
              {:==, {:map_get, :reattempt, :"$1"}, {:const, :auto}},
              {:==, {:map_get, :reattempt, :"$1"}, {:const, :manual}}
            }
          ],
          [:"$1"]
        },
        {{{:customer, :_}, :"$1", :paused, :_, :_}, [], [:"$1"]},
        {{{:customer, :_}, :"$1", :deleted, :_, :_}, [], [:"$1"]},
        {{{:customer, :_}, :"$1", :_, :_, true}, [], [:"$1"]}
      ]

      # desired_spec =
      #   spec(:table) do
      #     {{^customer, _}, var1 = %{reattempt: reattempt}, _, _, _}
      #     when reattempt in [:auto, :manual] ->
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
          {{^customer, _}, var1, _, _, _}
          when :erlang.map_get(:reattempt, var1) == auto or
                 :erlang.map_get(:reattempt, var1) == manual ->
            var1

          {{^customer, _}, var1, ^paused, _, _} ->
            var1

          {{^customer, _}, var1, ^deleted, _, _} ->
            var1

          {{^customer, _}, var1, _, _, true} ->
            var1
        end

      assert spec.source == desired_source
    end)

    # :ets.select(ets_name(customer), desired_source)
    # :ets.select(ets_name(customer), spec.source)
  end
end
