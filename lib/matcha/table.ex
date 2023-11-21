defmodule Matcha.Table do
  @moduledoc """
  High-level APIs for querying
  [`:ets`](https://www.erlang.org/doc/man/ets),
  [`:dets`](https://www.erlang.org/doc/man/dets),
  and [`:mnesia`](https://www.erlang.org/doc/man/mnesia) tables.

  These three Erlang storage systems can be queried very efficiently with
  match patterns and match specifications. You can use the results of
  `Matcha.Pattern.raw/1` and `Matcha.Spec.raw/1` anywhere these constructs
  are accepted in those modules.

  For convenience, you can also use these `Matcha.Table` modules instead,
  which implement a more Elixir-ish interface to just the matching parts of their APIs,
  automatically unwrap `Matcha` constructs where appropriate, and provide
  high-level macros for constructing and immediately querying them in a fluent way.

  > #### Using `Matcha.Table.Mnesia` {: .info}
  >
  > The `Matcha.Table.Mnesia` modules and functions are only available
  > if your application has specified [`:mnesia`](https://www.erlang.org/doc/man/mnesia) in its list of
  > `:extra_applications` in your `mix.exs` `applications/0` callback.
  """

  @doc """
  Builds a `Matcha.Spec` for table querying purposes.

  Shorthand for `Matcha.spec(:table, spec)`.
  """
  defmacro spec(spec) do
    quote location: :keep do
      require Matcha

      Matcha.spec(:table, unquote(spec))
    end
  end
end
