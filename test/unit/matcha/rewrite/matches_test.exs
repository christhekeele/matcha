defmodule Matcha.Rewrite.Matches.UnitTest do
  @moduledoc false

  use UnitTest

  import TestHelpers

  import Matcha

  alias Matcha.Spec

  describe "pin operator (`^`) in matches" do
    test "at top-level" do
      expected_source = [{{:"$1", 128}, [], [{{:"$1", {:const, 128}}}]}]
      y = 128

      spec =
        spec do
          {x, ^y} -> {x, y}
        end

      assert Spec.raw(spec) == expected_source
    end

    test "in nested bindings" do
      expected_source = [
        {{:"$1", :"$2"},
         [
           {:andalso, {:andalso, {:is_map, :"$2"}, {:is_map_key, :y, :"$2"}},
            {:==, 128, {:map_get, :y, :"$2"}}}
         ], [{{:"$1", :"$2", {:const, 128}}}]}
      ]

      y = 128

      spec =
        spec do
          {x, map = %{y: ^y}} -> {x, map, y}
        end

      assert Spec.raw(spec) == expected_source
    end
  end

  describe "cons operator (`|`) in matches" do
    test "at the top-level of a list" do
      expected_source = [{[:"$1" | :"$2"], [], [{{:"$1", :"$2"}}]}]

      spec =
        spec do
          [head | tail] -> {head, tail}
        end

      assert Spec.raw(spec) == expected_source
    end

    test "at the end of a list" do
      expected_source = [{[:"$1", :"$2" | :"$3"], [], [{{:"$1", :"$2", :"$3"}}]}]

      spec =
        spec do
          [first, second | tail] -> {first, second, tail}
        end

      assert Spec.raw(spec) == expected_source
    end

    test "with bad usage in middle of list", context do
      assert_raise CompileError, fn ->
        defmodule test_module_name(context) do
          import Matcha

          spec do
            [first, second | third, fourth] -> {first, second, third, fourth}
          end
        end
      end
    end

    test "with bad usage twice in list", context do
      assert_raise CompileError, fn ->
        defmodule test_module_name(context) do
          import Matcha

          spec do
            [first, second | third, fourth | fifth] -> {first, second, third, fourth, fifth}
          end
        end
      end
    end
  end

  test "char literals in matches" do
    expected_source = [{{[53, 53, 53, 45 | :"$1"], :"$2"}, [], [{{:"$1", :"$2"}}]}]

    spec =
      spec do
        {[?5, ?5, ?5, ?- | rest], name} -> {rest, name}
      end

    assert Spec.raw(spec) == expected_source
  end

  test "char lists in matches" do
    expected_source = [{{{[53, 53, 53], :"$1"}, :"$2"}, [], [{{:"$1", :"$2"}}]}]

    spec =
      spec do
        {{~c"555", rest}, name} -> {rest, name}
      end

    assert Spec.raw(spec) == expected_source
  end

  describe "map literals in matches:" do
    test "map in head tuple" do
      expected_source = [{{:"$1", %{a: :"$2", c: :"$3"}}, [], [{{:"$1", :"$2", :"$3"}}]}]

      spec =
        spec do
          {x, %{a: y, c: z}} -> {x, y, z}
        end

      assert Spec.raw(spec) == expected_source
    end

    test "work as entire match heads" do
      expected_source = [{%{x: :"$1"}, [], [:"$1"]}]

      spec =
        spec do
          %{x: z} -> z
        end

      assert Spec.raw(spec) == expected_source
    end

    test "work nested in match heads" do
      expected_source = [{{:"$1", %{a: :"$2", c: :"$3"}}, [], [{{:"$1", :"$3", :"$2"}}]}]

      spec =
        spec do
          {x, %{a: z, c: y}} -> {x, y, z}
        end

      assert Spec.raw(spec) == expected_source
    end
  end

  describe "tuples in matches:" do
    test "of length 0" do
      spec =
        spec do
          {} -> {}
        end

      assert Spec.raw(spec) == [{{}, [], [{{}}]}]
    end

    test "of length 1" do
      spec =
        spec do
          {x} -> {x}
        end

      assert Spec.raw(spec) == [{{:"$1"}, [], [{{:"$1"}}]}]
    end

    test "of length 2" do
      spec =
        spec do
          {x, y} -> {x, y}
        end

      assert Spec.raw(spec) == [{{:"$1", :"$2"}, [], [{{:"$1", :"$2"}}]}]
    end

    test "of length 3" do
      spec =
        spec do
          {x, y, z} -> {x, y, z}
        end

      assert Spec.raw(spec) == [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}]
    end
  end

  describe "matching (`=`):" do
    test "on a previously defined variable" do
      expected_source = [{{:"$1", :"$1"}, [], [{{:"$1", :"$1"}}]}]

      spec =
        spec do
          {x, y = x} -> {x, y}
        end

      assert Spec.raw(spec) == expected_source

      spec =
        spec do
          {x, x = y} -> {x, y}
        end

      assert Spec.raw(spec) == expected_source
    end

    test "on two previously defined variables" do
      expected_source = [{{:"$2", :"$2", :"$2"}, [], [{{:"$2", :"$2"}}]}]

      spec =
        spec do
          {x, y, y = x} -> {x, y}
        end

      assert Spec.raw(spec) == expected_source
    end

    test "on a new variable" do
      expected_source = [{{:"$1", :"$2"}, [], [{{:"$1", :"$2", :"$2"}}]}]

      spec =
        spec do
          {x, y = z} -> {x, y, z}
        end

      assert Spec.raw(spec) == expected_source
    end

    test "on an externally defined variable" do
      z = 128
      expected_source = [{{:"$1", 128}, [], [{{:"$1", {:const, 128}, {:const, 128}}}]}]

      spec =
        spec do
          {x, y = z} -> {x, y, z}
        end

      assert Spec.raw(spec) == expected_source
    end

    test "on a new variable to a literal value" do
      expected_source = [{{:"$1", :"$2"}, [{:==, :"$2", {:const, 128}}], [{{:"$1", :"$2"}}]}]

      spec =
        spec do
          {x, y = 128} -> {x, y}
        end

      assert Spec.raw(spec) == expected_source
    end

    test "on an internally matched variable to a literal value" do
      expected_source = [
        {{:"$1", :"$2", :"$2"}, [{:==, :"$2", {:const, 128}}], [{{:"$1", :"$2", :"$2"}}]}
      ]

      spec =
        spec do
          {x, y = 128, y = z} -> {x, y, z}
        end

      assert Spec.raw(spec) == expected_source

      expected_source = [
        {{:"$1", :"$2", :"$2"}, [{:==, :"$2", {:const, 128}}], [{{:"$1", :"$2", :"$2"}}]}
      ]

      spec =
        spec do
          {x, 128 = y, z = y} -> {x, y, z}
        end

      assert Spec.raw(spec) == expected_source
    end

    test "shadowing an external variable with a literal value", context do
      assert_raise Matcha.Rewrite.Error,
                   ~r/cannot match `y` to `128`: `y` is already bound outside of the match spec/,
                   fn ->
                     defmodule test_module_name(context, "variable first") do
                       import Matcha
                       y = 129

                       spec =
                         spec do
                           {x, y = 128} -> {x, y}
                         end
                     end
                   end

      assert_raise Matcha.Rewrite.Error,
                   ~r/cannot match `y` to `128`: `y` is already bound outside of the match spec/,
                   fn ->
                     defmodule test_module_name(context, "variable second") do
                       import Matcha
                       y = 129

                       spec =
                         spec do
                           {x, 128 = y} -> {x, y}
                         end
                     end
                   end

      assert_raise Matcha.Rewrite.Error,
                   ~r/cannot match `y` to `128`: `y` is already bound outside of the match spec/,
                   fn ->
                     defmodule test_module_name(context, "variable first, re-used later") do
                       import Matcha
                       y = 129

                       spec =
                         spec do
                           {x, y = 128, y} -> {x, y}
                         end
                     end
                   end

      assert_raise Matcha.Rewrite.Error,
                   ~r/cannot match `y` to `128`: `y` is already bound outside of the match spec/,
                   fn ->
                     defmodule test_module_name(context, "variable second, re-used later") do
                       import Matcha
                       y = 129

                       spec =
                         spec do
                           {x, 128 = y, y} -> {x, y}
                         end
                     end
                   end

      assert_raise Matcha.Rewrite.Error,
                   ~r/cannot match `y` to `128`: `y` is already bound outside of the match spec/,
                   fn ->
                     defmodule test_module_name(context, "variable first, re-bound later") do
                       import Matcha
                       y = 129

                       spec =
                         spec do
                           {x, y = 128, y = z} -> {x, y, z}
                         end
                     end
                   end

      assert_raise Matcha.Rewrite.Error,
                   ~r/cannot match `y` to `128`: `y` is already bound outside of the match spec/,
                   fn ->
                     defmodule test_module_name(context, "variable second, re-bound later") do
                       import Matcha
                       y = 129

                       spec =
                         spec do
                           {x, 128 = y, z = y} -> {x, y, z}
                         end
                     end
                   end

      assert_raise Matcha.Rewrite.Error,
                   ~r/cannot match `y` to `128`: `y` is already bound outside of the match spec/,
                   fn ->
                     defmodule test_module_name(
                                 context,
                                 "on a literal value to an externally defined variable"
                               ) do
                       import Matcha
                       y = 128

                       expected_source = [
                         {{:"$1", :"$2"}, [{:==, :"$2", {:const, 128}}], [{{:"$1", :"$2"}}]}
                       ]

                       spec =
                         spec do
                           {x, 128 = y} -> {x, y}
                         end

                       assert Spec.raw(spec) == expected_source
                     end
                   end

      assert_raise Matcha.Rewrite.Error,
                   ~r/cannot match `y` to `128`: `y` is already bound outside of the match spec/,
                   fn ->
                     defmodule test_module_name(
                                 context,
                                 "on an externally defined variable to a literal value, rematching later"
                               ) do
                       import Matcha
                       y = 128

                       expected_source = [
                         {{:"$1", :"$2"}, [{:==, :"$2", {:const, 128}}], [{{:"$1", :"$2"}}]}
                       ]

                       spec =
                         spec do
                           {x, y = 128, y = z} -> {x, y, z}
                         end

                       assert Spec.raw(spec) == expected_source
                     end
                   end

      assert_raise Matcha.Rewrite.Error,
                   ~r/cannot match `y` to `128`: `y` is already bound outside of the match spec/,
                   fn ->
                     defmodule test_module_name(
                                 context,
                                 "on a literal value to an externally defined variable, rematching later"
                               ) do
                       import Matcha
                       y = 128

                       expected_source = [
                         {{:"$1", :"$2"}, [{:==, :"$2", {:const, 128}}], [{{:"$1", :"$2"}}]}
                       ]

                       spec =
                         spec do
                           {x, 128 = y, z = y} -> {x, y, z}
                         end

                       assert Spec.raw(spec) == expected_source
                     end
                   end
    end
  end
end
