defimpl Inspect, for: Matcha.Pattern do
  import Inspect.Algebra

  def inspect(%Matcha.Pattern{source: source}, opts) do
    concat(["#Matcha.Pattern<", to_doc(source, opts), ">"])
  end
end

defimpl Inspect, for: Matcha.Spec do
  import Inspect.Algebra

  def inspect(%Matcha.Spec{source: source}, opts) do
    concat(["#Matcha.Spec<", to_doc(source, opts), ">"])
  end
end
