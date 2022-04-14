defmodule Matcha.Context.Table do
  @moduledoc """
  Functions and operators that `:table` match specs can use in their bodies.

  The return values of specs created in the `:table` context do not differentiate
  between specs that fail to find a matching clause for the given input,
  and specs with matching clauses that literally return the `false` value;
  they return `{:returned, result}` tuples either way.

  No additional functions besides those defined in `Matcha.Context.Common` can be used in `:table` contexts.
  """

  alias Matcha.Context

  @behaviour Context

  ###
  # CALLBACKS
  ##

  @impl Context
  def __context_name__ do
    :table
  end

  @impl Context
  def __erl_test_type__ do
    :table
  end

  @impl Context
  def __default_test_target__ do
    {}
  end

  @impl Context
  def __valid_test_target__(test_target) do
    is_tuple(test_target)
  end

  @impl Context
  def __invalid_test_target_error_message__(test_target) do
    "test targets for table specs must be a tuple, got: `#{inspect(test_target)}`"
  end

  @impl Context
  def __prepare_source__(source) do
    source
  end

  @impl Context
  def __emit_test_result__(result) do
    [result]
  end

  @impl Context
  def __handle_erl_test_results__(return) do
    case return do
      {:ok, result, [], _warnings} -> {:ok, result}
      {:error, problems} -> {:error, problems}
    end
  end

  @impl Context
  def __handle_erl_run_results__(results) do
    results
  end
end
