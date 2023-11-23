defmodule Matcha.Helpers do
  @moduledoc false

  def module_exists?(module) do
    module.__info__(:module)
  rescue
    _ -> false
  else
    ^module -> true
    _ -> false
  end

  @spec function_exists?(any, any) :: boolean
  def function_exists?(module, function) do
    module_exists?(module) and
      Keyword.has_key?(module.__info__(:functions), function)
  end

  def function_with_arity_exists?(module, function, arity) do
    function_exported?(module, function, arity)
  end

  def application_loaded?(name) do
    Enum.find(Application.loaded_applications(), &match?({^name, _, _}, &1))
  end

  def erlang_version do
    :otp_release |> :erlang.system_info() |> List.to_integer()
  end
end
