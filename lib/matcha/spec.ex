defmodule Matcha.Spec do
  @moduledoc """
  About specs.
  """

  alias __MODULE__

  alias Matcha.Context
  alias Matcha.Error
  alias Matcha.Source

  defstruct [:source, :context]

  @type t :: %__MODULE__{
          source: Source.uncompiled(),
          context: Context.t()
        }

  @compile {:inline, source: 1}
  @spec source(t()) :: Source.uncompiled()
  def source(%__MODULE__{source: source} = _spec) do
    source
  end

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

  @doc """
  Wraps an existing match specification `source` code into a `#{inspect(__MODULE__)}` struct for usage in Matcha APIs.

  Assumes the spec is written to be used in `Matcha.Context.Table` context, and validates it as such.
  To modify this validation behaviour, see `from_source/2`.

  Returns `{:ok, %{#{inspect(__MODULE__)}}}` if validation succeeds, or `{:error, problems}` if not.
  """
  @spec from_source(Source.spec()) :: {:ok, t} | {:error, Error.problems()}
  def from_source(source) do
    from_source(:table, source)
  end

  @doc """
  Wraps an existing match specification `source` code into a `#{inspect(__MODULE__)}` struct for usage in Matcha APIs.

  Accepts a `context` module or specifier against which to validate.

  Returns `{:ok, %{#{inspect(__MODULE__)}}}`  if validation succeeds, or `{:error, problems}` if not.
  """
  @spec from_source(Context.t() | Source.type(), Source.spec()) ::
          {:ok, t} | {:error, Error.problems()}
  def from_source(context, source) do
    %__MODULE__{
      source: source,
      context: Context.resolve(context)
    }
    |> validate
  end

  @doc """
  Wraps an existing match specification `source` code into a `Matcha.Spec` struct for usage in Matcha APIs.

  Assumes the spec is written to be used in `Matcha.Context.Table` context, and validates it as such.
  To modify this validation behaviour, see `from_source!/2`.

  Returns a `#{inspect(__MODULE__)}` struct if validation succeeds, otherwise raises a `#{inspect(__MODULE__)}.Error`.
  """
  @spec from_source!(Source.spec()) :: t | no_return
  def from_source!(source) do
    from_source!(:table, source)
  end

  @doc """
  Wraps an existing match specification `source` code into a `#{inspect(__MODULE__)}` struct for usage in Matcha APIs.

  Accepts a `context` module or specifier against which to validate.

  Returns a `#{inspect(__MODULE__)}` struct if validation succeeds, otherwise raises a `#{inspect(__MODULE__)}.Error`.
  """
  @spec from_source!(Context.t() | Source.type(), Source.spec()) ::
          t | no_return
  def from_source!(context, source) do
    %__MODULE__{
      source: source,
      context: Context.resolve(context)
    }
    |> validate!
  end

  @spec merge(list(t)) :: {:ok, t} | {:error, Error.problems()}
  @doc """
  Merges a list of `#{inspect(__MODULE__)}` `specs` into a single matchspec.

  All specs provided must be built for the same `Matcha.Context`.

  The clauses of each matchspec are combined _**in the order provided**_ into a new matchspec.
  Note that while the new spec is validated via the `validate/1` function at runtime,
  no compile-time checks are applied (for example, that none of the merged clauses overlap).

  This means that if an earlier spec provided has a match-all clause; no later clauses can match.
  This is rarely a problem in practice, as matchspecs tend to not be written with catch-all clauses,
  since part of their utility is to filter out unwanted matches that are not specified in the spec.

  Returns `{:ok, %{#{inspect(__MODULE__)}}}` if the new matchspec is valid, or `{:error, problems}` if not.

  ## Examples

      iex> require Matcha
      ...>
      ...> spec1 = Matcha.spec do
      ...>   integer when is_integer(integer)
      ...>     -> integer + 1
      ...> end
      ...>
      ...> spec2 = Matcha.spec do
      ...>   float when is_float(float)
      ...>     -> float + 0.5
      ...> end
      ...>
      ...> {:ok, merged_spec} = Matcha.Spec.merge([spec1, spec2])
      ...> Matcha.Spec.run!(merged_spec, [1, 1.5])
      [2, 2.0]

  """
  def merge(specs) do
    contexts =
      specs
      |> Enum.map(& &1.context)
      |> Enum.uniq()

    if length(contexts) != 1 do
      {:error,
       error: "all specs must be built for the same context, got contexts: `#{inspect(contexts)}`"}
    else
      specs
      |> do_merge(List.first(contexts))
      |> validate()
    end
  end

  @spec merge(t, t) :: {:ok, t} | {:error, Error.problems()}
  @doc """
  Merges `spec1` and `spec2` into a single matchspec.

  All specs provided must be built for the same `Matcha.Context`.

  See `merge/1` for more details on how a merged matchspec behaves.

  Returns `{:ok, %{#{inspect(__MODULE__)}}}` if the new matchspec is valid, or `{:error, problems}` if not.
  """
  def merge(spec1, spec2) do
    merge([spec1, spec2])
  end

  @spec merge!(list(t)) :: t | no_return()
  @doc """
  Merges a list of `#{inspect(__MODULE__)}` `specs` into a single matchspec.

  All specs provided must be built for the same `Matcha.Context`.

  See `merge/1` for more details on how a merged matchspec behaves.

  Returns the new `#{inspect(__MODULE__)}}}` if it is valid, or raises a `#{inspect(__MODULE__)}` exception if not.
  """
  def merge!(specs) do
    case merge(specs) do
      {:ok, spec} ->
        spec

      {:error, problems} ->
        raise Spec.Error,
          source: do_merge(specs, List.first(specs).context),
          details: "when merging match specs",
          problems: problems
    end
  end

  @spec merge!(t, t) :: t | no_return()
  @doc """
  Merges `spec1` and `spec2` into a single matchspec.

  All specs provided must be built for the same `Matcha.Context`.

  See `merge/1` for more details on how a merged matchspec behaves.

  Returns the new `#{inspect(__MODULE__)}}}` if it is valid, or raises a `#{inspect(__MODULE__)}` exception if not.
  """
  def merge!(spec1, spec2) do
    merge!([spec1, spec2])
  end

  defp do_merge(specs, context) do
    %__MODULE__{
      source: Enum.flat_map(specs, &Spec.source/1),
      context: Context.resolve(context)
    }
  end

  @spec run(t(), Enumerable.t()) :: {:ok, list} | {:error, Error.problems()}
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
