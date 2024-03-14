defmodule Matcha.Spec do
  @moduledoc """
  About specs.
  """

  alias __MODULE__

  alias Matcha.Context
  alias Matcha.Error
  alias Matcha.Raw

  defstruct [:raw, :context, :bindings]

  @type t :: %__MODULE__{
          raw: Raw.uncompiled(),
          context: Context.t(),
          bindings: %{non_neg_integer() => %{atom() => term()}}
        }

  @spec raw(t()) :: Raw.uncompiled()
  def raw(%__MODULE__{raw: raw} = _spec) do
    raw
  end

  @spec call(t(), Raw.match_target()) ::
          {:ok, Raw.match_result()} | {:error, Error.problems()}
  def call(%__MODULE__{} = spec, test) do
    Context.test(spec, test)
  end

  @spec call!(t(), Raw.match_target()) :: Raw.match_result() | no_return
  def call!(%__MODULE__{} = spec, test) do
    case call(spec, test) do
      {:ok, result} ->
        result

      {:error, problems} ->
        raise Spec.Error, source: spec, details: "when calling match spec", problems: problems
    end
  end

  @doc """
  Wraps an existing `raw` match specification into a `#{inspect(__MODULE__)}` struct for usage in Matcha APIs.

  Assumes the spec is written to be used in `Matcha.Context.Table` context, and validates it as such.
  To modify this validation behaviour, see `from_raw/2`.

  Returns `{:ok, %{#{inspect(__MODULE__)}}}` if validation succeeds, or `{:error, problems}` if not.
  """
  @spec from_raw(Raw.spec()) :: {:ok, t} | {:error, Error.problems()}
  def from_raw(raw) do
    from_raw(:table, raw)
  end

  @doc """
  Wraps an existing `raw` match specification into a `#{inspect(__MODULE__)}` struct for usage in Matcha APIs.

  Accepts a `context` module or specifier against which to validate.

  Returns `{:ok, %{#{inspect(__MODULE__)}}}`  if validation succeeds, or `{:error, problems}` if not.
  """
  @spec from_raw(Context.t() | Raw.type(), Raw.spec()) ::
          {:ok, t} | {:error, Error.problems()}
  def from_raw(context, raw, bindings \\ %{}) do
    %__MODULE__{
      raw: raw,
      context: Context.resolve(context),
      bindings: bindings
    }
    |> validate
  end

  @doc """
  Wraps an existing `raw` match specification into a `Matcha.Spec` struct for usage in Matcha APIs.

  Assumes the spec is written to be used in `Matcha.Context.Table` context, and validates it as such.
  To modify this validation behaviour, see `from_raw!/2`.

  Returns a `#{inspect(__MODULE__)}` struct if validation succeeds, otherwise raises a `#{inspect(__MODULE__)}.Error`.
  """
  @spec from_raw!(Raw.spec()) :: t | no_return
  def from_raw!(source) do
    from_raw!(:table, source)
  end

  @doc """
  Wraps an existing `raw` match specification into a `#{inspect(__MODULE__)}` struct for usage in Matcha APIs.

  Accepts a `context` module or specifier against which to validate.

  Returns a `#{inspect(__MODULE__)}` struct if validation succeeds, otherwise raises a `#{inspect(__MODULE__)}.Error`.
  """
  @spec from_raw!(Context.t() | Raw.type(), Raw.spec()) ::
          t | no_return
  def from_raw!(context, raw, bindings \\ %{}) do
    %__MODULE__{
      raw: raw,
      context: Context.resolve(context),
      bindings: bindings
    }
    |> validate!
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
