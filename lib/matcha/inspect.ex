defimpl Inspect, for: Matcha.Pattern do
  import Inspect.Algebra

  alias Matcha.Pattern

  def inspect(%Pattern{} = pattern, opts) do
    concat([
      "#Matcha.Pattern<",
      break(""),
      to_doc(pattern.source, opts),
      break(""),
      ">"
    ])
  end
end

defimpl Inspect, for: Matcha.Spec do
  import Inspect.Algebra

  alias Matcha.Spec

  def inspect(%Spec{} = spec, opts) do
    concat([
      "#Matcha.Spec<",
      break(""),
      to_doc(spec.source, opts),
      ",",
      break(" "),
      string("context: :#{inspect(spec.context)}"),
      break(""),
      ">"
    ])
  end
end

defimpl Inspect, for: Matcha.Trace do
  import Inspect.Algebra

  alias Matcha.Trace

  def inspect(%Trace{} = trace, opts) do
    concat([
      "#Matcha.Trace<",
      break(""),
      to_doc(trace.module, opts),
      ".",
      to_doc(trace.function, opts),
      "/",
      to_doc(trace.arguments, opts),
      break(""),
      ">"
    ])
  end
end
