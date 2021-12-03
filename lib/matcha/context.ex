defmodule Matcha.Context do
  @moduledoc """
  Matchspecs are intended to be used for different purposes, and support different instructions
  in their bodies for different use-cases.

  Currently there are three applications of matchspecs supported
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
