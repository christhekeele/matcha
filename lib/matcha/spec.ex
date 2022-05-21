defmodule Matcha.Spec do
  alias Matcha.Spec

  @moduledoc """
  About specs.
  """

  alias Matcha.Context
  alias Matcha.Error
  alias Matcha.Rewrite
  alias Matcha.Source

  defstruct [:source, :context]

  @type t :: %__MODULE__{
          source: Source.uncompiled(),
          context: Context.t()
        }

  @spec call(t(), Source.match_target()) ::
          {:ok, Source.match_result()} | {:error, Error.problems()}
  def call(%__MODULE__{} = spec, test) do
    Context.test(spec, test)
  end

  @spec call!(t(), Source.match_target()) :: Source.match_result() | no_return
  def call!(%__MODULE__{} = spec, test) do
    case call(spec, test) do
      {:ok, result} ->
        result

      {:error, problems} ->
        raise Spec.Error, source: spec, details: "when calling match spec", problems: problems
    end
  end

  @spec run(t(), Enumerable.t()) :: {:ok, list} | {:error, Matcha.Error.problems()}
  @doc """
  Runs a match `spec` over each item in an `enumerable`.

  ## Examples

      iex> require Matcha
      ...> Matcha.spec(:filter_map) do
      ...>   {amount, tax} when is_integer(amount) and amount > 0 -> {:credit, amount + tax}
      ...> end
      ...> |> Matcha.Spec.run!([
      ...>   {9001, 0},
      ...>   {-200, -2.50},
      ...>   {-3, -0.5},
      ...>   {:error, "bank was offline"},
      ...>   {100, 0},
      ...>   {-743, -16.0},
      ...> ])
      [credit: 9001, credit: 100]

  ## Note

  This function converts the `enumerable` to a list,
  which will trigger full enumeration of things like lazy `Stream`s.
  If used with an infinite stream, it will run forever!
  Consider using `stream/2` if you need lazy filter/mapping.
  It isn't as efficient, but plays nicer with infinite streams,
  and fits into the `Stream` APIs.
  """
  def run(%__MODULE__{} = spec, enumerable) do
    Context.run(spec, enumerable)
  end

  @spec run!(t(), Enumerable.t()) :: list | no_return
  @doc """
  Runs a match `spec` over each item in an `enumerable`.
  """
  def run!(%__MODULE__{} = spec, enumerable) do
    case run(spec, enumerable) do
      {:ok, results} ->
        results

      {:error, problems} ->
        raise Spec.Error, source: spec, details: "when running match spec", problems: problems
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

      # FIXME: context stream logic broken, re-enable after fix
      # iex> require Matcha
      ...> Matcha.spec do
      ...>   {amount, tax} when is_integer(amount) and amount < 0 -> {:charge, amount + tax}
      ...> end
      ...> |> Matcha.Spec.stream([
      ...>   {9001, 0},
      ...>   {-200, -2.50},
      ...>   {-3, -0.5},
      ...>   {:error, "bank was offline"},
      ...>   {100, 0},
      ...>   {-743, -16.0},
      ...> ])
      ...> |> Stream.take(2)
      ...> |> Enum.to_list
      [charge: -202.5, charge: -3.5]


  ## Note

  This function wraps the `enumerable` in a lazy `Stream`.
  If the `enumerable` is something you can safely convert
  to a list without going on forever or loading too much into memory,
  consider using `run/2` instead, as it is more efficient.
  """
  def stream(%__MODULE__{} = spec, enumerable) do
    Context.stream(spec, enumerable)
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
    case Context.test(spec) do
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
end
