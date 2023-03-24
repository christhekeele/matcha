defmodule Matcha.Error do
  @moduledoc """
  Standard behaviour for `Matcha` errors.
  """

  @type message :: String.t() | charlist
  @type error_problem :: {:error, message}
  @type warning_problem :: {:warning, message}
  @type problem :: error_problem | warning_problem
  @type problems :: [problem]

  @doc """
  Generates the "prelude" text for errors in the struct this error handles
  into a string displayable in an error message.
  """
  @callback format_prelude(struct()) :: String.t()

  @doc """
  Converts the struct this error handles
  into a string displayable in an error message.
  """
  @callback format_source(struct()) :: String.t()

  defmacro __using__(source_type: source_type) do
    quote do
      @behaviour unquote(__MODULE__)

      defexception [:source, :problems, details: nil]

      @type t :: %unquote(__CALLER__.module){
              source: unquote(source_type),
              problems: Matcha.Error.problems()
            }

      @spec message(t()) :: String.t()
      @doc """
      Produces a human-readable message from the given `error`.
      """
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
  @moduledoc """
  Error raised when rewriting Elixir code into a match pattern/spec.
  """

  alias Matcha.Error
  alias Matcha.Rewrite

  use Error, source_type: Rewrite.t()

  @impl Error
  @spec format_prelude(Rewrite.t()) :: String.t()
  def format_prelude(%Rewrite{} = _rewrite) do
    "found problems rewriting code into a match spec"
  end

  @impl Error
  @spec format_source(%Rewrite{}) :: String.t()
  def format_source(%Rewrite{} = rewrite) do
    Macro.to_string(rewrite.source)
  end
end

defmodule Matcha.Pattern.Error do
  @moduledoc """
  Error raised when a `Matcha.Pattern` is invalid.
  """

  alias Matcha.Error
  alias Matcha.Pattern

  use Error, source_type: Pattern.t()

  @impl Error
  @spec format_prelude(Pattern.t()) :: String.t()
  def format_prelude(%Pattern{} = _pattern) do
    "found problems with match pattern"
  end

  @impl Error
  @spec format_source(%Pattern{}) :: String.t()
  def format_source(%Pattern{} = pattern) do
    inspect(pattern.source)
  end
end

defmodule Matcha.Spec.Error do
  @moduledoc """
  Error raised when a `Matcha.Spec` is invalid.
  """

  alias Matcha.Error
  alias Matcha.Spec

  use Error, source_type: Spec.t()

  @impl Error
  @spec format_prelude(Spec.t()) :: String.t()
  def format_prelude(%Spec{} = _spec) do
    "found problems with match spec"
  end

  @impl Error
  @spec format_source(%Spec{}) :: String.t()
  def format_source(%Spec{} = spec) do
    inspect(spec.source)
  end
end

defmodule Matcha.Trace.Error do
  @moduledoc """
  Error raised when trying to trace events happening in a running system.
  """

  alias Matcha.Error
  alias Matcha.Trace

  use Error, source_type: Trace.t()

  @impl Error
  @spec format_prelude(Trace.t()) :: String.t()
  def format_prelude(%Trace{} = _trace) do
    "found problems tracing"
  end

  @impl Error
  @spec format_source(%Trace{}) :: String.t()
  def format_source(%Trace{} = trace) do
    inspect(trace)
  end
end
