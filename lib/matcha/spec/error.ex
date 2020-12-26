defmodule Matcha.Spec.Error do
  alias Matcha.Spec

  defexception [:spec, :problems]

  @type t :: %{
          __exception__: true,
          spec: Spec.t(),
          problems: Matcha.problems()
        }

  @spec exception({Spec.t(), Matcha.problems()}) :: t()
  def exception({%Spec{} = spec, problems}) do
    %__MODULE__{spec: spec, problems: problems, __exception__: true}
  end

  def message(%__MODULE__{} = error) do
    ["found errors in match spec" | Enum.map(error.problems, &format_problem/1)]
    |> Enum.join("\n ")
  end

  defp format_problem(problem) when is_binary(problem), do: problem
  defp format_problem({:error, problem}) when is_list(problem), do: List.to_string(problem)
end
