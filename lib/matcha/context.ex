defmodule Matcha.Context do
  @moduledoc """
  Different types of matchspec are intended to be used for different purposes,
  and support different instructions in their bodies for different use-cases.

  The modules implementing the `Matcha.Context` behaviour define the different types of `Matcha.Spec`,
  provide documentation for what specialized instructions that type supports, and are used during
  Elixir-to-matchspec conversion as a concrete function definition to use when expanding instructions
  (since most of these specialized instructions do not exist anywhere as an actual functions,
  this lets the Elixir compiler complain about invalid instructions as `UndefinedFunctionError`s).

  #### Predefined contexts

  Currently there are three applications of matchspecs supported:

    - `:filter_map`:

        Matchspecs intended to be used to filter/map over a list in an optimized fashion.
        These types of matchspec reference the `Matcha.Context.FilterMap` module.

    - `:table`:

        Matchspecs intended to be used to efficiently select data from BEAMVM "table"
        tools, such as `:ets`, `:dets`, and `:mnesia`, and massage the values returned.
        These types of matchspec reference the `Matcha.Context.Table` module.

    - `:trace`:

        Matchspecs intended to be used to instruct tracing utilities such as
        `:dbg` and `:recon_trace` exactly what function calls with what arguments to trace,
        and allows invoking special trace command instructions in response.
        These types of matchspec reference the `Matcha.Context.Trace` module.

  #### Custom contexts

  The context mechanism is technically extensible: any module can implement the `Matcha.Context`
  behaviour, define the callbacks, and list public no-op functions to allow their usage in
  specs compiled with that context (via `Matcha.spec(CustomContext) do...`).

  In practice there is little point in defining a custom context:
  the supported use-cases for matchspecs are tightly coupled to the erlang language,
  and `Matcha` covers all of them with its provided contexts, which should be sufficient for any application.
  The module+behaviour+callback implementation used in `Matcha` is less about offering extensibility,
  but instead used to simplify special-casing in `Matcha.Spec` function implementations,
  raise Elixir-flavored errors when an invalid instruction is used in the different types of spec,
  and provide a place to document what they do when invoked.

  """

  alias Matcha.Error
  alias Matcha.Source

  @type t :: module()

  @callback __name__() :: atom()

  @callback __erl_test_type__() :: Source.erl_test_type()

  @callback __default_test_target__() :: any()

  @callback __valid_test_target__(test_target :: any()) :: boolean()

  @callback __invalid_test_target_error_message__(test_target :: any) :: String.t()

  @callback __handle_erl_test_results__(return :: any()) ::
              {:ok, result :: any()} | {:error, Error.problems()}
end
