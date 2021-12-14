ExUnit.start(exclude: [:skip])

defmodule TestGuards do
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

defmodule TestHelpers do
  def test_module_name(
        %{case: test_case, describe: describe, test: test},
        description \\ nil
      ) do
    [Test, test_case, describe, test, description]
    |> Enum.reject(&is_nil/1)
    |> Module.concat()
  end
end
