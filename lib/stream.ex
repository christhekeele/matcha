defmodule Matcha.Stream do
  # alias Matcha.Spec

  # require Stream.Reducers, as: R

  # defmacrop skip(acc) do
  #   {:cont, acc}
  # end

  # defmacrop next(fun, entry, acc) do
  #   quote(do: unquote(fun).(unquote(entry), unquote(acc)))
  # end

  # defmacrop acc(head, state, tail) do
  #   quote(do: [unquote(head), unquote(state) | unquote(tail)])
  # end

  # defmacrop next_with_acc(fun, entry, head, state, tail) do
  #   quote do
  #     {reason, [head | tail]} = unquote(fun).(unquote(entry), [unquote(head) | unquote(tail)])
  #     {reason, [head, unquote(state) | tail]}
  #   end
  # end

  # @doc """
  # Creates a stream that filters elements according to
  # the given match spec on enumeration.
  # ## Examples
  #     iex> import Matcha
  #     iex> stream = Stream.filter([1, 2, 3], spec do {x, y} = z when rem(x, y) == 0 -> z end)
  #     iex> Enum.to_list(stream)
  #     [2]
  # """
  # def filter(enum, fun) when is_function(fun, 1) do
  #   lazy(enum, fn f1 -> R.filter(fun, f1) end)
  # end

  # ## Stolen Helpers

  # @compile {:inline, lazy: 2, lazy: 3, lazy: 4}

  # defp lazy(%Stream{done: nil, funs: funs} = lazy, fun), do: %{lazy | funs: [fun | funs]}
  # defp lazy(enum, fun), do: %Stream{enum: enum, funs: [fun]}

  # defp lazy(%Stream{done: nil, funs: funs, accs: accs} = lazy, acc, fun),
  #   do: %{lazy | funs: [fun | funs], accs: [acc | accs]}

  # defp lazy(enum, acc, fun), do: %Stream{enum: enum, funs: [fun], accs: [acc]}

  # defp lazy(%Stream{done: nil, funs: funs, accs: accs} = lazy, acc, fun, done),
  #   do: %{lazy | funs: [fun | funs], accs: [acc | accs], done: done}

  # defp lazy(enum, acc, fun, done), do: %Stream{enum: enum, funs: [fun], accs: [acc], done: done}
end
