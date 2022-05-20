defmodule Matcha.Test do
  @moduledoc false

  use ExUnit.Case, async: true

  doctest Matcha

  import TestHelpers

  import Matcha

  alias Matcha.Spec

  describe "spec macro" do
    test "non-block args", test_context do
      assert_raise ArgumentError, ~r/spec\/2 requires a block argument/, fn ->
        defmodule test_module_name(test_context) do
          import Matcha
          spec(123)
        end
      end

      assert_raise ArgumentError, ~r/spec\/2 requires a block argument/, fn ->
        defmodule test_module_name(test_context) do
          import Matcha
          spec(:table, 123)
        end
      end
    end

    test "non-clause args", test_context do
      assert_raise ArgumentError, ~r/spec\/2 must be provided with `->` clauses/, fn ->
        defmodule test_module_name(test_context) do
          import Matcha

          spec do
            :ok
          end
        end
      end

      assert_raise ArgumentError, ~r/spec\/2 must be provided with `->` clauses/, fn ->
        defmodule test_module_name(test_context) do
          import Matcha

          spec do
            :ok
            :ok
          end
        end
      end
    end

    test "non-shortcut or module context", test_context do
      assert_raise ArgumentError,
                   ~r/`123` is not.*?a module that implements `Matcha.Context`/,
                   fn ->
                     defmodule test_module_name(test_context) do
                       import Matcha

                       spec 123 do
                         x -> x
                       end
                     end
                   end
    end

    test "non context module", test_context do
      assert_raise ArgumentError,
                   ~r/`Enum` is not.*?a module that implements `Matcha.Context`/,
                   fn ->
                     defmodule test_module_name(test_context) do
                       import Matcha

                       spec Enum do
                         x -> x
                       end
                     end
                   end
    end

    test "multi-arity spec", context do
      assert_raise Matcha.Rewrite.Error, ~r"match spec clauses must be of arity 1", fn ->
        defmodule test_module_name(context) do
          import Matcha

          spec do
            x, y -> {x, y}
          end
        end
      end
    end
  end

  describe "stlib guards" do
    test "-/1" do
      spec =
        spec do
          x when x == -1 -> x
        end

      assert Spec.call!(spec, -1) == -1
      assert Spec.call!(spec, 1) == nil
      assert Spec.run!(spec, [-1, 1]) == [-1]

      spec =
        spec do
          x -> -x
        end

      assert Spec.call!(spec, -1) == 1
      assert Spec.call!(spec, 1) == -1
      assert Spec.run!(spec, [-1, 1]) == [1, -1]
    end

    test "-/2" do
      spec =
        spec do
          x when x - 1 == 0 -> x
        end

      assert Spec.call!(spec, 1) == 1
      assert Spec.call!(spec, -1) == nil
      assert Spec.run!(spec, [1, -1]) == [1]

      spec =
        spec do
          x -> x - 1
        end

      assert Spec.call!(spec, 1) == 0
      assert Spec.call!(spec, 0) == -1
      assert Spec.run!(spec, [1, 0]) == [0, -1]
    end

    test "!=/2" do
      spec =
        spec do
          x when x != 1.0 -> x
        end

      assert Spec.call!(spec, 1.0) == nil
      assert Spec.call!(spec, 1) == nil
      assert Spec.call!(spec, 2.0) == 2.0
      assert Spec.call!(spec, 2) == 2
      assert Spec.run!(spec, [1, 1.0, 2, 2.0]) == [2, 2.0]

      spec =
        spec do
          x -> x != 1.0
        end

      assert Spec.call!(spec, 1) == false
      assert Spec.call!(spec, 1.0) == false
      assert Spec.call!(spec, 2) == true
      assert Spec.call!(spec, 2.0) == true
      assert Spec.run!(spec, [1, 1.0, 2, 2.0]) == [false, false, true, true]
    end

    test "!==/2" do
      spec =
        spec do
          x when x !== 1.0 -> x
        end

      assert Spec.call!(spec, 1) == 1
      assert Spec.call!(spec, 1.0) == nil
      assert Spec.call!(spec, 2) == 2
      assert Spec.call!(spec, 2.0) == 2.0
      assert Spec.run!(spec, [1, 1.0, 2, 2.0]) == [1, 2, 2.0]

      spec =
        spec do
          x -> x !== 1.0
        end

      assert Spec.call!(spec, 1) == true
      assert Spec.call!(spec, 1.0) == false
      assert Spec.call!(spec, 2) == true
      assert Spec.call!(spec, 2.0) == true
      assert Spec.run!(spec, [1, 1.0, 2, 2.0]) == [true, false, true, true]
    end

    test "*/2" do
      spec =
        spec do
          x when x * 2 == 4 -> x
        end

      assert Spec.call!(spec, 1) == nil
      assert Spec.call!(spec, 2) == 2
      assert Spec.run!(spec, [1, 2]) == [2]

      spec =
        spec do
          x -> x * 2
        end

      assert Spec.call!(spec, 1) == 2
      assert Spec.call!(spec, 2) == 4
      assert Spec.run!(spec, [1, 2]) == [2, 4]
    end

    test "//2" do
      spec =
        spec do
          x when x / 2 == 4 -> x
        end

      assert Spec.call!(spec, 8) == 8
      assert Spec.call!(spec, 9) == nil
      assert Spec.run!(spec, [8, 9]) == [8]

      spec =
        spec do
          x -> x / 2
        end

      assert Spec.call!(spec, 8) == 4
      assert Spec.call!(spec, 9) == 4.5
      assert Spec.run!(spec, [8, 9]) == [4, 4.5]
    end

    test "+/1" do
      spec =
        spec do
          x when x == +1 -> x
        end

      assert Spec.call!(spec, 1) == 1
      assert Spec.call!(spec, -1) == nil
      assert Spec.run!(spec, [1, -1]) == [1]

      spec =
        spec do
          x -> +x
        end

      assert Spec.call!(spec, -1) == -1
      assert Spec.call!(spec, 1) == 1
      assert Spec.run!(spec, [1, -1]) == [1, -1]
    end

    test "+/2" do
      spec =
        spec do
          x when x + 2 == 4 -> x
        end

      assert Spec.call!(spec, 2) == 2
      assert Spec.call!(spec, 3) == nil
      assert Spec.run!(spec, [2, 3]) == [2]

      spec =
        spec do
          x -> x + 2
        end

      assert Spec.call!(spec, 2) == 4
      assert Spec.call!(spec, 3) == 5
      assert Spec.run!(spec, [2, 3]) == [4, 5]
    end

    test "</2" do
      spec =
        spec do
          x when x < 2 -> x
        end

      assert Spec.call!(spec, 1) == 1
      assert Spec.call!(spec, 2) == nil
      assert Spec.call!(spec, 3) == nil
      assert Spec.run!(spec, [1, 2, 3]) == [1]

      spec =
        spec do
          x -> x < 2
        end

      assert Spec.call!(spec, 1) == true
      assert Spec.call!(spec, 2) == false
      assert Spec.call!(spec, 3) == false
      assert Spec.run!(spec, [1, 2, 3]) == [true, false, false]
    end

    test "<=/2" do
      spec =
        spec do
          x when x <= 2 -> x
        end

      assert Spec.call!(spec, 1) == 1
      assert Spec.call!(spec, 2) == 2
      assert Spec.call!(spec, 3) == nil
      assert Spec.run!(spec, [1, 2, 3]) == [1, 2]

      spec =
        spec do
          x -> x <= 2
        end

      assert Spec.call!(spec, 1) == true
      assert Spec.call!(spec, 2) == true
      assert Spec.call!(spec, 3) == false
      assert Spec.run!(spec, [1, 2, 3]) == [true, true, false]
    end

    test "==/2" do
      spec =
        spec do
          x when x == 1.0 -> x
        end

      assert Spec.call!(spec, 1) == 1
      assert Spec.call!(spec, 1.0) == 1.0
      assert Spec.call!(spec, 2) == nil
      assert Spec.call!(spec, 2.0) == nil
      assert Spec.run!(spec, [1, 1.0, 2, 2.0]) == [1, 1.0]

      spec =
        spec do
          x -> x == 1.0
        end

      assert Spec.call!(spec, 1) == true
      assert Spec.call!(spec, 1.0) == true
      assert Spec.call!(spec, 2) == false
      assert Spec.call!(spec, 2.0) == false
      assert Spec.run!(spec, [1, 1.0, 2, 2.0]) == [true, true, false, false]
    end

    test "and/2" do
      spec =
        spec do
          _x when true and false -> 0
        end

      assert spec.source == [{:"$1", [{:andalso, true, false}], [0]}]
    end

    test "is_atom/1" do
      spec =
        spec do
          x when is_atom(x) -> x
        end

      assert spec.source == [{:"$1", [{:is_atom, :"$1"}], [:"$1"]}]
    end

    test "is_binary/1" do
      spec =
        spec do
          x when is_binary(x) -> x
        end

      assert spec.source == [{:"$1", [{:is_binary, :"$1"}], [:"$1"]}]
    end

    test "is_bitstring/1", test_context do
      assert_raise Matcha.Rewrite.Error, ~r|unsupported function call.*?is_bitstring/1|s, fn ->
        defmodule test_module_name(test_context) do
          import Matcha

          spec do
            x when is_bitstring(x) -> x
          end
        end
      end
    end

    test "is_number/1" do
      spec =
        spec do
          {x} when is_number(x) -> x
        end

      assert spec.source == [{{:"$1"}, [{:is_number, :"$1"}], [:"$1"]}]
    end

    test "not/1" do
      spec =
        spec do
          _x when not true -> 0
        end

      assert spec.source == [{:"$1", [not: true], [0]}]
    end

    test "or/2" do
      spec =
        spec do
          _x when true or false -> 0
        end

      assert spec.source == [{:"$1", [{:orelse, true, false}], [0]}]
    end
  end
end
