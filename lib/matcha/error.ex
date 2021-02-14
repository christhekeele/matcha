defmodule Matcha.Error do
  @moduledoc false

  @type problems :: [problem]
  @type problem :: {:error | :warning, String.t()}

  @callback format_prelude(any()) :: String.t()
  @callback format_source(any()) :: String.t()

  defmacro __using__(source_type: source_type) do
    quote do
      @behaviour unquote(__MODULE__)

      defexception [:source, :problems, details: nil]

      @type t :: %unquote(__CALLER__.module){
              source: unquote(source_type),
              problems: Matcha.Error.problems()
            }

      @spec message(__MODULE__.t()) :: String.t()
      def message(%__MODULE__{} = error) do
        [
          Enum.join([format_prelude(error.source), error.details], ": "),
          "    ",
          String.replace(format_source(error.source), "\n", "\n    ")
          | Enum.map(error.problems, &unquote(__MODULE__).format_problem/1)
        ]
        |> Enum.join("\n ")
      end

      defoverridable(message: 1)
    end
  end

  def format_problem({type, problem}), do: "  #{type}: #{problem}"
end

defmodule Matcha.Rewrite.Error do
  @moduledoc false

  alias Matcha.Error
  alias Matcha.Rewrite

  use Error, source_type: Rewrite.t()

  @impl Error
  @spec format_prelude(Rewrite.t()) :: String.t()
  def format_prelude(%Rewrite{} = _rewrite) do
    "found problems rewriting"
  end

  @impl Error
  @spec format_source(Rewrite.t()) :: String.t()
  def format_source(%Rewrite{} = rewrite) do
    Macro.to_string(rewrite.source)
  end
end

defmodule Matcha.Pattern.Error do
  @moduledoc false

  alias Matcha.Error
  alias Matcha.Pattern

  use Error, source_type: Pattern.t()

  @impl Error
  @spec format_prelude(Pattern.t()) :: String.t()
  def format_prelude(%Pattern{} = _pattern) do
    "found problems with match pattern"
  end

  @impl Error
  @spec format_source(Pattern.t()) :: String.t()
  def format_source(%Pattern{} = pattern) do
    inspect(pattern.source)
  end
end

defmodule Matcha.Spec.Error do
  @moduledoc false

  alias Matcha.Error
  alias Matcha.Spec

  use Error, source_type: Spec.t()

  @impl Error
  @spec format_prelude(Spec.t()) :: String.t()
  def format_prelude(%Spec{} = _spec) do
    "found problems with match spec"
  end

  @impl Error
  @spec format_source(Matcha.Spec.t()) :: String.t()
  def format_source(%Spec{} = spec) do
    inspect(spec.source)
  end
end
