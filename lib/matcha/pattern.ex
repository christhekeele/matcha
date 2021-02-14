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

  defstruct [:source, :type, :context]

  @type t :: %__MODULE__{
          source: Source.pattern(),
          type: Source.type(),
          context: Context.t()
        }

  @spec test(t()) :: {:ok, Source.test_result()} | {:error, Error.problems()}
  def test(pattern)

  def test(%__MODULE__{type: :table} = pattern) do
    test(pattern, {})
  end

  def test(%__MODULE__{type: :trace} = pattern) do
    test(pattern, [])
  end

  @spec test(t(), Source.test_target()) ::
          {:ok, Source.test_result()} | {:error, Error.problems()}
  def test(%__MODULE__{} = pattern, test) do
    do_test(pattern, test)
  end

  @spec test!(t()) :: Source.test_result() | no_return()
  def test!(%__MODULE__{type: type} = pattern) do
    test!(pattern, Rewrite.default_test_target(type))
  end

  @spec test!(t(), Source.test_target()) :: Source.test_result() | no_return()
  def test!(%__MODULE__{} = pattern, test) do
    case test(pattern, test) do
      {:ok, result} ->
        result

      {:error, problems} ->
        raise Pattern.Error, source: pattern, details: "testing pattern", problems: problems
    end
  end

  @spec do_test(t(), Source.test_target()) ::
          {:ok, Source.test_result()} | {:error, Matcha.Error.problems()}
  defp do_test(%__MODULE__{} = pattern, test) do
    with {:ok, spec} <- to_test_spec(pattern) do
      Spec.test(spec, test)
    end
  end

  @spec to_test_spec(t()) :: {:ok, Spec.t()}
  def to_test_spec(%__MODULE__{} = pattern) do
    Rewrite.pattern_to_test_spec(pattern)
  end

  @spec valid?(t()) :: boolean
  def valid?(%__MODULE__{} = pattern) do
    case validate(pattern) do
      {:ok, _pattern} ->
        true

      _ ->
        false
    end
  end

  @spec validate(t()) :: {:ok, t()} | {:error, Error.problems()}
  def validate(%__MODULE__{} = pattern) do
    do_validate(pattern)
  end

  @spec validate!(t()) :: t() | no_return()
  def validate!(%__MODULE__{} = pattern) do
    case validate(pattern) do
      {:ok, pattern} ->
        pattern

      {:error, problems} ->
        raise Pattern.Error, source: pattern, details: "validating pattern", problems: problems
    end
  end

  @spec do_validate(t()) :: {:ok, t()} | {:error, Error.problems()}
  defp do_validate(%__MODULE__{} = pattern) do
    case test(pattern) do
      {:ok, _result} -> {:ok, pattern}
      {:error, problems} -> {:error, problems}
    end
  end
end
