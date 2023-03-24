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

  defstruct [:source]

  @test_spec_context Matcha.Context.Match
  @default_to_spec_context @test_spec_context

  @type t :: %__MODULE__{
          source: Source.pattern()
        }

  @spec filter(t(), Enumerable.t()) :: Enumerable.t()
  def filter(%__MODULE__{} = pattern, enumerable) do
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
