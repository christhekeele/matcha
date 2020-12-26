defmodule Matcha.Context do
  alias Matcha.Source

  @type t :: atom | nil

  @callback __type__() :: Source.type()
end
