defmodule ElixirGuards.UsageTest do
  @moduledoc false

  use UsageTest

  import Matcha

  import TestHelpers

  alias Matcha.Spec

  describe "Kernel guards" do
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

    test "===/2" do
      spec =
        spec do
          x when x === 1.0 -> x
        end

      assert Spec.call!(spec, 1) == nil
      assert Spec.call!(spec, 1.0) == 1.0
      assert Spec.call!(spec, 2) == nil
      assert Spec.call!(spec, 2.0) == nil
      assert Spec.run!(spec, [1, 1.0, 2, 2.0]) == [1.0]

      spec =
        spec do
          x -> x === 1.0
        end

      assert Spec.call!(spec, 1) == false
      assert Spec.call!(spec, 1.0) == true
      assert Spec.call!(spec, 2) == false
      assert Spec.call!(spec, 2.0) == false
      assert Spec.run!(spec, [1, 1.0, 2, 2.0]) == [false, true, false, false]
    end

    test ">/2" do
      spec =
        spec do
          x when x > 2 -> x
        end

      assert Spec.call!(spec, 1) == nil
      assert Spec.call!(spec, 2) == nil
      assert Spec.call!(spec, 3) == 3
      assert Spec.run!(spec, [1, 2, 3]) == [3]

      spec =
        spec do
          x -> x > 2
        end

      assert Spec.call!(spec, 1) == false
      assert Spec.call!(spec, 2) == false
      assert Spec.call!(spec, 3) == true
      assert Spec.run!(spec, [1, 2, 3]) == [false, false, true]
    end

    test ">=/2" do
      spec =
        spec do
          x when x >= 2 -> x
        end

      assert Spec.call!(spec, 1) == nil
      assert Spec.call!(spec, 2) == 2
      assert Spec.call!(spec, 3) == 3
      assert Spec.run!(spec, [1, 2, 3]) == [2, 3]

      spec =
        spec do
          x -> x >= 2
        end

      assert Spec.call!(spec, 1) == false
      assert Spec.call!(spec, 2) == true
      assert Spec.call!(spec, 3) == true
      assert Spec.run!(spec, [1, 2, 3]) == [false, true, true]
    end

    test "abs/1" do
      spec =
        spec do
          x when abs(x) == 1 -> x
        end

      assert Spec.call!(spec, 1) == 1
      assert Spec.call!(spec, 0) == nil
      assert Spec.call!(spec, -1) == -1
      assert Spec.run!(spec, [1, 0, -1]) == [1, -1]

      spec =
        spec do
          x -> abs(x)
        end

      assert Spec.call!(spec, 1) == 1
      assert Spec.call!(spec, 0) == 0
      assert Spec.call!(spec, -1) == 1
      assert Spec.run!(spec, [1, 0, -1]) == [1, 0, 1]
    end

    test "and/2" do
      spec =
        spec do
          x when true and false -> x
        end

      assert Spec.call!(spec, :anything) == nil
      assert Spec.run!(spec, [:anything, :at, :all]) == []

      spec =
        spec do
          {x, y} when x and y -> {x, y}
        end

      assert Spec.call!(spec, {true, true}) == {true, true}
      assert Spec.call!(spec, {true, false}) == nil
      assert Spec.call!(spec, {false, true}) == nil
      assert Spec.call!(spec, {false, false}) == nil

      assert Spec.run!(spec, [{true, true}, {true, false}, {false, true}, {false, false}]) == [
               {true, true}
             ]

      spec =
        spec do
          x -> true and x
        end

      assert Spec.call!(spec, :anything) == :anything
      assert Spec.run!(spec, [:anything, :at, :all]) == [:anything, :at, :all]

      spec =
        spec do
          x -> false and x
        end

      assert Spec.call!(spec, :anything) == false
      assert Spec.run!(spec, [:anything, :at, :all]) == [false, false, false]

      spec =
        spec do
          {x, y} -> x and y
        end

      assert Spec.call!(spec, {true, true}) == true
      assert Spec.call!(spec, {true, false}) == false
      assert Spec.call!(spec, {false, true}) == false
      assert Spec.call!(spec, {false, false}) == false

      assert Spec.run!(spec, [{true, true}, {true, false}, {false, true}, {false, false}]) == [
               true,
               false,
               false,
               false
             ]
    end

    if Matcha.Helpers.erlang_version() >= 25 do
      test "binary_part/3" do
        spec =
          spec do
            string when binary_part(string, 1, 2) == "bc" -> string
          end

        assert Spec.call!(spec, "abcd") == "abcd"
        assert Spec.call!(spec, "bcde") == nil
        assert Spec.run!(spec, ["abcd", "bcde"]) == ["abcd"]

        spec =
          spec do
            string -> binary_part(string, 1, 2)
          end

        # TODO: handle `:EXIT`s better in :filter_map/:match contexts
        assert Spec.call!(spec, "abcd") == "bc"
        assert Spec.call!(spec, "bcde") == "cd"
        assert Spec.call!(spec, "") == :EXIT

        assert Spec.run!(spec, ["abcd", "bcde", ""]) == [
                 "bc",
                 "cd",
                 :EXIT
               ]
      end
    else
      test "binary_part/3", test_context do
        assert_raise Matcha.Rewrite.Error, ~r|unsupported function call.*?binary_part/3|s, fn ->
          defmodule test_module_name(test_context, "in guards") do
            import Matcha

            spec do
              string when binary_part(string, 1, 2) == "bc" -> string
            end
          end
        end

        assert_raise Matcha.Rewrite.Error, ~r|unsupported function call.*?binary_part/3|s, fn ->
          defmodule test_module_name(test_context, "in bodies") do
            import Matcha

            spec do
              string -> binary_part(string, 1, 2)
            end
          end
        end
      end
    end

    test "bit_size/1" do
      spec =
        spec do
          x when bit_size("abc") == 24 -> x
        end

      assert Spec.call!(spec, :anything) == :anything
      assert Spec.run!(spec, [:anything, :at, :all]) == [:anything, :at, :all]

      spec =
        spec do
          string when bit_size(string) == 24 -> string
        end

      assert Spec.call!(spec, "ab") == nil
      assert Spec.call!(spec, "abc") == "abc"
      assert Spec.call!(spec, "abcd") == nil
      assert Spec.run!(spec, ["ab", "abc", "abcd"]) == ["abc"]

      spec =
        spec do
          _ -> bit_size("abc")
        end

      assert Spec.call!(spec, :anything) == 24
      assert Spec.run!(spec, [:anything, :at, :all]) == [24, 24, 24]

      spec =
        spec do
          string -> bit_size(string)
        end

      assert Spec.call!(spec, "ab") == 16
      assert Spec.call!(spec, "abc") == 24
      assert Spec.call!(spec, "abcd") == 32
      assert Spec.run!(spec, ["ab", "abc", "abcd"]) == [16, 24, 32]
    end

    if Matcha.Helpers.erlang_version() >= 25 do
      test "byte_size/1" do
        spec =
          spec do
            x when byte_size("abc") == 3 -> x
          end

        assert Spec.call!(spec, :anything) == :anything
        assert Spec.run!(spec, [:anything, :at, :all]) == [:anything, :at, :all]

        spec =
          spec do
            string when byte_size(string) == 3 -> string
          end

        assert Spec.call!(spec, "ab") == nil
        assert Spec.call!(spec, "abc") == "abc"
        assert Spec.call!(spec, "abcd") == nil
        assert Spec.run!(spec, ["ab", "abc", "abcd"]) == ["abc"]

        spec =
          spec do
            _ -> byte_size("abc")
          end

        assert Spec.call!(spec, :anything) == 3
        assert Spec.run!(spec, [:anything, :at, :all]) == [3, 3, 3]

        spec =
          spec do
            string -> byte_size(string)
          end

        assert Spec.call!(spec, "ab") == 2
        assert Spec.call!(spec, "abc") == 3
        assert Spec.call!(spec, "abcd") == 4
        assert Spec.run!(spec, ["ab", "abc", "abcd"]) == [2, 3, 4]
      end
    else
      test "byte_size/1", test_context do
        assert_raise Matcha.Rewrite.Error, ~r|unsupported function call.*?byte_size/1|s, fn ->
          defmodule test_module_name(test_context, "in guards") do
            import Matcha

            spec do
              string when byte_size(string) == 3 -> string
            end
          end
        end

        assert_raise Matcha.Rewrite.Error, ~r|unsupported function call.*?byte_size/1|s, fn ->
          defmodule test_module_name(test_context, "in bodies") do
            import Matcha

            spec do
              string -> byte_size(string)
            end
          end
        end
      end
    end

    if Matcha.Helpers.erlang_version() >= 26 do
      test "ceil/2" do
        spec =
          spec do
            x when ceil(0.9) == 1 -> x
          end

        assert Spec.call!(spec, :anything) == :anything
        assert Spec.run!(spec, [:anything, :at, :all]) == [:anything, :at, :all]

        spec =
          spec do
            x when ceil(x) == 1 -> x
          end

        assert Spec.call!(spec, 0.9) == 0.9
        assert Spec.call!(spec, 1.9) == nil
        assert Spec.run!(spec, [0.9, 1.9]) == [0.9]

        spec =
          spec do
            _x -> ceil(0.9)
          end

        assert Spec.call!(spec, :anything) == 1
        assert Spec.run!(spec, [:anything, :at, :all]) == [1, 1, 1]

        spec =
          spec do
            x -> ceil(x)
          end

        assert Spec.call!(spec, 0.9) == 1
        assert Spec.call!(spec, 1.9) == 2
        assert Spec.run!(spec, [0.9, 1.9]) == [1, 2]
      end
    else
      test "ceil/1", test_context do
        assert_raise Matcha.Rewrite.Error, ~r|unsupported function call.*?ceil/1|s, fn ->
          defmodule test_module_name(test_context, "in guards") do
            import Matcha

            spec do
              num when ceil(num) == 5 -> num
            end
          end
        end

        assert_raise Matcha.Rewrite.Error, ~r|unsupported function call.*?ceil/1|s, fn ->
          defmodule test_module_name(test_context, "in bodies") do
            import Matcha

            spec do
              num -> ceil(num)
            end
          end
        end
      end
    end

    test "div/2" do
      spec =
        spec do
          x when div(9, 2) == 4 -> x
        end

      assert Spec.call!(spec, :anything) == :anything
      assert Spec.run!(spec, [:anything, :at, :all]) == [:anything, :at, :all]

      spec =
        spec do
          x when div(x, 2) == 4 -> x
        end

      assert Spec.call!(spec, 7) == nil
      assert Spec.call!(spec, 8) == 8
      assert Spec.call!(spec, 9) == 9
      assert Spec.call!(spec, 10) == nil
      assert Spec.run!(spec, [7, 8, 9, 10]) == [8, 9]

      spec =
        spec do
          _ -> div(9, 2)
        end

      assert Spec.call!(spec, :anything) == 4
      assert Spec.run!(spec, [:anything, :at, :all]) == [4, 4, 4]

      spec =
        spec do
          x -> div(x, 2)
        end

      assert Spec.call!(spec, 7) == 3
      assert Spec.call!(spec, 8) == 4
      assert Spec.call!(spec, 9) == 4
      assert Spec.call!(spec, 10) == 5
      assert Spec.run!(spec, [7, 8, 9, 10]) == [3, 4, 4, 5]
    end

    test "elem/2" do
      spec =
        spec do
          x when elem({:one}, 0) == :one -> x
        end

      assert Spec.call!(spec, :anything) == :anything
      assert Spec.run!(spec, [:anything, :at, :all]) == [:anything, :at, :all]

      spec =
        spec do
          x when elem(x, 0) == :one -> x
        end

      assert Spec.call!(spec, {:one, :two}) == {:one, :two}
      assert Spec.call!(spec, {:three, :four}) == nil
      assert Spec.run!(spec, one: :two, three: :four) == [one: :two]

      spec =
        spec do
          _x -> elem({:one}, 0)
        end

      assert Spec.call!(spec, :anything) == :one
      assert Spec.run!(spec, [:anything, :at, :all]) == [:one, :one, :one]

      spec =
        spec do
          x -> elem(x, 0)
        end

      assert Spec.call!(spec, {:one, :two}) == :one
      assert Spec.call!(spec, {:three, :four}) == :three
      assert Spec.run!(spec, one: :two, three: :four) == [:one, :three]
    end

    if Matcha.Helpers.erlang_version() >= 26 do
      test "floor/2" do
        spec =
          spec do
            x when floor(1.1) == 1 -> x
          end

        assert Spec.call!(spec, :anything) == :anything
        assert Spec.run!(spec, [:anything, :at, :all]) == [:anything, :at, :all]

        spec =
          spec do
            x when floor(x) == 1 -> x
          end

        assert Spec.call!(spec, 1.1) == 1.1
        assert Spec.call!(spec, 2.1) == nil
        assert Spec.run!(spec, [1.1, 2.1]) == [1.1]

        spec =
          spec do
            _x -> floor(1.1)
          end

        assert Spec.call!(spec, :anything) == 1
        assert Spec.run!(spec, [:anything, :at, :all]) == [1, 1, 1]

        spec =
          spec do
            x -> floor(x)
          end

        assert Spec.call!(spec, 1.1) == 1
        assert Spec.call!(spec, 2.1) == 2
        assert Spec.run!(spec, [1.1, 2.1]) == [1, 2]
      end
    else
      test "floor/1", test_context do
        assert_raise Matcha.Rewrite.Error, ~r|unsupported function call.*?floor/1|s, fn ->
          defmodule test_module_name(test_context, "in guards") do
            import Matcha

            spec do
              num when floor(num) == 5 -> num
            end
          end
        end

        assert_raise Matcha.Rewrite.Error, ~r|unsupported function call.*?floor/1|s, fn ->
          defmodule test_module_name(test_context, "in bodies") do
            import Matcha

            spec do
              num -> floor(num)
            end
          end
        end
      end
    end

    test "hd/1" do
      spec =
        spec do
          x when hd([:one]) == :one -> x
        end

      assert Spec.call!(spec, :anything) == :anything
      assert Spec.run!(spec, [:anything, :at, :all]) == [:anything, :at, :all]

      spec =
        spec do
          x when hd(x) == :one -> x
        end

      assert Spec.call!(spec, {}) == nil
      assert Spec.call!(spec, []) == nil
      assert Spec.call!(spec, [:one, :two]) == [:one, :two]
      assert Spec.call!(spec, [:three, :four]) == nil
      assert Spec.run!(spec, [{}, [:one, :two], [:three, :four]]) == [[:one, :two]]

      spec =
        spec do
          _x -> hd([:one])
        end

      assert Spec.call!(spec, :anything) == :one
      assert Spec.run!(spec, [:anything, :at, :all]) == [:one, :one, :one]

      spec =
        spec do
          x -> hd(x)
        end

      assert Spec.call!(spec, {}) == :EXIT
      assert Spec.call!(spec, []) == :EXIT
      assert Spec.call!(spec, [:one, :two]) == :one
      assert Spec.call!(spec, [:three, :four]) == :three

      assert Spec.run!(spec, [{}, [], [:one, :two], [:three, :four]]) == [
               :EXIT,
               :EXIT,
               :one,
               :three
             ]
    end

    test "in/2 with compile-time lists/ranges" do
      spec =
        spec do
          x when x in [:one, :two, :three] -> x
        end

      assert Spec.call!(spec, :one) == :one
      assert Spec.call!(spec, :two) == :two
      assert Spec.call!(spec, :three) == :three
      assert Spec.call!(spec, :four) == nil
      assert Spec.run!(spec, [:one, :two, :three, :four]) == [:one, :two, :three]

      spec =
        spec do
          x when x in ~w[one two three]a -> x
        end

      assert Spec.call!(spec, :one) == :one
      assert Spec.call!(spec, :two) == :two
      assert Spec.call!(spec, :three) == :three
      assert Spec.call!(spec, :four) == nil
      assert Spec.run!(spec, [:one, :two, :three, :four]) == [:one, :two, :three]

      spec =
        spec do
          x when x in 1..3 -> x
        end

      assert Spec.call!(spec, 1) == 1
      assert Spec.call!(spec, 2) == 2
      assert Spec.call!(spec, 3) == 3
      assert Spec.call!(spec, 4) == nil
      assert Spec.run!(spec, [1, 2, 3, 4]) == [1, 2, 3]

      spec =
        spec do
          x when x in 1..3//2 -> x
        end

      assert Spec.call!(spec, 1) == 1
      assert Spec.call!(spec, 2) == nil
      assert Spec.call!(spec, 3) == 3
      assert Spec.call!(spec, 4) == nil
      assert Spec.run!(spec, [1, 2, 3, 4]) == [1, 3]

      spec =
        spec do
          x when x in ?a..?f -> x
        end

      assert Spec.call!(spec, ?a) == ?a
      assert Spec.call!(spec, ?c) == ?c
      assert Spec.call!(spec, ?f) == ?f
      assert Spec.call!(spec, ?z) == nil
      assert Spec.run!(spec, [?a, ?c, ?f, ?z]) == [?a, ?c, ?f]

      spec =
        spec do
          x -> x in [:one, :two, :three]
        end

      assert Spec.call!(spec, :one) == true
      assert Spec.call!(spec, :two) == true
      assert Spec.call!(spec, :three) == true
      assert Spec.call!(spec, :four) == false
      assert Spec.run!(spec, [:one, :two, :three, :four]) == [true, true, true, false]

      spec =
        spec do
          x -> x in ~w[one two three]a
        end

      assert Spec.call!(spec, :one) == true
      assert Spec.call!(spec, :two) == true
      assert Spec.call!(spec, :three) == true
      assert Spec.call!(spec, :four) == false
      assert Spec.run!(spec, [:one, :two, :three, :four]) == [true, true, true, false]

      spec =
        spec do
          x -> x in 1..3
        end

      assert Spec.call!(spec, 1) == true
      assert Spec.call!(spec, 2) == true
      assert Spec.call!(spec, 3) == true
      assert Spec.call!(spec, 4) == false
      assert Spec.run!(spec, [1, 2, 3, 4]) == [true, true, true, false]

      spec =
        spec do
          x -> x in 1..3//2
        end

      assert Spec.call!(spec, 1) == true
      assert Spec.call!(spec, 2) == false
      assert Spec.call!(spec, 3) == true
      assert Spec.call!(spec, 4) == false
      assert Spec.run!(spec, [1, 2, 3, 4]) == [true, false, true, false]

      spec =
        spec do
          x -> x in ?a..?f
        end

      assert Spec.call!(spec, ?a) == true
      assert Spec.call!(spec, ?c) == true
      assert Spec.call!(spec, ?f) == true
      assert Spec.call!(spec, ?z) == false
      assert Spec.run!(spec, [?a, ?c, ?f, ?z]) == [true, true, true, false]
    end

    test "is_atom/1" do
      spec =
        spec do
          x when is_atom(x) -> x
        end

      assert Spec.call!(spec, :one) == :one
      assert Spec.call!(spec, 1) == nil
      assert Spec.run!(spec, [:one, 1]) == [:one]

      spec =
        spec do
          x -> is_atom(x)
        end

      assert Spec.call!(spec, :one) == true
      assert Spec.call!(spec, 1) == false
      assert Spec.run!(spec, [:one, 1]) == [true, false]
    end

    test "is_binary/1" do
      spec =
        spec do
          x when is_binary(x) -> x
        end

      assert Spec.call!(spec, "one") == "one"
      assert Spec.call!(spec, 1) == nil
      assert Spec.run!(spec, ["one", 1]) == ["one"]

      spec =
        spec do
          x -> is_binary(x)
        end

      assert Spec.call!(spec, "one") == true
      assert Spec.call!(spec, 1) == false
      assert Spec.run!(spec, ["one", 1]) == [true, false]
    end

    test "is_bitstring/1", test_context do
      assert_raise Matcha.Rewrite.Error, ~r|unsupported function call.*?is_bitstring/1|s, fn ->
        defmodule test_module_name(test_context, "in guards") do
          import Matcha

          spec do
            x when is_bitstring(x) -> x
          end
        end
      end

      assert_raise Matcha.Rewrite.Error, ~r|unsupported function call.*?is_bitstring/1|s, fn ->
        defmodule test_module_name(test_context, "in bodies") do
          import Matcha

          spec do
            x -> is_bitstring(x)
          end
        end
      end
    end

    test "is_boolean/1" do
      spec =
        spec do
          x when is_boolean(x) -> x
        end

      assert Matcha.Spec.call!(spec, true) == true
      assert Matcha.Spec.call!(spec, false) == false
      assert Matcha.Spec.call!(spec, nil) == nil
      assert Matcha.Spec.call!(spec, 1) == nil

      assert Matcha.Spec.run!(spec, [true, false, nil, 1]) == [true, false]

      spec =
        spec do
          x -> is_boolean(x)
        end

      assert Matcha.Spec.call!(spec, true) == true
      assert Matcha.Spec.call!(spec, false) == true
      assert Matcha.Spec.call!(spec, nil) == false
      assert Matcha.Spec.call!(spec, 1) == false

      assert Matcha.Spec.run!(spec, [true, false, nil, 1]) == [true, true, false, false]
    end

    test "is_exception/1" do
      spec =
        spec do
          x when is_exception(x) -> x
        end

      assert Matcha.Spec.call!(spec, %ArgumentError{}) == %ArgumentError{}
      assert Matcha.Spec.call!(spec, %CompileError{}) == %CompileError{}
      assert Matcha.Spec.call!(spec, 1..2) == nil
      assert Matcha.Spec.call!(spec, %{}) == nil
      assert Matcha.Spec.call!(spec, :other) == nil

      assert Matcha.Spec.run!(spec, [%ArgumentError{}, %CompileError{}, 1..2, %{}, :other]) == [
               %ArgumentError{},
               %CompileError{}
             ]

      spec =
        spec do
          x -> is_exception(x)
        end

      assert Matcha.Spec.call!(spec, %ArgumentError{}) == true
      assert Matcha.Spec.call!(spec, %CompileError{}) == true
      assert Matcha.Spec.call!(spec, 1..2) == false
      assert Matcha.Spec.call!(spec, %{}) == false
      assert Matcha.Spec.call!(spec, :other) == false

      assert Matcha.Spec.run!(spec, [
               %ArgumentError{},
               %CompileError{},
               1..2,
               %{},
               :other
             ]) == [true, true, false, false, false]
    end

    test "is_exception/2" do
      spec =
        spec do
          x when is_exception(x, ArgumentError) -> x
        end

      assert Matcha.Spec.call!(spec, %ArgumentError{}) == %ArgumentError{}
      assert Matcha.Spec.call!(spec, %CompileError{}) == nil
      assert Matcha.Spec.call!(spec, 1..2) == nil
      assert Matcha.Spec.call!(spec, %{}) == nil
      assert Matcha.Spec.call!(spec, :other) == nil

      assert Matcha.Spec.run!(spec, [%ArgumentError{}, %CompileError{}, 1..2, %{}, :other]) == [
               %ArgumentError{}
             ]

      spec =
        spec do
          x -> is_exception(x, ArgumentError)
        end

      assert Matcha.Spec.call!(spec, %ArgumentError{}) == true
      assert Matcha.Spec.call!(spec, %CompileError{}) == false
      assert Matcha.Spec.call!(spec, 1..2) == false
      assert Matcha.Spec.call!(spec, %{}) == false
      assert Matcha.Spec.call!(spec, :other) == false

      assert Matcha.Spec.run!(spec, [
               %ArgumentError{},
               %CompileError{},
               1..2,
               %{},
               :other
             ]) == [true, false, false, false, false]
    end

    test "is_float/1" do
      spec =
        spec do
          x when is_float(x) -> x
        end

      assert Matcha.Spec.call!(spec, 1.0) == 1.0
      assert Matcha.Spec.call!(spec, 1) == nil
      assert Matcha.Spec.run!(spec, [1.0, 1]) == [1.0]

      spec =
        spec do
          x -> is_float(x)
        end

      assert Matcha.Spec.call!(spec, 1.0) == true
      assert Matcha.Spec.call!(spec, 1) == false
      assert Matcha.Spec.run!(spec, [1.0, 1]) == [true, false]
    end

    test "is_function/1" do
      fun = fn -> nil end

      spec =
        spec do
          x when is_function(x) -> x
        end

      assert Matcha.Spec.call!(spec, fun) == fun
      assert Matcha.Spec.call!(spec, :other) == nil
      assert Matcha.Spec.run!(spec, [fun, :other]) == [fun]

      spec =
        spec do
          x -> is_function(x)
        end

      assert Matcha.Spec.call!(spec, fun) == true
      assert Matcha.Spec.call!(spec, :other) == false
      assert Matcha.Spec.run!(spec, [fun, :other]) == [true, false]
    end

    if Matcha.Helpers.erlang_version() >= 26 do
      test "is_function/2" do
        fun0 = fn -> 0 end
        fun1 = fn _ -> 1 end

        spec =
          spec do
            x when is_function(x, 0) -> x
          end

        assert Matcha.Spec.call!(spec, fun0) == fun0
        assert Matcha.Spec.call!(spec, fun1) == nil
        assert Matcha.Spec.call!(spec, :other) == nil
        assert Matcha.Spec.run!(spec, [fun0, fun1, :other]) == [fun0]

        spec =
          spec do
            x -> is_function(x, 0)
          end

        assert Matcha.Spec.call!(spec, fun0) == true
        assert Matcha.Spec.call!(spec, fun1) == false
        assert Matcha.Spec.call!(spec, :other) == false
        assert Matcha.Spec.run!(spec, [fun0, fun1, :other]) == [true, false, false]
      end
    else
      test "is_function/2", test_context do
        assert_raise Matcha.Rewrite.Error, ~r|unsupported function call.*?is_function/2|s, fn ->
          defmodule test_module_name(test_context, "in guards") do
            import Matcha

            spec do
              x when is_function(x, 0) -> x
            end
          end
        end

        assert_raise Matcha.Rewrite.Error, ~r|unsupported function call.*?is_function/2|s, fn ->
          defmodule test_module_name(test_context, "in bodies") do
            import Matcha

            spec do
              x -> is_function(x, 0)
            end
          end
        end
      end
    end

    test "is_integer/1" do
      spec =
        spec do
          x when is_integer(x) -> x
        end

      assert Matcha.Spec.call!(spec, 1) == 1
      assert Matcha.Spec.call!(spec, 1.0) == nil
      assert Matcha.Spec.run!(spec, [1, 1.0]) == [1]

      spec =
        spec do
          x -> is_integer(x)
        end

      assert Matcha.Spec.call!(spec, 1) == true
      assert Matcha.Spec.call!(spec, 1.0) == false
      assert Matcha.Spec.run!(spec, [1, 1.0]) == [true, false]
    end

    test "is_list/1" do
      spec =
        spec do
          x when is_list(x) -> x
        end

      assert Matcha.Spec.call!(spec, []) == []
      assert Matcha.Spec.call!(spec, {}) == nil
      assert Matcha.Spec.run!(spec, [[], {}]) == [[]]

      spec =
        spec do
          x -> is_list(x)
        end

      assert Matcha.Spec.call!(spec, []) == true
      assert Matcha.Spec.call!(spec, {}) == false
      assert Matcha.Spec.run!(spec, [[], {}]) == [true, false]
    end

    test "is_map_key/2" do
      spec =
        spec do
          x when is_map_key(x, :key) -> x
        end

      assert Matcha.Spec.call!(spec, %{key: :value}) == %{key: :value}
      assert Matcha.Spec.call!(spec, %{}) == nil
      assert Matcha.Spec.call!(spec, 1) == nil
      assert Matcha.Spec.run!(spec, [%{key: :value}, %{}, 1]) == [%{key: :value}]

      spec =
        spec do
          x -> is_map_key(x, :key)
        end

      assert Matcha.Spec.call!(spec, %{key: :value}) == true
      assert Matcha.Spec.call!(spec, %{}) == false
      assert Matcha.Spec.call!(spec, 1) == :EXIT
      assert Matcha.Spec.run!(spec, [%{key: :value}, %{}, 1]) == [true, false, :EXIT]
    end

    test "is_map/1" do
      spec =
        spec do
          x when is_map(x) -> x
        end

      assert Matcha.Spec.call!(spec, %{}) == %{}
      assert Matcha.Spec.call!(spec, {}) == nil
      assert Matcha.Spec.run!(spec, [%{}, {}]) == [%{}]

      spec =
        spec do
          x -> is_map(x)
        end

      assert Matcha.Spec.call!(spec, %{}) == true
      assert Matcha.Spec.call!(spec, {}) == false
      assert Matcha.Spec.run!(spec, [%{}, {}]) == [true, false]
    end

    test "is_nil/1" do
      spec =
        spec(:match) do
          x when is_nil(x) -> x
        end

      assert Matcha.Spec.call!(spec, nil) == {:matched, nil}
      assert Matcha.Spec.call!(spec, :other) == :no_match
      assert Matcha.Spec.run!(spec, [nil, :other]) == [{:matched, nil}, :no_match]

      spec =
        spec(:match) do
          x -> is_nil(x)
        end

      assert Matcha.Spec.call!(spec, nil) == {:matched, true}
      assert Matcha.Spec.call!(spec, :other) == {:matched, false}
      assert Matcha.Spec.run!(spec, [nil, :other]) == [{:matched, true}, {:matched, false}]
    end

    test "is_number/1" do
      spec =
        spec do
          x when is_number(x) -> x
        end

      assert Matcha.Spec.call!(spec, 1) == 1
      assert Matcha.Spec.call!(spec, 1.0) == 1.0
      assert Matcha.Spec.call!(spec, :other) == nil
      assert Matcha.Spec.run!(spec, [1, 1.0, :other]) == [1, 1.0]

      spec =
        spec do
          x -> is_number(x)
        end

      assert Matcha.Spec.call!(spec, 1) == true
      assert Matcha.Spec.call!(spec, 1.0) == true
      assert Matcha.Spec.call!(spec, :other) == false
      assert Matcha.Spec.run!(spec, [1, 1.0, :other]) == [true, true, false]
    end

    test "is_pid/1" do
      spec =
        spec do
          x when is_pid(x) -> x
        end

      assert Matcha.Spec.call!(spec, self()) == self()
      assert Matcha.Spec.call!(spec, :other) == nil
      assert Matcha.Spec.run!(spec, [self(), :other]) == [self()]

      spec =
        spec do
          x -> is_pid(x)
        end

      assert Matcha.Spec.call!(spec, self()) == true
      assert Matcha.Spec.call!(spec, :other) == false
      assert Matcha.Spec.run!(spec, [self(), :other]) == [true, false]
    end

    test "is_port/1" do
      port = Port.open({:spawn, "cat"}, [:binary])

      spec =
        spec do
          x when is_port(x) -> x
        end

      assert Matcha.Spec.call!(spec, port) == port
      assert Matcha.Spec.call!(spec, :other) == nil
      assert Matcha.Spec.run!(spec, [port, :other]) == [port]

      spec =
        spec do
          x -> is_port(x)
        end

      assert Matcha.Spec.call!(spec, port) == true
      assert Matcha.Spec.call!(spec, :other) == false
      assert Matcha.Spec.run!(spec, [port, :other]) == [true, false]

      Port.close(port)
    end

    test "is_reference/1" do
      reference = make_ref()

      spec =
        spec do
          x when is_reference(x) -> x
        end

      assert Matcha.Spec.call!(spec, reference) == reference
      assert Matcha.Spec.call!(spec, :other) == nil
      assert Matcha.Spec.run!(spec, [reference, :other]) == [reference]

      spec =
        spec do
          x -> is_reference(x)
        end

      assert Matcha.Spec.call!(spec, reference) == true
      assert Matcha.Spec.call!(spec, :other) == false
      assert Matcha.Spec.run!(spec, [reference, :other]) == [true, false]
    end

    test "is_struct/1" do
      spec =
        spec do
          x when is_struct(x) -> x
        end

      assert Matcha.Spec.call!(spec, 1..2) == 1..2
      assert Matcha.Spec.call!(spec, %ArgumentError{}) == %ArgumentError{}
      assert Matcha.Spec.call!(spec, :other) == nil
      assert Matcha.Spec.run!(spec, [1..2, :other]) == [1..2]

      spec =
        spec do
          x -> is_struct(x)
        end

      assert Matcha.Spec.call!(spec, 1..2) == true
      assert Matcha.Spec.call!(spec, %ArgumentError{}) == true
      assert Matcha.Spec.call!(spec, :other) == false
      assert Matcha.Spec.run!(spec, [1..2, %ArgumentError{}, :other]) == [true, true, false]
    end

    test "is_struct/2" do
      spec =
        spec do
          x when is_struct(x, Range) -> x
        end

      assert Matcha.Spec.call!(spec, 1..2) == 1..2
      assert Matcha.Spec.call!(spec, %ArgumentError{}) == nil
      assert Matcha.Spec.call!(spec, :other) == nil
      assert Matcha.Spec.run!(spec, [1..2, %ArgumentError{}, :other]) == [1..2]

      spec =
        spec do
          x -> is_struct(x, Range)
        end

      assert Matcha.Spec.call!(spec, 1..2) == true
      assert Matcha.Spec.call!(spec, %ArgumentError{}) == false
      assert Matcha.Spec.call!(spec, :other) == false
      assert Matcha.Spec.run!(spec, [1..2, %ArgumentError{}, :other]) == [true, false, false]
    end

    test "is_tuple/1" do
      spec =
        spec do
          x when is_tuple(x) -> x
        end

      assert Matcha.Spec.call!(spec, {}) == {}
      assert Matcha.Spec.call!(spec, []) == nil
      assert Matcha.Spec.run!(spec, [{}, []]) == [{}]

      spec =
        spec do
          x -> is_tuple(x)
        end

      assert Matcha.Spec.call!(spec, {}) == true
      assert Matcha.Spec.call!(spec, []) == false
      assert Matcha.Spec.run!(spec, [{}, []]) == [true, false]
    end

    test "length/1" do
      spec =
        spec do
          x when length(x) == 1 -> x
        end

      assert Matcha.Spec.call!(spec, []) == nil
      assert Matcha.Spec.call!(spec, [:one]) == [:one]
      assert Matcha.Spec.call!(spec, [:one, :two]) == nil
      assert Matcha.Spec.call!(spec, {}) == nil
      assert Matcha.Spec.run!(spec, [[], [:one], [:one, :two], {}]) == [[:one]]

      spec =
        spec do
          x -> length(x)
        end

      assert Matcha.Spec.call!(spec, []) == 0
      assert Matcha.Spec.call!(spec, [:one]) == 1
      assert Matcha.Spec.call!(spec, [:one, :two]) == 2
      assert Matcha.Spec.call!(spec, {}) == :EXIT
      assert Matcha.Spec.run!(spec, [[], [:one], [:one, :two], {}]) == [0, 1, 2, :EXIT]
    end

    test "map_size/1" do
      spec =
        spec do
          x when map_size(x) == 1 -> x
        end

      assert Matcha.Spec.call!(spec, %{}) == nil
      assert Matcha.Spec.call!(spec, %{one: 1}) == %{one: 1}
      assert Matcha.Spec.call!(spec, %{one: 1, two: 2}) == nil
      assert Matcha.Spec.call!(spec, {}) == nil
      assert Matcha.Spec.run!(spec, [%{}, %{one: 1}, %{one: 1, two: 2}, {}]) == [%{one: 1}]

      spec =
        spec do
          x -> map_size(x)
        end

      assert Matcha.Spec.call!(spec, %{}) == 0
      assert Matcha.Spec.call!(spec, %{one: 1}) == 1
      assert Matcha.Spec.call!(spec, %{one: 1, two: 2}) == 2
      assert Matcha.Spec.call!(spec, {}) == :EXIT
      assert Matcha.Spec.run!(spec, [%{}, %{one: 1}, %{one: 1, two: 2}, {}]) == [0, 1, 2, :EXIT]
    end

    test "node/0" do
      spec =
        spec do
          x when node() == x -> true
        end

      assert Matcha.Spec.call!(spec, node()) == true
      assert Matcha.Spec.call!(spec, :other) == nil
      assert Matcha.Spec.run!(spec, [node(), :other]) == [true]

      spec =
        spec do
          x when x == 1 -> node()
        end

      assert Matcha.Spec.call!(spec, 1) == node()
      assert Matcha.Spec.call!(spec, :other) == nil
      assert Matcha.Spec.run!(spec, [1, :other]) == [node()]
    end

    test "node/1" do
      spec =
        spec do
          x when node(self()) == x -> true
        end

      assert Matcha.Spec.call!(spec, node()) == true
      assert Matcha.Spec.call!(spec, :other) == nil
      assert Matcha.Spec.run!(spec, [node(), :other]) == [true]

      spec =
        spec do
          x -> node(x)
        end

      assert Matcha.Spec.call!(spec, self()) == node()
      assert Matcha.Spec.call!(spec, :other) == :EXIT
      assert Matcha.Spec.run!(spec, [self(), :other]) == [node(), :EXIT]
    end

    test "not/1" do
      spec =
        spec do
          x when not x -> x
        end

      assert Matcha.Spec.call!(spec, true) == nil
      assert Matcha.Spec.call!(spec, false) == false
      assert Matcha.Spec.call!(spec, nil) == nil
      assert Matcha.Spec.call!(spec, :other) == nil
      assert Matcha.Spec.run!(spec, [true, false, nil, :other]) == [false]

      spec =
        spec do
          x -> not x
        end

      assert Matcha.Spec.call!(spec, true) == false
      assert Matcha.Spec.call!(spec, false) == true
      assert Matcha.Spec.call!(spec, nil) == :EXIT
      assert Matcha.Spec.call!(spec, :other) == :EXIT
      assert Matcha.Spec.run!(spec, [true, false, nil, :other]) == [false, true, :EXIT, :EXIT]
    end

    test "or/2" do
      spec =
        spec do
          x when false or x -> :success
        end

      assert Matcha.Spec.call!(spec, true) == :success
      assert Matcha.Spec.call!(spec, false) == nil
      assert Matcha.Spec.call!(spec, nil) == nil
      assert Matcha.Spec.call!(spec, :other) == nil
      assert Matcha.Spec.run!(spec, [true, false, nil, :other]) == [:success]

      spec =
        spec do
          x -> true or x
        end

      assert Spec.call!(spec, :anything) == true
      assert Spec.run!(spec, [:anything, :at, :all]) == [true, true, true]

      spec =
        spec do
          x -> false or x
        end

      assert Spec.call!(spec, :anything) == :anything
      assert Spec.run!(spec, [:anything, :at, :all]) == [:anything, :at, :all]

      spec =
        spec do
          {x, y} -> x or y
        end

      assert Spec.call!(spec, {true, true}) == true
      assert Spec.call!(spec, {true, false}) == true
      assert Spec.call!(spec, {false, true}) == true
      assert Spec.call!(spec, {false, false}) == false

      assert Spec.run!(spec, [{true, true}, {true, false}, {false, true}, {false, false}]) == [
               true,
               true,
               true,
               false
             ]
    end

    test "rem/2" do
      spec =
        spec do
          x when rem(x, 0) == 0 -> x
        end

      assert Matcha.Spec.call!(spec, -2) == nil
      assert Matcha.Spec.call!(spec, -1) == nil
      assert Matcha.Spec.call!(spec, 0) == nil
      assert Matcha.Spec.call!(spec, 1) == nil
      assert Matcha.Spec.call!(spec, 2) == nil
      assert Matcha.Spec.call!(spec, 3) == nil
      assert Matcha.Spec.call!(spec, :other) == nil
      assert Matcha.Spec.run!(spec, [-2, -1, 0, 1, 2, 3, :other]) == []

      spec =
        spec do
          x -> rem(x, 0)
        end

      assert Matcha.Spec.call!(spec, -2) == :EXIT
      assert Matcha.Spec.call!(spec, -1) == :EXIT
      assert Matcha.Spec.call!(spec, 0) == :EXIT
      assert Matcha.Spec.call!(spec, 1) == :EXIT
      assert Matcha.Spec.call!(spec, 2) == :EXIT
      assert Matcha.Spec.call!(spec, 3) == :EXIT
      assert Matcha.Spec.call!(spec, :other) == :EXIT

      assert Matcha.Spec.run!(spec, [-2, -1, 0, 1, 2, 3, :other]) == [
               :EXIT,
               :EXIT,
               :EXIT,
               :EXIT,
               :EXIT,
               :EXIT,
               :EXIT
             ]

      spec =
        spec do
          x when rem(x, 2) == 0 -> x
        end

      assert Matcha.Spec.call!(spec, -2) == -2
      assert Matcha.Spec.call!(spec, -1) == nil
      assert Matcha.Spec.call!(spec, 0) == 0
      assert Matcha.Spec.call!(spec, 1) == nil
      assert Matcha.Spec.call!(spec, 2) == 2
      assert Matcha.Spec.call!(spec, 3) == nil
      assert Matcha.Spec.call!(spec, :other) == nil
      assert Matcha.Spec.run!(spec, [-2, -1, 0, 1, 2, 3, :other]) == [-2, 0, 2]

      spec =
        spec do
          x -> rem(x, 2)
        end

      assert Matcha.Spec.call!(spec, -2) == 0
      assert Matcha.Spec.call!(spec, -1) == -1
      assert Matcha.Spec.call!(spec, 0) == 0
      assert Matcha.Spec.call!(spec, 1) == 1
      assert Matcha.Spec.call!(spec, 2) == 0
      assert Matcha.Spec.call!(spec, 3) == 1
      assert Matcha.Spec.call!(spec, :other) == :EXIT
      assert Matcha.Spec.run!(spec, [-2, -1, 0, 1, 2, 3, :other]) == [0, -1, 0, 1, 0, 1, :EXIT]
    end

    test "round/1" do
      spec =
        spec do
          x when round(x) == 0 -> x
        end

      assert Matcha.Spec.call!(spec, -0.6) == nil
      assert Matcha.Spec.call!(spec, -0.5) == nil
      assert Matcha.Spec.call!(spec, -0.4) == -0.4
      assert Matcha.Spec.call!(spec, 0) == 0
      assert Matcha.Spec.call!(spec, 0.4) == 0.4
      assert Matcha.Spec.call!(spec, 0.5) == nil
      assert Matcha.Spec.call!(spec, 0.6) == nil
      assert Matcha.Spec.call!(spec, :other) == nil

      assert Matcha.Spec.run!(spec, [-0.6, -0.5, -0.4, 0, 0.4, 0.5, 0.6, :other]) == [
               -0.4,
               0,
               0.4
             ]

      spec =
        spec do
          x when round(x) == 1 -> x
        end

      assert Matcha.Spec.call!(spec, 0.4) == nil
      assert Matcha.Spec.call!(spec, 0.5) == 0.5
      assert Matcha.Spec.call!(spec, 0.6) == 0.6
      assert Matcha.Spec.call!(spec, 1) == 1
      assert Matcha.Spec.call!(spec, 1.4) == 1.4
      assert Matcha.Spec.call!(spec, 1.5) == nil
      assert Matcha.Spec.call!(spec, 1.6) == nil
      assert Matcha.Spec.call!(spec, :other) == nil

      assert Matcha.Spec.run!(spec, [0.4, 0.5, 0.6, 1, 1.4, 1.5, 1.6, :other]) == [
               0.5,
               0.6,
               1,
               1.4
             ]

      spec =
        spec do
          x -> round(x)
        end

      assert Matcha.Spec.call!(spec, -0.6) == -1
      assert Matcha.Spec.call!(spec, -0.5) == -1
      assert Matcha.Spec.call!(spec, -0.4) == 0
      assert Matcha.Spec.call!(spec, 0) == 0
      assert Matcha.Spec.call!(spec, 0.4) == 0
      assert Matcha.Spec.call!(spec, 0.5) == 1
      assert Matcha.Spec.call!(spec, 0.6) == 1
      assert Matcha.Spec.call!(spec, 1) == 1
      assert Matcha.Spec.call!(spec, 1.4) == 1
      assert Matcha.Spec.call!(spec, 1.5) == 2
      assert Matcha.Spec.call!(spec, 1.6) == 2
      assert Matcha.Spec.call!(spec, :other) == :EXIT

      assert Matcha.Spec.run!(spec, [-0.6, -0.5, -0.4, 0.4, 0.5, 0.6, 1, 1.4, 1.5, 1.6, :other]) ==
               [-1, -1, 0, 0, 1, 1, 1, 1, 2, 2, :EXIT]
    end

    test "self/0" do
      spec =
        spec do
          x when self() == x -> true
        end

      assert Matcha.Spec.call!(spec, self()) == true
      assert Matcha.Spec.call!(spec, :other) == nil
      assert Matcha.Spec.run!(spec, [self(), :other]) == [true]

      spec =
        spec do
          x when x == 1 -> self()
        end

      assert Matcha.Spec.call!(spec, 1) == self()
      assert Matcha.Spec.call!(spec, :other) == nil
      assert Matcha.Spec.run!(spec, [1, :other]) == [self()]
    end

    test "tl/1" do
      spec =
        spec do
          x when tl([:one]) == [] -> x
        end

      assert Spec.call!(spec, :anything) == :anything
      assert Spec.run!(spec, [:anything, :at, :all]) == [:anything, :at, :all]

      spec =
        spec do
          x when tl(x) == [:two] -> x
        end

      assert Spec.call!(spec, {}) == nil
      assert Spec.call!(spec, []) == nil
      assert Spec.call!(spec, [:one]) == nil
      assert Spec.call!(spec, [:one, :two]) == [:one, :two]
      assert Spec.call!(spec, [:three, :four]) == nil
      assert Spec.run!(spec, [{}, [], [:one], [:one, :two], [:three, :four]]) == [[:one, :two]]

      spec =
        spec do
          _x -> tl([:one])
        end

      assert Spec.call!(spec, :anything) == []
      assert Spec.run!(spec, [:anything, :at, :all]) == [[], [], []]

      spec =
        spec do
          x -> tl(x)
        end

      assert Spec.call!(spec, {}) == :EXIT
      assert Spec.call!(spec, []) == :EXIT
      assert Spec.call!(spec, [:one]) == []
      assert Spec.call!(spec, [:one, :two]) == [:two]
      assert Spec.call!(spec, [:one, :two, :three]) == [:two, :three]

      assert Spec.run!(spec, [{}, [], [:one], [:one, :two], [:one, :two, :three]]) == [
               :EXIT,
               :EXIT,
               [],
               [:two],
               [:two, :three]
             ]
    end

    test "trunc/1" do
      spec =
        spec do
          x when trunc(x) == 0 -> x
        end

      assert Spec.call!(spec, -1.1) == nil
      assert Spec.call!(spec, -1.0) == nil
      assert Spec.call!(spec, -0.9) == -0.9
      assert Spec.call!(spec, -0.1) == -0.1
      assert Spec.call!(spec, 0) == 0
      assert Spec.call!(spec, 0.0) == 0.0
      assert Spec.call!(spec, 0.1) == 0.1
      assert Spec.call!(spec, 0.9) == 0.9
      assert Spec.call!(spec, 1) == nil
      assert Spec.call!(spec, 1.0) == nil
      assert Spec.call!(spec, 1.1) == nil
      assert Spec.call!(spec, :other) == nil

      assert Spec.run!(spec, [-1.1, -1.0, -0.9, -0.1, 0, 0.0, 0.1, 0.9, 1, 1.0, 1.1, :other]) == [
               -0.9,
               -0.1,
               0,
               0.0,
               0.1,
               0.9
             ]

      spec =
        spec do
          x -> trunc(x)
        end

      assert Spec.call!(spec, -1.1) == -1
      assert Spec.call!(spec, -1.0) == -1
      assert Spec.call!(spec, -0.9) == 0
      assert Spec.call!(spec, -0.1) == 0
      assert Spec.call!(spec, 0) == 0
      assert Spec.call!(spec, 0.0) == 0
      assert Spec.call!(spec, 0.1) == 0
      assert Spec.call!(spec, 0.9) == 0
      assert Spec.call!(spec, 1) == 1
      assert Spec.call!(spec, 1.0) == 1
      assert Spec.call!(spec, 1.1) == 1
      assert Spec.call!(spec, :other) == :EXIT

      assert Spec.run!(spec, [-1.1, -1.0, -0.9, -0.1, 0, 0.0, 0.1, 0.9, 1, 1.0, 1.1, :other]) == [
               -1,
               -1,
               0,
               0,
               0,
               0,
               0,
               0,
               1,
               1,
               1,
               :EXIT
             ]
    end

    if Matcha.Helpers.erlang_version() >= 26 do
      test "tuple_size/2" do
        spec =
          spec do
            x when tuple_size({:one}) == 1 -> x
          end

        assert Spec.call!(spec, :anything) == :anything
        assert Spec.run!(spec, [:anything, :at, :all]) == [:anything, :at, :all]

        spec =
          spec do
            x when tuple_size(x) == 1 -> x
          end

        assert Spec.call!(spec, {:one}) == {:one}
        assert Spec.call!(spec, {:one, :two}) == nil
        assert Spec.call!(spec, :not_a_tuple) == nil
        assert Spec.run!(spec, [{:one}, {:one, :two}, :not_a_tuple]) == [{:one}]

        spec =
          spec do
            _x -> tuple_size({:one})
          end

        assert Spec.call!(spec, :anything) == 1
        assert Spec.run!(spec, [:anything, :at, :all]) == [1, 1, 1]

        spec =
          spec do
            x -> tuple_size(x)
          end

        assert Spec.call!(spec, {:one}) == 1
        assert Spec.call!(spec, {:one, :two}) == 2
        assert Spec.call!(spec, :not_a_tuple) == :EXIT
        assert Spec.run!(spec, [{:one}, {:one, :two}, :not_a_tuple]) == [1, 2, :EXIT]
      end
    else
      test "tuple_size/1", test_context do
        assert_raise Matcha.Rewrite.Error, ~r|unsupported function call.*?tuple_size/1|s, fn ->
          defmodule test_module_name(test_context, "in guards") do
            import Matcha

            spec do
              tuple when tuple_size(tuple) == 2 -> tuple
            end
          end
        end

        assert_raise Matcha.Rewrite.Error, ~r|unsupported function call.*?tuple_size/1|s, fn ->
          defmodule test_module_name(test_context, "in bodies") do
            import Matcha

            spec do
              tuple -> tuple_size(tuple)
            end
          end
        end
      end
    end
  end

  describe "Record guards" do
    if Matcha.Helpers.erlang_version() >= 26 do
      test "is_record/1" do
        import Record, only: [is_record: 1]

        spec =
          spec do
            x when is_record({:record_tag}) -> x
          end

        assert Spec.call!(spec, :anything) == :anything
        assert Spec.run!(spec, [:anything, :at, :all]) == [:anything, :at, :all]

        spec =
          spec do
            x when is_record(1) -> x
          end

        assert Spec.call!(spec, :anything) == nil
        assert Spec.run!(spec, [:anything, :at, :all]) == []

        # FIXME: defguard expressions not correctly expanding in match spec bodies
        # spec =
        #   spec do
        #     _x -> is_record({:record_tag})
        #   end

        # assert Spec.call!(spec, :anything) == true
        # assert Spec.run!(spec, [:anything, :at, :all]) == [true, true, true]

        # spec =
        #   spec do
        #     x -> is_record(x)
        #   end

        # assert Spec.call!(spec, {:one}) == true
        # assert Spec.call!(spec, {1}) == false
        # assert Spec.call!(spec, :not_a_tuple) == false
        # assert Spec.run!(spec, [{:one}, {1}, :not_a_tuple]) == [true, false, false]
      end
    else
      test "is_record/1", test_context do
        assert_raise Matcha.Rewrite.Error, ~r|unsupported function call.*?tuple_size/1|s, fn ->
          defmodule test_module_name(test_context, "in guards") do
            import Matcha

            spec do
              tuple when tuple_size(tuple) == 2 -> tuple
            end
          end
        end

        assert_raise Matcha.Rewrite.Error, ~r|unsupported function call.*?tuple_size/1|s, fn ->
          defmodule test_module_name(test_context, "in bodies") do
            import Matcha

            spec do
              tuple -> tuple_size(tuple)
            end
          end
        end
      end
    end
  end

  describe "Bitwise guards" do
    test "band/2" do
      import Bitwise

      spec =
        spec do
          x when (1 &&& 1) == 1 -> x
        end

      assert Spec.call!(spec, :anything) == :anything
      assert Spec.run!(spec, [:anything, :at, :all]) == [:anything, :at, :all]

      spec =
        spec do
          x when (1 &&& 1) == 2 -> x
        end

      assert Spec.call!(spec, :anything) == nil
      assert Spec.run!(spec, [:anything, :at, :all]) == []

      spec =
        spec do
          _x -> 1 &&& 1
        end

      assert Spec.call!(spec, :anything) == 1
      assert Spec.run!(spec, [:anything, :at, :all]) == [1, 1, 1]

      spec =
        spec do
          x -> x &&& 1
        end

      assert Spec.call!(spec, -1) == 1
      assert Spec.call!(spec, 0) == 0
      assert Spec.call!(spec, 1) == 1
      assert Spec.call!(spec, 2) == 0
      assert Spec.run!(spec, [-1, 0, 1, 2]) == [1, 0, 1, 0]
    end

    test "bor/2" do
      import Bitwise

      spec =
        spec do
          x when (1 ||| 1) == 1 -> x
        end

      assert Spec.call!(spec, :anything) == :anything
      assert Spec.run!(spec, [:anything, :at, :all]) == [:anything, :at, :all]

      spec =
        spec do
          x when (1 ||| 1) == 2 -> x
        end

      assert Spec.call!(spec, :anything) == nil
      assert Spec.run!(spec, [:anything, :at, :all]) == []

      spec =
        spec do
          _x -> 1 ||| 1
        end

      assert Spec.call!(spec, :anything) == 1
      assert Spec.run!(spec, [:anything, :at, :all]) == [1, 1, 1]

      spec =
        spec do
          x -> x ||| 1
        end

      assert Spec.call!(spec, -1) == -1
      assert Spec.call!(spec, 0) == 1
      assert Spec.call!(spec, 1) == 1
      assert Spec.call!(spec, 2) == 3
      assert Spec.run!(spec, [-1, 0, 1, 2]) == [-1, 1, 1, 3]
    end

    test "bnot/1" do
      import Bitwise

      spec =
        spec do
          x when ~~~1 == -2 -> x
        end

      assert Spec.call!(spec, :anything) == :anything
      assert Spec.run!(spec, [:anything, :at, :all]) == [:anything, :at, :all]

      spec =
        spec do
          x when ~~~1 == 1 -> x
        end

      assert Spec.call!(spec, :anything) == nil
      assert Spec.run!(spec, [:anything, :at, :all]) == []

      spec =
        spec do
          _x -> ~~~1
        end

      assert Spec.call!(spec, :anything) == -2
      assert Spec.run!(spec, [:anything, :at, :all]) == [-2, -2, -2]

      spec =
        spec do
          x -> ~~~x
        end

      assert Spec.call!(spec, -1) == 0
      assert Spec.call!(spec, 0) == -1
      assert Spec.call!(spec, 1) == -2
      assert Spec.call!(spec, 2) == -3
      assert Spec.run!(spec, [-1, 0, 1, 2]) == [0, -1, -2, -3]
    end

    test "bsl/2" do
      import Bitwise

      spec =
        spec do
          x when 1 <<< 1 == 2 -> x
        end

      assert Spec.call!(spec, :anything) == :anything
      assert Spec.run!(spec, [:anything, :at, :all]) == [:anything, :at, :all]

      spec =
        spec do
          x when 1 <<< 1 == 1 -> x
        end

      assert Spec.call!(spec, :anything) == nil
      assert Spec.run!(spec, [:anything, :at, :all]) == []

      spec =
        spec do
          _x -> 1 <<< 1
        end

      assert Spec.call!(spec, :anything) == 2
      assert Spec.run!(spec, [:anything, :at, :all]) == [2, 2, 2]

      spec =
        spec do
          x -> x <<< 1
        end

      assert Spec.call!(spec, -1) == -2
      assert Spec.call!(spec, 0) == 0
      assert Spec.call!(spec, 1) == 2
      assert Spec.call!(spec, 2) == 4
      assert Spec.run!(spec, [-1, 0, 1, 2]) == [-2, 0, 2, 4]
    end

    test "bsr/2" do
      import Bitwise

      spec =
        spec do
          x when 1 >>> 1 == 0 -> x
        end

      assert Spec.call!(spec, :anything) == :anything
      assert Spec.run!(spec, [:anything, :at, :all]) == [:anything, :at, :all]

      spec =
        spec do
          x when 1 >>> 1 == 1 -> x
        end

      assert Spec.call!(spec, :anything) == nil
      assert Spec.run!(spec, [:anything, :at, :all]) == []

      spec =
        spec do
          _x -> 1 >>> 1
        end

      assert Spec.call!(spec, :anything) == 0
      assert Spec.run!(spec, [:anything, :at, :all]) == [0, 0, 0]

      spec =
        spec do
          x -> x >>> 1
        end

      assert Spec.call!(spec, -1) == -1
      assert Spec.call!(spec, 0) == 0
      assert Spec.call!(spec, 1) == 0
      assert Spec.call!(spec, 2) == 1
      assert Spec.run!(spec, [-1, 0, 1, 2]) == [-1, 0, 0, 1]
    end

    test "bxor/2" do
      import Bitwise

      spec =
        spec do
          x when bxor(1, 1) == 0 -> x
        end

      assert Spec.call!(spec, :anything) == :anything
      assert Spec.run!(spec, [:anything, :at, :all]) == [:anything, :at, :all]

      spec =
        spec do
          x when bxor(1, 1) == 1 -> x
        end

      assert Spec.call!(spec, :anything) == nil
      assert Spec.run!(spec, [:anything, :at, :all]) == []

      spec =
        spec do
          _x -> bxor(1, 1)
        end

      assert Spec.call!(spec, :anything) == 0
      assert Spec.run!(spec, [:anything, :at, :all]) == [0, 0, 0]

      spec =
        spec do
          x -> bxor(x, 1)
        end

      assert Spec.call!(spec, -1) == -2
      assert Spec.call!(spec, 0) == 1
      assert Spec.call!(spec, 1) == 0
      assert Spec.call!(spec, 2) == 3
      assert Spec.run!(spec, [-1, 0, 1, 2]) == [-2, 1, 0, 3]
    end
  end
end
