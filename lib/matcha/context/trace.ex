defmodule Matcha.Context.Trace do
  @moduledoc """
  About trace contexts.
  """

  alias Matcha.Context

  @behaviour Context

  ####
  # CALLBACKS
  ##

  @impl Context
  def __name__ do
    :trace
  end

  @impl Context
  def __erl_test_type__ do
    :trace
  end

  @impl Context
  def __default_test_target__ do
    []
  end

  @impl Context
  def __valid_test_target__(test_target) do
    is_list(test_target)
  end

  @impl Context
  def __invalid_test_target_error_message__(test_target) do
    "test targets for trace specs must be a list, got: `#{inspect(test_target)}`"
  end

  @impl Context
  def __handle_erl_test_results__(return) do
    case return do
      {:ok, result, flags, _warnings} ->
        result =
          if is_list(result) do
            List.to_string(result)
          else
            result
          end

        {:ok, {:traced, result, flags}}

      {:error, problems} ->
        {errors, _warnings} = Keyword.split(problems, [:warnings])
        {:error, Matcha.Rewrite.problems(errors)}
    end
  end

  ####
  # SUPPORTED FUNCTIONS
  ##

  def return_trace do
    :noop
  end

  def message(_) do
    :noop
  end

  def caller do
    :noop
  end

  def set_seq_token(component, val) do
    :seq_trace.set_token(component, val)
  end
end
