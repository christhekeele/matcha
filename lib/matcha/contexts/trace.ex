defmodule :trace do
  def get_tcw() do
    :erlang.system_info(:trace_control_word)
  end

  def set_seq_token, do: :noop

  def get_seq_token, do: :noop

  def message, do: :noop

  def return_trace, do: :noop

  def exception_trace, do: :noop

  def process_dump, do: :noop

  def enable_trace, do: :noop

  def disable_trace, do: :noop

  def trace, do: :noop

  def display, do: :noop

  def caller, do: :noop

  def set_tcw, do: :noop

  def silent, do: :noop
end
