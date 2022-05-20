defmodule Matcha.Context.Table do
  @moduledoc """
  Functions and operators that table match specs can use in their bodies.

  The return values of specs created in this context do not differentiate
  between specs that fail to find a matching clause for the given input,
  and specs with matching clauses that literally return the `false` value;
  they return `{:returned, result}` tuples either way.

  No additional functions besides those defined in `Matcha.Context.Common` can be used in this context.
  """

  alias Matcha.Context

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
    {}
  end

  @impl Context
  def __valid_match_target__(match_target) do
    is_tuple(match_target)
  end

  @impl Context
  def __invalid_match_target_error_message__(match_target) do
    "test targets for table specs must be a tuple, got: `#{inspect(match_target)}`"
  end

  @impl Context
  def __prepare_source__(source) do
    {:ok, source}
  end

  @impl Context
  def __emit_erl_test_result__(result) do
    [result]
  end

  @impl Context
  def __transform_erl_test_result__(return) do
    case return do
      {:ok, result, [], _warnings} -> {:ok, result}
      {:error, problems} -> {:error, problems}
    end
  end

  @impl Context
  def __transform_erl_run_results__(results) do
    results
  end
end
