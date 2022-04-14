defmodule Matcha do
  @readme "README.md"
  @external_resource @readme
  @moduledoc_blurb @readme
                   |> File.read!()
                   |> String.split("<!-- MODULEDOC BLURB -->")
                   |> Enum.fetch!(1)
  @moduledoc_snippet @readme
                     |> File.read!()
                     |> String.split("<!-- MODULEDOC SNIPPET -->")
                     |> Enum.fetch!(1)

  @moduledoc """
  #{@moduledoc_blurb}

  #{@moduledoc_snippet}

  ### Known Limitations

  Currently, it is not possible to:

  - Use the `Kernel.in/2`  macro in guards. *(see: [open issue](https://github.com/christhekeele/matcha/issues/2))*
  - Use the `Kernel.tuple_size/1` or `:erlang.tuple_size/1` guards. *(see: [documentation](https://hexdocs.pm/matcha/Matcha.Context.Common.html#module-limitations))*
    - This is a fundamental limitation of match specs.
  - Use any `is_record` guards (neither Elixir's implementation because of the  `Kernel.tuple_size/1` limitation above, nor erlang's implementation for other reasons). *(see: [documentation](https://hexdocs.pm/matcha/Matcha.Context.Common.html#module-limitations))*
  - Both destructure values from a data structure into bindings, and assign the datastructure to a variable, except at the top-level of a clause.
    - This is how match specs work by design; though there may be a work-around using `:erlang.map_get/2` for maps, but at this time introducing an inconsistency doesn't seem worth it.
  """

  alias Matcha.Context
  alias Matcha.Trace

  @doc """
  Traces `function` calls to `module`, executing a `spec` on matching arguments.

  Tracing is a powerful feature of the BEAM VM, allowing for near zero-cost
  monitoring of what is happening in running systems.
  The functions in `Matcha.Trace` provide utilities for accessing this functionality.

  One of the most powerful forms of tracing uses match specifications:
  rather that just print information on when a certain function signature
  with some number of arguments is invoked, they let you:

  - dissect the arguments in question with pattern-matching and guards
  - take special actions in response (documented in `Matcha.Context.Trace`)

  This macro is a shortcut for constructing a `spec` with the `:trace` context via `Matcha.spec/2`,
  and tracing the specified `module` and `function` with it via `Matcha.Trace.calls/4`.

  For more information on tracing in general, consult the `Matcha.Trace` docs.

  ## Examples

      iex> require Matcha
      ...> Matcha.trace_calls(Enum, :join, limit: 3) do
      ...>   [_enumerable] -> message("using default joiner")
      ...>   [_enumerable, ""] -> message("using default joiner (but explicitly)")
      ...>   [_enumerable, _custom] -> message("using custom joiner")
      ...> end
      ...> Enum.join(1..3)
      # Prints a trace message with "using default joiner" appended
      "123"
      iex> Enum.join(1..3, "")
      # Prints a trace message with "using default joiner (but explicitly)" appended
      "123"
      iex> Enum.join(1..3, ", ")
      # Prints a trace message with "using custom joiner" appended
      "1, 2, 3"

  """
  defmacro trace_calls(module, function, opts \\ [], spec) do
    quote do
      require Matcha.Build

      Trace.calls(
        unquote(module),
        unquote(function),
        Matcha.Build.spec(unquote(Context.Trace.__context_name__()), unquote(spec)),
        unquote(opts)
      )
    end
  end
end
