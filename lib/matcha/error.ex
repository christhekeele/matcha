defmodule Matcha.Error do
  @moduledoc """
  Standard behaviour for `Matcha` errors.
  """

  alias __MODULE__

  @type message :: binary | charlist
  @type error_problem :: {:error, message}
  @type warning_problem :: {:warning, message}
  @type problem :: error_problem | warning_problem
  @type problems :: [problem]

  @doc """
  Generates the "prelude" text for errors in the struct this error handles
  into a string displayable in an error message.
  """
  @callback format_prelude(struct()) :: binary

  @doc """
  Converts the struct this error handles
  into a string displayable in an error message.
  """
  @callback format_source(struct()) :: binary

  defmacro __using__(source_type: source_type) do
    quote do
      @behaviour unquote(__MODULE__)

      defexception [:source, :problems, details: nil]

      @type t :: %unquote(__CALLER__.module){
              source: unquote(source_type),
              problems: Matcha.Error.problems()
            }

      @spec message(t()) :: binary
      @doc """
      Produces a human-readable message from the given `error`.
      """
      def message(%__MODULE__{} = error) do
        Enum.join(
          [
            Enum.join([format_prelude(error.source), error.details], ": "),
            "    ",
            String.replace(format_source(error.source), "\n", "\n    ")
            | Enum.map(error.problems, &unquote(__MODULE__).format_problem/1)
          ],
          "\n "
        )
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

  use Error, source_type: Rewrite.t()

  alias Matcha.Error
  alias Matcha.Rewrite

  @impl Error
  @spec format_prelude(Rewrite.t()) :: binary
  def format_prelude(%Rewrite{} = _rewrite) do
    "found problems rewriting code into a match spec"
  end

  @impl Error
  @spec format_source(Rewrite.t()) :: binary
  def format_source(%Rewrite{} = rewrite) do
    Macro.to_string(Rewrite.code(rewrite))
  end
end

defmodule Matcha.Pattern.Error do
  @moduledoc """
  Error raised when a `Matcha.Pattern` is invalid.
  """

  use Error, source_type: Pattern.t()

  alias Matcha.Error
  alias Matcha.Pattern

  @impl Error
  @spec format_prelude(Pattern.t()) :: binary
  def format_prelude(%Pattern{} = _pattern) do
    "found problems with match pattern"
  end

  @impl Error
  @spec format_source(Pattern.t()) :: binary
  def format_source(%Pattern{} = pattern) do
    inspect(Pattern.raw(pattern))
  end
end

defmodule Matcha.Filter.Error do
  @moduledoc """
  Error raised when a `Matcha.Filter` is invalid.
  """

  use Error, source_type: Filter.t()

  alias Matcha.Error
  alias Matcha.Filter

  @impl Error
  @spec format_prelude(Filter.t()) :: binary
  def format_prelude(%Filter{} = _pattern) do
    "found problems with match filter"
  end

  @impl Error
  @spec format_source(Filter.t()) :: binary
  def format_source(%Filter{} = pattern) do
    inspect(Filter.raw(pattern))
  end
end

defmodule Matcha.Spec.Error do
  @moduledoc """
  Error raised when a `Matcha.Spec` is invalid.
  """

  use Error, source_type: Spec.t()

  alias Matcha.Error
  alias Matcha.Spec

  @impl Error
  @spec format_prelude(Spec.t()) :: binary
  def format_prelude(%Spec{} = _spec) do
    "found problems with match spec"
  end

  @impl Error
  @spec format_source(Spec.t()) :: binary
  def format_source(%Spec{} = spec) do
    inspect(Spec.raw(spec))
  end
end

defmodule Matcha.Trace.Error do
  @moduledoc """
  Error raised when trying to trace events happening in a running system.
  """

  use Error, source_type: Trace.t()

  alias Matcha.Error
  alias Matcha.Trace

  @impl Error
  @spec format_prelude(Trace.t()) :: binary
  def format_prelude(%Trace{} = _trace) do
    "found problems tracing"
  end

  @impl Error
  @spec format_source(Trace.t()) :: binary
  def format_source(%Trace{} = trace) do
    inspect(trace)
  end
end
