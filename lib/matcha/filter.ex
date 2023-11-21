defmodule Matcha.Filter do
  @moduledoc """
  About filters.
  """

  alias __MODULE__

  alias Matcha.Context
  alias Matcha.Error
  alias Matcha.Rewrite
  alias Matcha.Source

  alias Matcha.Spec

  import Kernel, except: [match?: 2]

  defstruct [:source, :bindings]

  @test_spec_context Matcha.Context.Match
  @default_to_spec_context @test_spec_context

  @type t :: %__MODULE__{
          source: Source.filter(),
          bindings: %{atom() => term()}
        }

  @spec raw(t()) :: Source.filter()
  def raw(%__MODULE__{source: source} = _filter) do
    source
  end

  @spec bindings(t()) :: %{atom() => non_neg_integer()}
  def bindings(%__MODULE__{bindings: bindings} = _filter) do
    bindings
  end

  @spec matches(t(), Enumerable.t()) :: Enumerable.t()
  def matches(%__MODULE__{} = filter, enumerable) do
    with {:ok, spec} <- to_spec(@test_spec_context, filter) do
      Spec.run(spec, enumerable)
    end
  end

  @spec match?(t(), term()) :: boolean()
  def match?(%__MODULE__{} = filter, term) do
    case do_test(filter, term) do
      {:ok, {:matched, ^term}} -> true
      _ -> false
    end
  end

  @spec match!(t(), term()) :: term() | no_return()
  def match!(%__MODULE__{} = filter, term) do
    if match?(filter, term) do
      term
    else
      raise MatchError, term: term
    end
  end

  @spec matched_variables(t(), term()) :: %{atom() => term()} | nil
  def matched_variables(%__MODULE__{} = filter, term) do
    with {:ok, spec} <- Rewrite.filter_to_matched_variables_spec(@test_spec_context, filter) do
      case Context.test(spec, term) do
        {:ok, {:matched, results}} ->
          Map.new(
            for {binding, index} <- filter.bindings, index > 0 do
              {binding, Enum.at(results, index - 1)}
            end
          )

        {:ok, :no_match} ->
          nil
      end
    end
  end

  @spec to_spec(context :: Context.t(), t()) :: {:ok, Spec.t()} | {:error, Error.problems()}
  def to_spec(context \\ @default_to_spec_context, %__MODULE__{} = filter) do
    context
    |> Context.resolve()
    |> Rewrite.filter_to_spec(filter)
  end

  @spec validate(t()) :: {:ok, t()} | {:error, Error.problems()}
  def validate(%__MODULE__{} = filter) do
    case do_test(filter) do
      {:ok, _result} -> {:ok, filter}
      {:error, problems} -> {:error, problems}
    end
  end

  @spec validate!(t()) :: t() | no_return()
  def validate!(%__MODULE__{} = filter) do
    case validate(filter) do
      {:ok, filter} ->
        filter

      {:error, problems} ->
        raise Filter.Error,
          source: filter,
          details: "when validating filter",
          problems: problems
    end
  end

  defp do_test(%__MODULE__{} = filter) do
    with {:ok, spec} <- to_spec(@test_spec_context, filter) do
      Context.test(spec)
    end
  end

  defp do_test(%__MODULE__{} = filter, match_target) do
    with {:ok, spec} <- to_spec(@test_spec_context, filter) do
      Context.test(spec, match_target)
    end
  end
end
