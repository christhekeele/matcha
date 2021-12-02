defimpl Inspect, for: Matcha.Pattern do
  import Inspect.Algebra

  alias Matcha.Pattern

  def inspect(%Pattern{} = pattern, opts) do
    concat([
      "#Matcha.Pattern<",
      to_doc(pattern.source, opts),
      ">"
    ])
  end
end

defimpl Inspect, for: Matcha.Spec do
  import Inspect.Algebra

  alias Matcha.Spec

  def inspect(%Spec{} = spec, opts) do
    context =
      if spec.context do
        to_string(spec.context.__type__())
      else
        "none"
      end

    concat([
      "#Matcha.Spec<",
      break(""),
      to_doc(spec.source, opts),
      ",",
      break(" "),
      string("context: #{context}"),
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
      to_doc(trace.module, opts),
      ".",
      to_doc(trace.function, opts),
      "/",
      to_doc(trace.arguments, opts),
      ">"
    ])
  end
end
