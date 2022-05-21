ExUnit.start(exclude: [:skip])

defmodule TestGuards do
  defmacro custom_gt_3_neq_5_guard(x) do
    quote do
      unquote(x) > 3 and unquote(x) != 5
    end
  end

  defmacro nested_custom_gt_3_neq_5_guard(x) do
    quote do
      custom_gt_3_neq_5_guard(unquote(x)) and custom_gt_3_neq_5_guard(unquote(x) + 1)
    end
  end
end

defmodule TestHelpers do
  def test_module_name(
        %{case: test_case, describe: describe, test: test},
        description \\ nil
      ) do
    module_name = [Test, test_case]

    module_name =
      if describe do
        module_name ++ [describe |> String.replace(~r/[^\w]/, "_")]
      else
        module_name
      end

    module_name = module_name ++ [test |> Atom.to_string() |> String.replace(~r/[^\w]/, "_")]

    module_name =
      if description do
        module_name ++ [description |> String.replace(~r/[^\w]/, "_")]
      else
        module_name
      end

    Module.concat(module_name)
  end

  def module_importable_functions(module) do
    module.__info__(:functions)
    |> Enum.reject(fn {function, _arity} ->
      function |> Atom.to_string() |> String.starts_with?("_")
    end)
  end
end
