defmodule Matcha.Pattern do
  alias Matcha.Pattern
  alias Matcha.Spec
  alias Matcha.Rewrite

  defstruct [:source, :type, :context]

  @opaque t() :: %__MODULE__{
            source: Spec.Source.pattern(),
            type: Matcha.type(),
            context: Matcha.context()
          }

  def test(%__MODULE__{type: :table} = pattern) do
    test(pattern, {})
  end

  def test(%__MODULE__{type: :trace} = pattern) do
    test(pattern, [])
  end

  def test(%__MODULE__{} = pattern, test) do
    do_test(pattern, test)
  end

  def test!(%__MODULE__{type: type} = pattern) do
    test(pattern, Rewrite.default_test_target(type))
  end

  def test!(%__MODULE__{} = pattern, test) do
    case test(pattern, test) do
      {:ok, result} -> {:ok, result}
      {:error, problems} -> raise Pattern.Error, {pattern, problems}
    end
  end

  def do_test(%__MODULE__{} = pattern, test) do
    with {:ok, spec} <- to_test_spec(pattern) do
      case Spec.test(spec, test) do
        {:ok, result} -> {:ok, result}
        {:error, problems} -> raise Pattern.Error, {pattern, problems}
      end
    else
      {:error, reason} ->
        {:error,
         "can only test matches that can be converted to spec, conversion failed: " <> reason}
    end
  end

  def to_test_spec(%__MODULE__{} = pattern) do
    Rewrite.pattern_to_test_spec(pattern)
  end

  def to_test_spec!(%__MODULE__{} = pattern) do
    Rewrite.pattern_to_test_spec!(pattern)
  end

  def valid?(%__MODULE__{} = pattern) do
    case validate(pattern) do
      {:ok, _pattern} -> true
      _ -> false
    end
  end

  def validate(%__MODULE__{} = pattern) do
    do_validate(pattern)
  end

  def validate!(%__MODULE__{} = pattern) do
    case validate(pattern) do
      {:ok, pattern} -> pattern
      {:error, problems} -> raise Pattern.Error, {pattern, problems}
    end
  end

  defp do_validate(%__MODULE__{} = pattern) do
    case test(pattern) do
      {:ok, _result} -> {:ok, pattern}
      {:error, problems} -> {:error, problems}
    end
  end
end
