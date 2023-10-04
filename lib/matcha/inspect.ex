defimpl Inspect, for: Matcha.Pattern do
  @moduledoc false

  import Inspect.Algebra

  alias Matcha.Pattern

  @spec inspect(Matcha.Pattern.t(), Inspect.Opts.t()) ::
          :doc_line
          | :doc_nil
          | binary
          | {:doc_collapse, pos_integer}
          | {:doc_force, any}
          | {:doc_break | :doc_color | :doc_cons | :doc_fits | :doc_group | :doc_string, any, any}
          | {:doc_nest, any, :cursor | :reset | non_neg_integer, :always | :break}
  def inspect(%Pattern{} = pattern, opts) do
    concat([
      "#Matcha.Pattern<",
      break(""),
      to_doc(Pattern.source(pattern), opts),
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

  @spec inspect(Matcha.Filter.t(), Inspect.Opts.t()) ::
          :doc_line
          | :doc_nil
          | binary
          | {:doc_collapse, pos_integer}
          | {:doc_force, any}
          | {:doc_break | :doc_color | :doc_cons | :doc_fits | :doc_group | :doc_string, any, any}
          | {:doc_nest, any, :cursor | :reset | non_neg_integer, :always | :break}
  def inspect(%Filter{} = pattern, opts) do
    concat([
      "#Matcha.Filter<",
      break(""),
      to_doc(Filter.source(pattern), opts),
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

  def inspect(%Spec{} = spec, opts) do
    concat([
      "#Matcha.Spec<",
      break(""),
      to_doc(Spec.source(spec), opts),
      ",",
      break(" "),
      string("context: #{inspect(spec.context)}"),
      break(""),
      ">"
    ])
  end
end

defimpl Inspect, for: Matcha.Trace do
  @moduledoc false

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
