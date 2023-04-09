defprotocol Matcha.Trace.Target do
  def trace_flag(target)

  def trace_patterns(target)

  def validate(target)

  def validate!(target)
end
