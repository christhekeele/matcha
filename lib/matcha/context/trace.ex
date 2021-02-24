defmodule Matcha.Context.Trace do
  @moduledoc """
  About trace contexts.
  """

  use Matcha.Context, type: :trace

  def return_trace do
    :noop
  end

  def set_seq_token(component, val) do
    :seq_trace.set_token(component, val)
  end
end
