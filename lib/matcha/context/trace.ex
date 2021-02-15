defmodule Matcha.Context.Trace do
  @moduledoc """
  About trace contexts.
  """

  @behaviour Matcha.Context

  def __type__, do: :trace

  def return_trace do
    :noop
  end

  def set_seq_token(component, val) do
    :seq_trace.set_token(component, val)
  end
end
