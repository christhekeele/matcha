ExUnit.start(exclude: [:skip])

defmodule TestHelpers do
  defmacro custom_guard(x) do
    quote do
      unquote(x) > 3 and unquote(x) != 5
    end
  end

  defmacro nested_custom_guard(x) do
    quote do
      custom_guard(unquote(x)) and custom_guard(unquote(x) + 1)
    end
  end
end
