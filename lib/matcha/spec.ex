defmodule Matcha.Spec do
  alias Matcha.Spec

  @moduledoc """
  About specs.
  """

  alias Matcha.Context
  alias Matcha.Error
  alias Matcha.Rewrite
  alias Matcha.Source

  defstruct [:source, :type, :context, :compiled, :node]

  @type t :: %__MODULE__{
          source: Source.spec(),
          type: Source.type(),
          context: Context.t(),
          compiled: Source.compiled() | nil,
          node: Node.t() | nil
        }

  @spec compile(__MODULE__.t()) :: {:error, Error.problems()} | {:ok, Spec.t()}
  def compile(%__MODULE__{} = spec) do
    do_compile(spec)
  end

  @spec compile!(__MODULE__.t()) :: __MODULE__.t() | no_return()
  def compile!(%__MODULE__{} = spec) do
    case compile(spec) do
      {:ok, spec} ->
        spec

      {:error, problems} ->
        raise Spec.Error, source: spec, details: "compiling spec", problems: problems
    end
  end

  @spec compiled?(__MODULE__.t()) :: boolean
  def compiled?(%__MODULE__{} = spec) do
    !!spec.compiled and not should_recompile?(spec)
  end

  defp do_compile(%__MODULE__{} = spec) do
    with {:ok, spec} <- validate(spec),
         {:ok, compiled} <- Source.compile(spec.source, spec.type) do
      {:ok, %{spec | compiled: compiled, node: node()}}
    end
  end

  defp ensure_compiled(%__MODULE__{} = spec) do
    if compiled?(spec) do
      {:ok, spec}
    else
      compile(spec)
    end
  end

  @spec recompile(__MODULE__.t()) :: {:error, Error.problems()} | {:ok, Spec.t()}
  def recompile(%__MODULE__{} = spec) do
    if should_recompile?(spec) do
      do_compile(spec)
    else
      {:ok, spec}
    end
  end

  @spec recompile!(__MODULE__.t()) :: __MODULE__.t() | no_return()
  def recompile!(%__MODULE__{} = spec) do
    case recompile(spec) do
      {:ok, spec} ->
        spec

      {:error, problems} ->
        raise Spec.Error, source: spec, details: "recompiling spec", problems: problems
    end
  end

  @spec should_recompile?(__MODULE__.t()) :: boolean
  def should_recompile?(%__MODULE__{} = spec) do
    spec.node != node() or node() == :nonode@nohost
  end

  @spec run(__MODULE__.t(), Enumerable.t()) :: Enumerable.t()
  def run(%__MODULE__{} = spec, enumerable) do
    with {:ok, spec} <- ensure_compiled(spec) do
      list = Enum.to_list(enumerable)
      Source.run(spec.compiled, list)
    end
  end

  @spec stream(__MODULE__.t(), Enumerable.t()) :: Enumerable.t()
  def stream(%__MODULE__{} = spec, enumerable) do
    with {:ok, spec} <- ensure_compiled(spec) do
      Stream.transform(enumerable, spec, fn element, spec ->
        Source.run(spec, [element])
      end)
    end
  end

  @spec test(__MODULE__.t()) ::
          {:error, Error.problems()} | {:ok, Source.test_result()}
  def test(%__MODULE__{type: type} = spec) do
    test(spec, Rewrite.default_test_target(type))
  end

  @spec test(__MODULE__.t(), Source.test_target()) ::
          {:error, Error.problems()} | {:ok, Source.test_result()}
  def test(%__MODULE__{} = spec, test) do
    do_test(spec, test)
  end

  @spec test!(__MODULE__.t()) :: Source.test_result() | no_return
  def test!(%__MODULE__{type: type} = spec) do
    test!(spec, Rewrite.default_test_target(type))
  end

  @spec test!(__MODULE__.t(), Source.test_target()) :: Source.test_result() | no_return
  def test!(%__MODULE__{} = spec, test) do
    case test(spec, test) do
      {:ok, result} ->
        result

      {:error, problems} ->
        raise Spec.Error, source: spec, details: "testing spec", problems: problems
    end
  end

  @spec do_test(__MODULE__.t(), Source.test_target()) ::
          {:error, Error.problems()} | {:ok, Source.test_result()}
  defp do_test(%__MODULE__{} = spec, test) do
    Source.test(spec.source, spec.type, test)
  end

  def to_pattern(%__MODULE__{} = spec) do
    Rewrite.spec_to_pattern(spec)
  end

  def valid?(%__MODULE__{} = spec) do
    case validate(spec) do
      {:ok, _spec} -> true
      _ -> false
    end
  end

  def validate(%__MODULE__{} = spec) do
    do_validate(spec)
  end

  def validate!(%__MODULE__{} = spec) do
    case validate(spec) do
      {:ok, spec} ->
        spec

      {:error, problems} ->
        raise Spec.Error, source: spec, details: "validating spec", problems: problems
    end
  end

  defp do_validate(%__MODULE__{} = spec) do
    case test(spec) do
      {:ok, _result} -> {:ok, spec}
      {:error, problems} -> {:error, problems}
    end
  end
end
