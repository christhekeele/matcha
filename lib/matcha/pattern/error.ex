defmodule Matcha.Pattern.Error do
  alias Matcha.Pattern

  defexception [:pattern, :problems]

  @type t :: %{
          __exception__: true,
          pattern: Pattern.t(),
          problems: Matcha.problems()
        }

  @spec exception({Pattern.t(), Matcha.problems()}) :: t()
  def exception({%Pattern{} = pattern, problems}) do
    %__MODULE__{pattern: pattern, problems: problems, __exception__: true}
  end

  def message(%__MODULE__{} = error) do
    ["found errors in match pattern" | Enum.map(error.problems, &format_problem/1)]
    |> Enum.join("\n ")
  end

  defp format_problem(problem) when is_binary(problem), do: problem
  defp format_problem({:error, problem}) when is_list(problem), do: List.to_string(problem)
end
