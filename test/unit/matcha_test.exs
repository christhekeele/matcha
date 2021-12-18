defmodule Matcha.Test do
  @moduledoc false

  use ExUnit.Case, async: true
  doctest Matcha

  import TestHelpers

  describe "spec macro" do
    test "non-block args", test_context do
      assert_raise ArgumentError, ~r/spec\/2 requires a block argument/, fn ->
        defmodule test_module_name(test_context) do
          Matcha.spec(123)
        end
      end

      assert_raise ArgumentError, ~r/spec\/2 requires a block argument/, fn ->
        defmodule test_module_name(test_context) do
          Matcha.spec(:filter_map, 123)
        end
      end
    end

    test "non-shortcut or module context", test_context do
      assert_raise ArgumentError, ~r/123 is not one of/, fn ->
        defmodule test_module_name(test_context) do
          Matcha.spec 123 do
            x -> x
          end
        end
      end
    end

    test "non context module", test_context do
      assert_raise ArgumentError, ~r/Enum is not one of/, fn ->
        defmodule test_module_name(test_context) do
          Matcha.spec Enum do
            x -> x
          end
        end
      end
    end

    test "multi-arity spec", context do
      assert_raise Matcha.Rewrite.Error, ~r"match spec clauses must be of arity 1", fn ->
        defmodule test_module_name(context) do
          Matcha.spec do
            x, y -> {x, y}
          end
        end
      end
    end
  end
end