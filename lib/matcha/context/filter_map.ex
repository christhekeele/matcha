defmodule Matcha.Context.FilterMap do
  @moduledoc """
  About filter contexts.
  """

  alias Matcha.Context

  @behaviour Context

  ####
  # CALLBACKS
  ##

  @impl Context
  def __name__ do
    :filter_map
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
  def __handle_erl_test_results__(return) do
    case return do
      {:ok, result, [], _warnings} -> {:ok, {:returned, result}}
      {:error, problems} -> {:error, problems}
    end
  end
end
