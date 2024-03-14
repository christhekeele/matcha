defmodule Matcha.Context do
  @moduledoc """
  Defines the functions allowed in and the behaviour of `Matcha.Spec`s for different use-cases.

  Different types of match spec are intended to be used for different purposes,
  and support different instructions in their bodies when passed to different APIs.

  The modules implementing the `Matcha.Context` behaviour define the different types of `Matcha.Spec`,
  provide documentation for what specialized instructions that type supports, and are used during
  Elixir-to-match spec conversion as a concrete function definition to use when expanding instructions
  (since most of these specialized instructions do not exist anywhere as an actual functions,
  this lets the Elixir compiler complain about invalid instructions as `UndefinedFunctionError`s).

  ### Predefined contexts

  Currently the supported applications of match specs are:

    - `:filter_map`:

        Matchspecs intended to be used to filter/map over an in-memory list in an optimized fashion.
        These types of match spec reference the `Matcha.Context.FilterMap` module,
        and can be used in the `Matcha.Spec` APIs.

    - `:match`:

        Matchspecs intended to be used to match over an in-memory list in an optimized fashion.
        These types of match spec reference the `Matcha.Context.Match` module,
        and can be used in the `Matcha.Spec` APIs.

    - `:table`:

        Matchspecs intended to be used to efficiently select data from BEAM VM "table"
        tools, such as [`:ets`](https://www.erlang.org/doc/man/ets),
        [`:dets`](https://www.erlang.org/doc/man/dets),
        and [`:mnesia`](https://www.erlang.org/doc/man/mnesia), and massage the values returned.
        These types of match spec reference the `Matcha.Context.Table` module,
        and can be used in the `Matcha.Table` APIs.

    - `:trace`:

        Matchspecs intended to be used to instruct tracing utilities such as
        [`:erlang.trace_pattern/3`](https://www.erlang.org/doc/man/erlang#trace_pattern-3),
        [`:dbg`](https://www.erlang.org/doc/man/dbg),
        and [`:recon_trace`](https://ferd.github.io/recon/recon_trace)
        exactly what function calls with what arguments to trace,
        and allows invoking special trace command instructions in response.
        These types of match spec reference the `Matcha.Context.Trace` module,
        and can be used in the `Matcha.Trace` APIs.

  ### Custom contexts

  The context mechanism is technically extensible: any module can implement the `Matcha.Context`
  behaviour, define the callbacks, and list public no-op functions to allow their usage in
  specs compiled with that context (via `Matcha.spec(CustomContext) do...`).

  In practice there is little point in defining a custom context:
  the supported use-cases for match specs are tightly coupled to the Erlang language,
  and `Matcha` covers all of them with its provided contexts, which should be sufficient for any application.
  The module+behaviour+callback implementation used in `Matcha` is less about offering extensibility,
  but instead used to simplify special-casing in `Matcha.Spec` function implementations,
  raise Elixir-flavored errors when an invalid instruction is used in the different types of spec,
  and provide a place to document what they do when invoked.

  """

  defmacro __using__(_opts \\ []) do
    quote do
      @behaviour unquote(__MODULE__)
    end
  end

  alias Matcha.Error
  alias Matcha.Raw

  alias Matcha.Spec

  @type t :: module()

  @core_context_aliases [
    filter_map: Matcha.Context.FilterMap,
    match: Matcha.Context.Match,
    table: Matcha.Context.Table,
    trace: Matcha.Context.Trace
  ]

  @spec __core_context_aliases__() :: Keyword.t()
  @doc """
  Maps the shortcut references to the core Matcha context modules.

  This describes which shortcuts users may write, for example in `Matcha.spec(:some_shortcut)` instead of
  the fully qualified module `Matcha.spec(Matcha.Context.SomeContext)`.
  """
  def __core_context_aliases__(), do: @core_context_aliases

  @doc """
  Which primitive Erlang context this context module wraps.
  """
  @callback __erl_spec_type__() :: Raw.type()

  @doc """
  A default value to use when executing match specs in this context.

  This function is used to provide `Matcha.Raw.test/3` with a target value to test against,
  in situations where it is being used to simply validate the match spec itself,
  but we do not acutally care if the input matches the spec.

  This value, when passed to this context's `c:Matcha.Context.__valid_match_target__/1` callback,
  must produce a `true` value.
  """
  @callback __default_match_target__() :: any

  @doc """
  A validator that runs before executing a match spec against a `target` in this context.

  This validator is run before any match specs are executed on inputs to `Matcha.Raw.test/3`,
  and all elements of the enumerable input to `Matcha.Raw.run/2`.

  If this function returns false, the match spec will not be executed, instead
  returning a `t:Matcha.Error.error_problem` with a `t:Matcha.Error.message`
  generated by the `c:Matcha.Context.__invalid_match_target_error_message__/1` callback.
  """
  @callback __valid_match_target__(match_target :: any) :: boolean()

  @doc """
  Describes an issue with a test target.

  Invoked to generate a `t:Matcha.Error.message` when `c:Matcha.Context.__valid_match_target__/1` fails.
  """
  @callback __invalid_match_target_error_message__(match_target :: any) :: binary

  @doc """
  Allows this context module to modify match specs before their execution.

  This hook is the main entrypoint for creating custom contexts,
  allowing them to augment the match spec with new behaviour when executed in this context.

  Care must be taken to handle the results of the modified match spec after execution correctly,
  before they are returned to the caller. This should be implemented in the callbacks:

  - `c:__transform_erl_run_results__/1`
  - `c:__transform_erl_test_result__/1`
  - `c:__emit_erl_test_result__/1`
  """
  @callback __prepare_source__(source :: Raw.uncompiled()) ::
              {:ok, new_source :: Raw.uncompiled()} | {:error, Error.problems()}
  @doc """
  Transforms the result of a spec match just after calling `:erlang.match_spec_test/3`.

  You can think of this as an opportunity to "undo" any modifications to the user's
  provided matchspec made in `c:__prepare_source__/1`.

  Must return `{:ok, result}` to indicate that the returned value is valid; otherwise
  return `{:error, problems}` to raise an exception.
  """
  @callback __transform_erl_test_result__(result :: any) ::
              {:ok, result :: any} | {:error, Error.problems()}

  @doc """
  Transforms the result of a spec match just after calling `:ets.match_spec_run/2`.

  You can think of this as an opportunity to "undo" any modifications to the user's
  provided matchspec made in `c:__prepare_source__/1`.

  Must return `{:ok, result}` to indicate that the returned value is valid; otherwise
  return `{:error, problems}` to raise an exception.
  """
  @callback __transform_erl_run_results__(results :: [any]) ::
              {:ok, results :: [any]} | {:error, Error.problems()}

  @doc """
  Decides if the result of a spec match should be part of the result set.

  This callback runs just after calls to `c:__transform_erl_test_result__/1` or `c:__transform_erl_test_result__/1`.

  Must return `{:emit, result}` to include the transformed result of a spec match, when executing it
  against in-memory data (as opposed to tracing or :ets) for validation or debugging purposes.
  Otherwise, returning `:no_emit` will hide the result.
  """
  @callback __emit_erl_test_result__(result :: any) :: {:emit, new_result :: any} | :no_emit

  @doc """
  Determines whether or not specs in this context can be compiled.
  """
  @spec supports_compilation?(t) :: boolean
  def supports_compilation?(context) do
    context.__erl_spec_type__() == :table
  end

  @doc """
  Determines whether or not specs in this context can used in tracing.
  """
  @spec supports_tracing?(t) :: boolean
  def supports_tracing?(context) do
    context.__erl_spec_type__() == :trace
  end

  @doc """
  Resolves shortcut references to the core Matcha context modules.

  This allows users to write, for example, `Matcha.spec(:trace)` instead of
  the fully qualified module `Matcha.spec(Matcha.Context.Trace)`.
  """
  @spec resolve(atom() | t) :: t | no_return

  for {alias, context} <- @core_context_aliases do
    def resolve(unquote(alias)), do: unquote(context)
  end

  def resolve(context) when is_atom(context) do
    context.__erl_spec_type__()
  rescue
    UndefinedFunctionError ->
      reraise ArgumentError,
              [
                message:
                  "`#{inspect(context)}` is not one of: " <>
                    (Keyword.keys(@core_context_aliases)
                     |> Enum.map_join(", ", &"`#{inspect(&1)}`")) <>
                    " or a module that implements `Matcha.Context`"
              ],
              __STACKTRACE__
  else
    _ -> context
  end

  def resolve(context) do
    raise ArgumentError,
      message:
        "`#{inspect(context)}` is not one of: " <>
          (Keyword.keys(@core_context_aliases)
           |> Enum.map_join(", ", &"`#{inspect(&1)}`")) <>
          " or a module that implements `Matcha.Context`"
  end

  @spec run(Matcha.Spec.t(), Enumerable.t()) ::
          {:ok, list(any)} | {:error, Error.problems()}
  @doc """
  Runs a `spec` against an `enumerable`.

  This is a key function that ensures the input `spec` and results
  are passed through the callbacks of a `#{inspect(__MODULE__)}`.

  Returns either `{:ok, results}` or `{:error, problems}` (that other `!` APIs may use to raise an exception).
  """
  def run(%Spec{context: context} = spec, enumerable) do
    case context.__prepare_source__(Spec.raw(spec)) do
      {:ok, source} ->
        match_targets = Enum.to_list(enumerable)
        # TODO: validate targets pre-run
        # spec.context.__valid_match_target__(match_target)

        results =
          if supports_compilation?(context) do
            source
            |> Raw.compile()
            |> Raw.run(match_targets)
          else
            do_run_without_compilation(match_targets, spec, source)
          end

        spec.context.__transform_erl_run_results__(results)

      {:error, problems} ->
        {:error, problems}
    end
  end

  defp do_run_without_compilation(match_targets, spec, source) do
    match_targets
    |> Enum.reduce([], fn match_target, results ->
      case do_test(source, spec.context, match_target) do
        {:ok, result} ->
          case spec.context.__emit_erl_test_result__(result) do
            {:emit, result} ->
              [result | results]

            :no_emit ->
              {[], spec}
          end

        {:error, problems} ->
          raise Spec.Error,
            source: spec,
            details: "when running match spec",
            problems: problems
      end
    end)
    |> :lists.reverse()
  end

  @doc """
  Creates a lazy `Stream` that yields the results of running the `spec` against the provided `enumberable`.

  This is a key function that ensures the input `spec` and results
  are passed through the callbacks of a `#{inspect(__MODULE__)}`.

  Returns either `{:ok, stream}` or `{:error, problems}` (that other `!` APIs may use to raise an exception).
  """
  @spec stream(Matcha.Spec.t(), Enumerable.t()) ::
          {:ok, Enumerable.t()} | {:error, Error.problems()}
  def stream(%Spec{context: context} = spec, enumerable) do
    case context.__prepare_source__(Spec.raw(spec)) do
      {:ok, source} ->
        Stream.transform(enumerable, {spec, source}, fn match_target, {spec, source} ->
          # TODO: validate targets midstream
          # spec.context.__valid_match_target__(match_target)
          do_stream_test(match_target, spec, source)
        end)

      {:error, problems} ->
        {:error, problems}
    end
  end

  defp do_stream_test(match_target, spec, source) do
    case do_test(source, spec.context, match_target) do
      {:ok, result} ->
        case spec.context.__emit_erl_test_result__(result) do
          {:emit, result} ->
            case spec.context.__transform_erl_run_results__([result]) do
              {:ok, results} ->
                {:ok, results}

              {:error, problems} ->
                raise Spec.Error,
                  source: spec,
                  details: "when streaming match spec",
                  problems: problems
            end

          :no_emit ->
            {[], spec}
        end

      {:error, problems} ->
        raise Spec.Error,
          source: spec,
          details: "when streaming match spec",
          problems: problems
    end
  end

  @spec test(Spec.t()) ::
          {:ok, any} | {:error, Error.problems()}
  @doc """
  Tests that the provided `spec` in  its `Matcha.Context` is valid.

  Invokes `c:__default_match_target__/0` and passes it into `:erlang.match_spec_test/3`.

  Returns either `{:ok, stream}` or `{:error, problems}` (that other `!` APIs may use to raise an exception).
  """
  def test(%Spec{context: context} = spec) do
    test(spec, context.__default_match_target__())
  end

  @spec test(Spec.t(), Raw.match_target()) ::
          {:ok, any} | {:error, Error.problems()}
  @doc """
  Tests that the provided `spec` in its `Matcha.Context` correctly matches a provided `match_target`.

  Passes the provided `match_target` into `:erlang.match_spec_test/3`.

  Returns either `{:ok, stream}` or `{:error, problems}` (that other `!` APIs may use to raise an exception).
  """
  def test(%Spec{context: context} = spec, match_target) do
    case context.__prepare_source__(Spec.raw(spec)) do
      {:ok, source} ->
        if context.__valid_match_target__(match_target) do
          do_test(source, context, match_target)
        else
          {:error,
           [
             error: context.__invalid_match_target_error_message__(match_target)
           ]}
        end

      {:error, problems} ->
        {:error, problems}
    end
  end

  defp do_test(source, context, match_target) do
    source
    |> Raw.test(context.__erl_spec_type__(), match_target)
    |> context.__transform_erl_test_result__()
  end
end
