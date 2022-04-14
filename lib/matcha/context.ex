defmodule Matcha.Context do
  @moduledoc """
  Different types of match spec are intended to be used for different purposes,
  and support different instructions in their bodies for different use-cases.

  The modules implementing the `Matcha.Context` behaviour define the different types of `Matcha.Spec`,
  provide documentation for what specialized instructions that type supports, and are used during
  Elixir-to-match spec conversion as a concrete function definition to use when expanding instructions
  (since most of these specialized instructions do not exist anywhere as an actual functions,
  this lets the Elixir compiler complain about invalid instructions as `UndefinedFunctionError`s).

  ### Predefined contexts

  Currently there are three applications of match specs supported:

    - `:match`:

        Matchspecs intended to be used to filter/map over an in-memory list in an optimized fashion.
        These types of match spec reference the `Matcha.Context.Match` module.

    - `:table`:

        Matchspecs intended to be used to efficiently select data from BEAM VM "table"
        tools, such as `:ets`, `:dets`, and `:mnesia`, and massage the values returned.
        These types of match spec reference the `Matcha.Context.Table` module.

    - `:trace`:

        Matchspecs intended to be used to instruct tracing utilities such as
        `:dbg` and `:recon_trace` exactly what function calls with what arguments to trace,
        and allows invoking special trace command instructions in response.
        These types of match spec reference the `Matcha.Context.Trace` module.

  ### Custom contexts

  The context mechanism is technically extensible: any module can implement the `Matcha.Context`
  behaviour, define the callbacks, and list public no-op functions to allow their usage in
  specs compiled with that context (via `Matcha.spec(CustomContext) do...`).

  In practice there is little point in defining a custom context:
  the supported use-cases for match specs are tightly coupled to the erlang language,
  and `Matcha` covers all of them with its provided contexts, which should be sufficient for any application.
  The module+behaviour+callback implementation used in `Matcha` is less about offering extensibility,
  but instead used to simplify special-casing in `Matcha.Spec` function implementations,
  raise Elixir-flavored errors when an invalid instruction is used in the different types of spec,
  and provide a place to document what they do when invoked.

  """

  alias Matcha.Error
  alias Matcha.Source

  alias Matcha.Spec

  @type t :: module()

  @callback __context_name__() :: atom()

  @callback __erl_test_type__() :: Source.erl_test_type()

  @callback __default_test_target__() :: any

  @callback __valid_test_target__(test_target :: any) :: boolean()

  @callback __prepare_source__(source :: any) :: any

  @callback __emit_test_result__(result :: any) :: any

  @callback __invalid_test_target_error_message__(test_target :: any) :: String.t()

  @callback __handle_erl_test_results__(result :: any) ::
              {:ok, result :: any} | {:error, Error.problems()}

  @callback __handle_erl_run_results__(results :: [any]) ::
              {:ok, results :: [any]} | {:error, Error.problems()}

  @spec run(Matcha.Spec.t(), Enumerable.t()) ::
          {:ok, Source.test_result()} | {:error, Matcha.Error.problems()}
  def run(%Spec{context: context} = spec, enumerable) do
    source = context.__prepare_source__(spec.source)
    test_target = context.__default_test_target__()

    case do_test(source, context, test_target) do
      {:ok, _result} ->
        context.__handle_erl_run_results__(Source.run(source, Enum.to_list(enumerable)))

      {:error, problems} ->
        {:error, problems}
    end
  end

  @type test_result ::
          {:matched, any}
          | :no_match
          | {:returned, any}
          | {:traced, boolean | String.t(), Source.trace_flags()}
          | any
  @spec test(Spec.t()) ::
          {:ok, Source.test_result()} | {:error, Matcha.Error.problems()}
  def test(%Spec{context: context} = spec) do
    source = context.__prepare_source__(spec.source)
    test_target = context.__default_test_target__()

    do_test(source, context, test_target)
  end

  @spec test(Spec.t(), Source.test_target()) ::
          {:ok, Source.test_result()} | {:error, Matcha.Error.problems()}
  def test(%Spec{context: context} = spec, test_target) do
    source = context.__prepare_source__(spec.source)

    if context.__valid_test_target__(test_target) do
      do_test(source, context, test_target)
    else
      {:error,
       [
         error: context.__invalid_test_target_error_message__(test_target)
       ]}
    end
  end

  defp do_test(source, context, test_target) do
    source
    |> Source.test(context.__erl_test_type__(), test_target)
    |> context.__handle_erl_test_results__()
  end
end
