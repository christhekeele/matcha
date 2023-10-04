defmodule Matcha.Pattern do
  @moduledoc """
  About patterns.
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
          source: Source.pattern(),
          bindings: %{atom() => non_neg_integer()}
        }

  @compile {:inline, source: 1}
  @spec source(t()) :: Source.pattern()
  def source(%__MODULE__{source: source} = _pattern) do
    source
  end

  @compile {:inline, bindings: 1}
  @spec bindings(t()) :: %{atom() => non_neg_integer()}
  def bindings(%__MODULE__{bindings: bindings} = _pattern) do
    bindings
  end

  @spec matches(t(), Enumerable.t()) :: Enumerable.t()
  def matches(%__MODULE__{} = pattern, enumerable) do
    with {:ok, spec} <- to_spec(@test_spec_context, pattern) do
      Spec.run(spec, enumerable)
    end
  end

  @spec match?(t(), term()) :: boolean()
  def match?(%__MODULE__{} = pattern, term) do
    case do_test(pattern, term) do
      {:ok, {:matched, ^term}} -> true
      _ -> false
    end
  end

  @spec match!(t(), term()) :: term() | no_return()
  def match!(%__MODULE__{} = pattern, term) do
    if match?(pattern, term) do
      term
    else
      raise MatchError, term: term
    end
  end

  @spec matched_variables(t(), term()) :: %{atom() => term()} | nil
  def matched_variables(%__MODULE__{} = pattern, term) do
    with {:ok, spec} <- Rewrite.pattern_to_matched_variables_spec(@test_spec_context, pattern) do
      case Context.test(spec, term) do
        {:ok, {:matched, results}} ->
          Map.new(
            for {binding, index} <- pattern.bindings, index > 0 do
              {binding, Enum.at(results, index - 1)}
            end
          )

        {:ok, :no_match} ->
          nil
      end
    end
  end

  @spec to_spec(context :: Context.t(), t()) :: {:ok, Spec.t()} | {:error, Error.problems()}
  def to_spec(context \\ @default_to_spec_context, %__MODULE__{} = pattern) do
    context
    |> Context.resolve()
    |> Rewrite.pattern_to_spec(pattern)
  end

  @spec validate(t()) :: {:ok, t()} | {:error, Error.problems()}
  def validate(%__MODULE__{} = pattern) do
    case do_test(pattern) do
      {:ok, _result} -> {:ok, pattern}
      {:error, problems} -> {:error, problems}
    end
  end

  @spec validate!(t()) :: t() | no_return()
  def validate!(%__MODULE__{} = pattern) do
    case validate(pattern) do
      {:ok, pattern} ->
        pattern

      {:error, problems} ->
        raise Pattern.Error,
          source: pattern,
          details: "when validating pattern",
          problems: problems
    end
  end

  defp do_test(%__MODULE__{} = pattern) do
    with {:ok, spec} <- to_spec(@test_spec_context, pattern) do
      Context.test(spec)
    end
  end

  defp do_test(%__MODULE__{} = pattern, match_target) do
    with {:ok, spec} <- to_spec(@test_spec_context, pattern) do
      Context.test(spec, match_target)
    end
  end
end
