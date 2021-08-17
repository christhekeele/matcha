import Matcha
require Matcha.Trace
alias Matcha.{Pattern, Spec, Trace}

test_spec = Matcha.spec do
  {:ok, value} -> value
  :error       -> "found error"
end
