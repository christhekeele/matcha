defmodule Matcha.Spec do
  alias Matcha.Spec
  alias Matcha.Rewrite

  defstruct [:source, :type, :context, :compiled, :node]

  @opaque t() :: %__MODULE__{
            source: Matcha.Spec.Source.spec(),
            type: Matcha.type(),
            context: Matcha.context(),
            compiled: any() | nil,
            node: Node.t() | nil
          }

  def compile(%__MODULE__{} = spec) do
    do_compile(spec)
  end

  @spec compile!(Matcha.Spec.t()) :: Matcha.Spec.t() | no_return()
  def compile!(%__MODULE__{} = spec) do
    case compile(spec) do
      {:ok, spec} -> spec
      {:error, problems} -> raise Spec.Error, {spec, problems}
    end
  end

  def compiled?(%__MODULE__{} = spec) do
    !!spec.compiled and not should_recompile?(spec)
  end

  defp do_compile(%__MODULE__{} = spec) do
    with {:ok, spec} <- validate(spec),
         {:ok, compiled} <- Spec.Source.compile(spec.source, spec.type) do
      {:ok, %{spec | compiled: compiled, node: node()}}
    end
  end

  defp ensure_compiled(%__MODULE__{} = spec) do
    if not compiled?(spec) do
      compile(spec)
    else
      {:ok, spec}
    end
  end

  def recompile(%__MODULE__{} = spec) do
    if should_recompile?(spec) do
      do_compile(spec)
    else
      {:ok, spec}
    end
  end

  def recompile!(%__MODULE__{} = spec) do
    do_compile(spec)
  end

  def should_recompile?(%__MODULE__{} = spec) do
    spec.node != node() or node() == :nonode@nohost
  end

  def run(%__MODULE__{} = spec, enumerable) do
    with {:ok, spec} = ensure_compiled(spec) do
      enumerable
      |> Enum.to_list()
      |> :ets.match_spec_run(spec.compiled)
    end
  end

  def stream(enumerable, %__MODULE__{} = spec) do
    with {:ok, spec} = ensure_compiled(spec) do
      Stream.transform(enumerable, spec, fn element, spec ->
        :ets.match_spec_run([element], spec.compiled)
      end)
    end
  end

  def test(%__MODULE__{type: type} = spec) do
    test(spec, Rewrite.default_test_target(type))
  end

  def test(%__MODULE__{} = spec, test) do
    do_test(spec, test)
  end

  def test!(%__MODULE__{type: type} = spec) do
    test(spec, Rewrite.default_test_target(type))
  end

  def test!(%__MODULE__{} = spec, test) do
    case test(spec, test) do
      {:ok, result} -> {:ok, result}
      {:error, problems} -> raise Spec.Error, {spec, problems}
    end
  end

  def do_test(%__MODULE__{} = spec, test) do
    Spec.Source.test(spec.source, spec.type, test)
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
      {:ok, spec} -> spec
      {:error, problems} -> raise Spec.Error, {spec, problems}
    end
  end

  defp do_validate(%__MODULE__{} = spec) do
    case test(spec) do
      {:ok, _result} -> {:ok, spec}
      {:error, problems} -> {:error, problems}
    end
  end
end
