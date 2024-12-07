defmodule Matcha.Helpers do
  @moduledoc false

  # def module_exists?(module) do
  #   :code.module_status(module) == :loaded
  # end

  # def module_exists?(module) do
  #   module.__info__(:module)
  # rescue
  #   _ -> false
  # else
  #   ^module -> true
  #   _ -> false
  # end

  # def function_exists?(module, function) do
  #   module_exists?(module) and
  #     Keyword.has_key?(module.__info__(:functions), function)
  # end

  # def function_with_arity_exists?(module, function, arity) do
  #   {module, function, arity} |> dbg()
  #   function_exported?(module, function, arity) |> dbg()
  # end

  def application_loaded?(name) do
    Application.loaded_applications() |> Enum.find(&match?({^name, _, _}, &1))
  end

  def erlang_version do
    Path.join([
      :code.root_dir(),
      "releases",
      :erlang.system_info(:otp_release),
      "OTP_VERSION"
    ])
    |> File.read!()
    |> String.trim()
    |> String.split(".")
    |> Stream.unfold(fn
      [] -> nil
      [head | tail] -> {head, tail}
    end)
    |> Stream.concat(Stream.repeatedly(fn -> 0 end))
    |> Enum.take(3)
    |> Enum.join(".")
    |> Version.parse!()
  end
end
