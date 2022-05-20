defmodule Matcha.Rewrite.Kernel do
  @moduledoc false

  import Kernel, except: [is_boolean: 1]

  defguard is_boolean(value)
           when is_atom(value) and (value == true or value == false)
end
