defmodule Matcha.Context do
  @moduledoc """
  About contexts.
  """

  alias Matcha.Source

  @type t :: atom | nil

  @callback __type__() :: Source.type()

  defmacro __using__(opts \\ []) do
    type = Keyword.fetch!(opts, :type)

    quote do
      @behaviour unquote(__MODULE__)

      def __type__, do: unquote(type)
    end
  end
end
