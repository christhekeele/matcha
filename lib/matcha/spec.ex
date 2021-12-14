defmodule Matcha.Spec do
  alias Matcha.Spec

  @moduledoc """
  About specs.
  """

  alias Matcha.Context
  alias Matcha.Error
  alias Matcha.Rewrite
  alias Matcha.Source

  defstruct [:source, :context, :compiled, :node]

  @type t :: %__MODULE__{
          source: Source.spec(),
          context: Context.t(),
          compiled: Source.compiled() | nil,
          node: Node.t() | nil
        }

  @spec filter_map(t(), Enumerable.t()) :: Enumerable.t()
  def filter_map(%__MODULE__{} = spec, enumerable) do
    with {:ok, spec} <- ensure_compiled(spec) do
      list = Enum.to_list(enumerable)
      Source.run(spec.compiled, list)
    end
  end

  @spec stream(t(), Enumerable.t()) :: Enumerable.t()
  def stream(%__MODULE__{} = spec, enumerable) do
    with {:ok, spec} <- ensure_compiled(spec) do
      Stream.transform(enumerable, spec, fn element, spec ->
        Source.run(spec, [element])
      end)
    end
  end

  @spec run(t(), Source.test_target()) ::
          {:ok, Source.test_result()} | {:error, Error.problems()}
  def run(%__MODULE__{} = spec, test) do
    Source.test(spec.source, spec.context, test)
  end

  @spec run!(t(), Source.test_target()) :: Source.test_result() | no_return

  def run!(%__MODULE__{} = spec, test) do
    case run(spec, test) do
      {:ok, result} ->
        result

      {:error, problems} ->
        raise Spec.Error, source: spec, details: "when testing match spec", problems: problems
    end
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
    test_target = spec.context.__default_test_target__()

    case Source.test(spec.source, spec.context, test_target) do
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

  ###
  # COMPILATION HELPERS
  ##

  @spec compile(t()) :: {:ok, t()} | {:error, Error.problems()}
  defp compile(%__MODULE__{} = spec) do
    with {:ok, spec} <- validate(spec),
         {:ok, compiled} <- Source.compile(spec.source, spec.context) do
      {:ok, %{spec | compiled: compiled, node: node()}}
    end
  end

  @spec compiled?(t()) :: boolean
  defp compiled?(%__MODULE__{} = spec) do
    !!spec.compiled and not should_recompile?(spec)
  end

  @spec ensure_compiled(t()) :: {:ok, t()} | {:error, Error.problems()}
  defp ensure_compiled(%__MODULE__{} = spec) do
    if compiled?(spec) do
      {:ok, spec}
    else
      compile(spec)
    end
  end

  @spec should_recompile?(t()) :: boolean
  defp should_recompile?(%__MODULE__{} = spec) do
    !spec.compiled or spec.node != node() or node() == :nonode@nohost
  end
end
