defmodule Matcha.Spec do
  alias Matcha.Spec

  @moduledoc """
  About specs.
  """

  alias Matcha.Context
  alias Matcha.Error
  alias Matcha.Rewrite
  alias Matcha.Source

  defstruct [:source, :context, :compiled, :node]

  @type t :: %__MODULE__{
          source: Source.spec(),
          context: Context.t(),
          compiled: Source.compiled() | nil,
          node: Node.t() | nil
        }

  @spec filter_map(t(), Enumerable.t()) :: list
  @doc """
  Uses a `spec` to filter out and manipulate elements of an `enumerable`.

  Elements of the `enumerable` that match one of the `spec`'s clauses
  will transformed as instructed. Elements that do not match
  will be filtered out of the result.

  Always returns a list.

  ## Examples

      iex> require Matcha
      ...> spec = Matcha.spec do
      ...>   {type, amount, tax} when type == :charge -> {type, amount + tax}
      ...> end
      ...> Matcha.Spec.filter_map(spec, [
      ...>   {:credit, 9001, 0},
      ...>   {:charge, -200, -2.50},
      ...>   {:credit, 100, 0},
      ...>   {:charge, -743, -16.0},
      ...> ])
      [charge: -202.5, charge: -759.0]

  ## Note

  This function converts the `enumerable` to a list,
  which will trigger full enumeration of things like lazy `Stream`s.
  If used with an infinite stream, it will run forever!
  Consider using `stream/2` if you need lazy filter/mapping.
  It isn't as efficient, but plays nicer with infinite streams,
  and fits into the `Stream` APIs.
  """
  def filter_map(%__MODULE__{} = spec, enumerable) do
    with {:ok, spec} <- ensure_compiled(spec) do
      list = Enum.to_list(enumerable)
      Source.run(spec.compiled, list)
    end
  end

  @spec stream(t(), Enumerable.t()) :: Enumerable.t()
  @doc """
  Produces a `Stream` that filters out and manipulates elements of an `enumerable`.

  Elements of the `enumerable` that match one of the `spec`'s clauses
  will transformed as instructed.
  Elements that do not match will be filtered out of the result.

  Always returns a lazy `Stream` enumerable.

  ## Examples

      iex> require Matcha
      ...> spec = Matcha.spec do
      ...>   {type, amount, tax} when type == :charge -> {type, amount + tax}
      ...>   {type, _amount, _tax} when type == :skip -> false
      ...> end
      ...> Matcha.Spec.stream(spec, [
      ...>   {:credit, 9001, 0},
      ...>   {:charge, -200, -2.50},
      ...>   {:credit, 100, 0},
      ...>   {:charge, -743, -16.0},
      ...> ])
      ...> |> Stream.take(1)
      ...> |> Enum.to_list
      [charge: -202.5]

    require Matcha
    spec = Matcha.spec do
      {type, amount, tax} when type == :charge -> {type, amount + tax}
    end
    Matcha.Spec.stream(spec, [
      {:credit, 9001, 0},
      {:charge, -200, -2.50},
      {:credit, 100, 0},
      {:charge, -200, -2.50}
    ]) |>  Enum.to_list

  ## Note

  This function wraps the `enumerable` in a lazy `Stream`.
  If the `enumerable` is something you can safely convert
  to a list without going on forever or loading too much into memory,
  consider using `filter_map/2` instead, as it is much more efficient.
  """
  def stream(%__MODULE__{} = spec, enumerable) do
    Stream.transform(enumerable, spec, fn element, spec ->
      case run(spec, element) do
        {:ok, result} ->
          {spec.context.__emit_test_result__(result), spec}

        {:error, problems} ->
          raise Spec.Error,
            source: spec,
            details: "when streaming match spec",
            problems: problems
      end
    end)
  end

  @spec run(t(), Source.test_target()) ::
          {:ok, Source.test_result()} | {:error, Error.problems()}
  def run(%__MODULE__{} = spec, test) do
    Source.test(spec, test)
  end

  @spec run!(t(), Source.test_target()) :: Source.test_result() | no_return

  def run!(%__MODULE__{} = spec, test) do
    case run(spec, test) do
      {:ok, result} ->
        result

      {:error, problems} ->
        raise Spec.Error, source: spec, details: "when testing match spec", problems: problems
    end
  end

  def to_pattern(%__MODULE__{} = spec) do
    Rewrite.spec_to_pattern(spec)
  end

  @spec valid?(t()) :: boolean()
  def valid?(%__MODULE__{} = spec) do
    case validate(spec) do
      {:ok, _spec} -> true
      {:error, _problems} -> false
    end
  end

  @spec validate(t()) :: {:ok, t()} | {:error, Error.problems()}
  def validate(%__MODULE__{} = spec) do
    test_target = spec.context.__default_test_target__()

    case Source.test(spec, test_target) do
      {:ok, _result} -> {:ok, spec}
      {:error, problems} -> {:error, problems}
    end
  end

  @spec validate!(t()) :: t() | no_return()
  def validate!(%__MODULE__{} = spec) do
    case validate(spec) do
      {:ok, spec} ->
        spec

      {:error, problems} ->
        raise Spec.Error, source: spec, details: "when validating match spec", problems: problems
    end
  end

  ###
  # COMPILATION HELPERS
  ##

  @spec compile(t()) :: {:ok, t()} | {:error, Error.problems()}
  defp compile(%__MODULE__{} = spec) do
    with {:ok, spec} <- validate(spec),
         {:ok, compiled} <- Source.compile(spec.source, spec.context) do
      {:ok, %{spec | compiled: compiled, node: node()}}
    end
  end

  @spec compiled?(t()) :: boolean
  defp compiled?(%__MODULE__{} = spec) do
    !!spec.compiled and not should_recompile?(spec)
  end

  @spec ensure_compiled(t()) :: {:ok, t()} | {:error, Error.problems()}
  defp ensure_compiled(%__MODULE__{} = spec) do
    if compiled?(spec) do
      {:ok, spec}
    else
      compile(spec)
    end
  end

  @spec should_recompile?(t()) :: boolean
  defp should_recompile?(%__MODULE__{} = spec) do
    !spec.compiled or spec.node != node() or node() == :nonode@nohost
  end
end
