defimpl Inspect, for: Matcha.Pattern do
  @moduledoc false

  import Inspect.Algebra

  alias Matcha.Pattern

  def inspect(%Pattern{} = pattern, options) do
    concat([
      "##{inspect(@for)}<",
      break(""),
      to_doc(Pattern.raw(pattern), options),
      ",",
      break(" "),
      string("bindings: #{inspect(pattern.bindings)}"),
      break(""),
      ">"
    ])
  end
end

defimpl Inspect, for: Matcha.Filter do
  @moduledoc false

  import Inspect.Algebra

  alias Matcha.Filter

  def inspect(%Filter{} = pattern, options) do
    concat([
      "##{inspect(@for)}<",
      break(""),
      to_doc(Filter.raw(pattern), options),
      ",",
      break(" "),
      string("bindings: #{inspect(pattern.bindings)}"),
      break(""),
      ">"
    ])
  end
end

defimpl Inspect, for: Matcha.Spec do
  @moduledoc false

  import Inspect.Algebra

  alias Matcha.Spec

  def inspect(%Spec{} = spec, options) do
    concat([
      "##{inspect(@for)}<",
      break(""),
      to_doc(Spec.raw(spec), options),
      ",",
      break(" "),
      string("context: #{inspect(spec.context)}"),
      ",",
      break(" "),
      string("bindings: #{inspect(spec.bindings)}"),
      break(""),
      ">"
    ])
  end
end
