defmodule Matcha.Context.Table do
  @moduledoc """
  Functions and operators that `:table` match specs can use in their bodies.

  No additional functions besides those defined in `Matcha.Context.Common` can be used in `:table` contexts.
  """

  alias Matcha.Context

  @behaviour Context

  ####
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
  def __handle_erl_test_results__(return) do
    case return do
      {:ok, result, [], _warnings} -> {:ok, {:returned, result}}
      {:error, problems} -> {:error, problems}
    end
  end
end
