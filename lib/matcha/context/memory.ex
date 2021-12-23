defmodule Matcha.Context.Memory do
  @moduledoc """
  Functions and operators that `:memory` match specs can use in their bodies.

  Specs created in the `:memory` context are unique in that they can differentiate
  between specs that fail to find a matching clause for the given input,
  and specs with matching clauses that literally return the `false` value.
  They return `:no_match` in the former case, and `{:matched, value}` tuples in the latter,
  where `value` can be a literal `false` returned from a clause.

  No additional functions besides those defined in `Matcha.Context.Common` can be used in `:memory` contexts.
  """

  alias Matcha.Context

  @behaviour Context

  ###
  # CALLBACKS
  ##

  @impl Context
  def __context_name__ do
    :memory
  end

  @impl Context
  def __erl_test_type__ do
    :table
  end

  @impl Context
  def __default_test_target__ do
    nil
  end

  @impl Context
  def __valid_test_target__(_test_target) do
    true
  end

  @impl Context
  def __invalid_test_target_error_message__(_test_target) do
    ""
  end

  @impl Context
  def __prepare_source__(source) do
    for {match, guards, body} <- source do
      {last_expr, body} = List.pop_at(body, -1)
      body = [body | [{{:matched, last_expr}}]]
      {match, guards, body}
    end
  end

  @impl Context
  def __emit_test_result__({:matched, value}) do
    [value]
  end

  def __emit_test_result__(:no_match) do
    []
  end

  @impl Context
  def __handle_erl_test_results__(return) do
    case return do
      {:ok, {:matched, result}, [], _warnings} -> {:ok, {:matched, result}}
      {:ok, false, [], _warnings} -> {:ok, :no_match}
      {:error, problems} -> {:error, problems}
    end
  end
end
