defmodule Matcha.Helpers do
  @moduledoc false

  def module_exists?(module) do
    module.module_info()
  rescue
    _ -> false
  else
    _ -> true
  end

  def function_exists?(module, function) do
    module_exists?(module) and
      Keyword.has_key?(Keyword.get(module.module_info(), :exports), function)
  end

  def function_with_arity_exists?(module, function, arity) do
    function_exported?(module, function, arity)
  end
end
