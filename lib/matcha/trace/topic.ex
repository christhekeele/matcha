defprotocol Matcha.Trace.Topic do
  alias Matcha.Trace

  @type t :: Trace.Calls.t()

  def trace(topic, pids)
end
