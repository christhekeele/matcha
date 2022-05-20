defmodule Matcha.Context.FilterMap do
  @moduledoc """
  Functions and operators that filter map match specs can use in their bodies.

  ???

  Specs created in this context are unique in that they can differentiate
  between specs that fail to find a matching clause for the given input,
  and specs with matching clauses that literally return the `false` value.
  They return `:no_return` in the former case, and `{:matched, result}` tuples in the latter,
  where `result` can be a literal `false` returned from a clause.

  No additional functions besides those defined in `Matcha.Context.Common` can be used in this context.
  """

  alias Matcha.Context
  alias Matcha.Source

  use Context

  ###
  # CALLBACKS
  ##

  @impl Context
  def __erl_type__ do
    :table
  end

  @impl Context
  def __default_match_target__ do
    nil
  end

  @impl Context
  def __valid_match_target__(_match_target) do
    true
  end

  @impl Context
  def __invalid_match_target_error_message__(_match_target) do
    ""
  end

  @impl Context
  def __prepare_source__(source) do
    {:ok,
     for {match, guards, body} <- source do
       {last_expr, body} = List.pop_at(body, -1)
       body = [body | [{{:returned, last_expr}}]]
       {match, guards, body}
     end}
  end

  @impl Context
  def __emit_erl_test_result__({:returned, result}) do
    [result]
  end

  def __emit_erl_test_result__(:no_return) do
    []
  end

  @impl Context
  def __transform_erl_test_result__(return) do
    case return do
      {:ok, result, [], _warnings} ->
        [result] = __transform_erl_run_results__([result])
        {:ok, result}

      {:error, problems} ->
        {:error, problems}
    end
  end

  @impl Context
  def __transform_erl_run_results__(results) do
    [{{:returned, :"$1"}, [], [:"$1"]}, {false, [], [:no_return]}] |> Source.run(results)
  end
end
