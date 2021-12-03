defmodule Matcha.Pattern do
  alias Matcha.Pattern

  @moduledoc """
  About patterns.
  """

  alias Matcha.Context
  alias Matcha.Error
  alias Matcha.Rewrite
  alias Matcha.Source

  alias Matcha.Spec

  import Kernel, except: [match?: 2]

  defstruct [:source, :context]

  @type t :: %__MODULE__{
          source: Source.pattern(),
          context: Context.t()
        }

  @spec filter(t(), Enumerable.t()) :: Enumerable.t()
  def filter(%__MODULE__{} = pattern, enumerable) do
    with {:ok, spec} <- to_test_spec(pattern) do
      Spec.filter_map(spec, enumerable)
    end
  end

  @spec match?(t(), term()) :: boolean()
  def match?(%__MODULE__{} = pattern, term) do
    case do_test(pattern) do
      {:ok, {:returned, ^term}} -> true
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

  @spec to_test_spec(t()) :: {:ok, Spec.t()}
  def to_test_spec(%__MODULE__{} = pattern) do
    Rewrite.pattern_to_test_spec(pattern)
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

  @spec do_test(t()) :: {:ok, Source.test_result()} | {:error, Error.problems()}
  defp do_test(%__MODULE__{} = pattern) do
    test_target = pattern.context.__default_test_target__()

    with {:ok, spec} <- to_test_spec(pattern) do
      Source.test(spec.source, spec.context, test_target)
    end
  end
end
