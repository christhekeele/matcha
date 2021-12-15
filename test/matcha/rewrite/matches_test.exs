defmodule Matcha.Rewrite.Matches.Test do
  @moduledoc false

  use ExUnit.Case, async: true

  import TestHelpers

  require Matcha

  describe "cons operator (`|`)" do
    test "in matches at the top-level of a list" do
      expected_source = [{[:"$1" | :"$2"], [], [{{:"$1", :"$2"}}]}]

      spec =
        Matcha.spec do
          [head | tail] -> {head, tail}
        end

      assert spec.source == expected_source

      assert Matcha.Spec.run(spec, [:head, :tail]) ==
               {:ok, {:returned, {:head, [:tail]}}}

      assert Matcha.Spec.run(spec, [:head | :improper]) ==
               {:ok, {:returned, {:head, :improper}}}
    end

    test "in matches at the end of a list" do
      expected_source = [{[:"$1", :"$2" | :"$3"], [], [{{:"$1", :"$2", :"$3"}}]}]

      spec =
        Matcha.spec do
          [first, second | tail] -> {first, second, tail}
        end

      assert spec.source == expected_source

      assert Matcha.Spec.run(spec, [:first, :second, :tail]) ==
               {:ok, {:returned, {:first, :second, [:tail]}}}

      assert Matcha.Spec.run(spec, [:first, :second | :improper]) ==
               {:ok, {:returned, {:first, :second, :improper}}}
    end

    test "in matches with bad usage in middle of list", context do
      assert_raise CompileError, ~r"misplaced operator |/2", fn ->
        defmodule test_module_name(context) do
          Matcha.spec do
            [first, second | third, fourth] -> {first, second, third, fourth}
          end
        end
      end
    end

    test "in matches with bad usage twice in list", context do
      assert_raise CompileError, ~r"misplaced operator |/2", fn ->
        defmodule test_module_name(context) do
          Matcha.spec do
            [first, second | third, fourth | fifth] -> {first, second, third, fourth, fifth}
          end
        end
      end
    end
  end

  test "char literals in matches" do
    expected_source = [{{[53, 53, 53, 45 | :"$1"], :"$2"}, [], [{{:"$1", :"$2"}}]}]

    spec =
      Matcha.spec do
        {[?5, ?5, ?5, ?- | rest], name} -> {rest, name}
      end

    assert spec.source == expected_source

    assert Matcha.Spec.run(spec, {'555-1234', 'John Smith'}) ==
             {:ok, {:returned, {'1234', 'John Smith'}}}
  end

  test "char lists in matches" do
    expected_source = [{{{[53, 53, 53], :"$1"}, :"$2"}, [], [{{:"$1", :"$2"}}]}]

    spec =
      Matcha.spec do
        {{'555', rest}, name} -> {rest, name}
      end

    assert spec.source == expected_source

    assert Matcha.Spec.run(spec, {{'555', '1234'}, 'John Smith'}) ==
             {:ok, {:returned, {'1234', 'John Smith'}}}
  end

  describe "map literals in matches" do
    test "work as entire match head" do
      spec =
        Matcha.spec do
          %{x: z} -> z
        end

      assert spec.source == [{%{x: :"$1"}, [], [:"$1"]}]

      assert {:ok, {:returned, 2}} == Matcha.Spec.run(spec, %{x: 2})
    end

    test "work inside matches" do
      spec =
        Matcha.spec do
          {x, %{a: z, c: y}} -> {x, y, z}
        end

      assert spec.source == [{{:"$1", %{a: :"$2", c: :"$3"}}, [], [{{:"$1", :"$3", :"$2"}}]}]

      assert {:ok, {:returned, {1, 2, 3}}} == Matcha.Spec.run(spec, {1, %{a: 3, c: 2}})
    end
  end

  describe "matching (`=`)" do
    test "matching on a previously defined variable" do
      spec =
        Matcha.spec do
          {x, y = x} -> {x, y}
        end

      assert spec.source == [{{:"$1", :"$1"}, [], [{{:"$1", :"$1"}}]}]

      spec =
        Matcha.spec do
          {x, x = y} -> {x, y}
        end

      assert spec.source == [{{:"$1", :"$1"}, [], [{{:"$1", :"$1"}}]}]
    end

    test "matching two previously defined variables" do
      spec =
        Matcha.spec do
          {x, y, y = x} -> {x, y}
        end

      assert spec.source == [{{:"$2", :"$2", :"$2"}, [], [{{:"$2", :"$2"}}]}]
    end

    test "matching on a new variable" do
      spec =
        Matcha.spec do
          {x, y = z} -> {x, y, z}
        end

      assert spec.source == [{{:"$1", :"$2"}, [], [{{:"$1", :"$2", :"$2"}}]}]
    end

    test "matching on an externally defined variable" do
      z = 128

      spec =
        Matcha.spec do
          {x, y = z} -> {x, y, z}
        end

      assert spec.source == [{{:"$1", 128}, [], [{{:"$1", {:const, 128}, {:const, 128}}}]}]
    end

    # There is an attempt to allow limited literal matching in match heads, here:
    # https://github.com/christhekeele/matcha/tree/experiment-with-literals

    test "matching on a new variable to a literal value", context do
      assert_raise Matcha.Rewrite.Error,
                   ~r/cannot match `y` to `128`: cannot use the match operator in match spec heads/,
                   fn ->
                     defmodule test_module_name(context, "variable first") do
                       spec =
                         Matcha.spec do
                           {x, y = 128} -> {x, y}
                         end
                     end
                   end

      assert_raise Matcha.Rewrite.Error,
                   ~r/cannot match `128` to `y`: cannot use the match operator in match spec heads/,
                   fn ->
                     defmodule test_module_name(context, "variable second") do
                       spec =
                         Matcha.spec do
                           {x, 128 = y} -> {x, y}
                         end
                     end
                   end
    end

    test "matching on an internally matched variable to a literal value", context do
      assert_raise Matcha.Rewrite.Error,
                   ~r/cannot match `y` to `128`: cannot use the match operator in match spec heads/,
                   fn ->
                     defmodule test_module_name(context, "variable first") do
                       spec =
                         Matcha.spec do
                           {x, y = 128, y = z} -> {x, y, z}
                         end
                     end
                   end

      assert_raise Matcha.Rewrite.Error,
                   ~r/cannot match `128` to `y`: cannot use the match operator in match spec heads/,
                   fn ->
                     defmodule test_module_name(context, "variable second") do
                       spec =
                         Matcha.spec do
                           {x, 128 = y, z = y} -> {x, y, z}
                         end
                     end
                   end
    end

    test "matching on a matching external variable to a literal value", context do
      assert_raise Matcha.Rewrite.Error,
                   ~r/cannot match `y` to `128`: cannot use the match operator in match spec heads/,
                   fn ->
                     defmodule test_module_name(context, "variable first") do
                       y = 128

                       spec =
                         Matcha.spec do
                           {x, y = 128} -> {x, y}
                         end
                     end
                   end

      assert_raise Matcha.Rewrite.Error,
                   ~r/cannot match `128` to `y`: cannot use the match operator in match spec heads/,
                   fn ->
                     defmodule test_module_name(context, "variable second") do
                       y = 128

                       spec =
                         Matcha.spec do
                           {x, 128 = y} -> {x, y}
                         end
                     end
                   end

      assert_raise Matcha.Rewrite.Error,
                   ~r/cannot match `y` to `128`: cannot use the match operator in match spec heads/,
                   fn ->
                     defmodule test_module_name(context, "variable first, used later") do
                       y = 128

                       spec =
                         Matcha.spec do
                           {x, y = 128, y = z} -> {x, y, z}
                         end
                     end
                   end

      assert_raise Matcha.Rewrite.Error,
                   ~r/cannot match `128` to `y`: cannot use the match operator in match spec heads/,
                   fn ->
                     defmodule test_module_name(context, "variable second, used later") do
                       y = 128

                       spec =
                         Matcha.spec do
                           {x, 128 = y, z = y} -> {x, y, z}
                         end
                     end
                   end
    end

    test "matching and shadowing an external variable with a literal value", context do
      assert_raise Matcha.Rewrite.Error,
                   ~r/cannot match `y` to `128`: cannot use the match operator in match spec heads/,
                   fn ->
                     defmodule test_module_name(context, "variable first") do
                       y = 129

                       spec =
                         Matcha.spec do
                           {x, y = 128} -> {x, y}
                         end
                     end
                   end

      assert_raise Matcha.Rewrite.Error,
                   ~r/cannot match `128` to `y`: cannot use the match operator in match spec heads/,
                   fn ->
                     defmodule test_module_name(context, "variable second") do
                       y = 129

                       spec =
                         Matcha.spec do
                           {x, 128 = y} -> {x, y}
                         end
                     end
                   end

      assert_raise Matcha.Rewrite.Error,
                   ~r/cannot match `y` to `128`: cannot use the match operator in match spec heads/,
                   fn ->
                     defmodule test_module_name(context, "variable first, re-used later") do
                       y = 129

                       spec =
                         Matcha.spec do
                           {x, y = 128, y} -> {x, y}
                         end
                     end
                   end

      assert_raise Matcha.Rewrite.Error,
                   ~r/cannot match `128` to `y`: cannot use the match operator in match spec heads/,
                   fn ->
                     defmodule test_module_name(context, "variable second, re-used later") do
                       y = 129

                       spec =
                         Matcha.spec do
                           {x, 128 = y, y} -> {x, y}
                         end
                     end
                   end

      assert_raise Matcha.Rewrite.Error,
                   ~r/cannot match `y` to `128`: cannot use the match operator in match spec heads/,
                   fn ->
                     defmodule test_module_name(context, "variable first, re-bound later") do
                       y = 129

                       spec =
                         Matcha.spec do
                           {x, y = 128, y = z} -> {x, y, z}
                         end
                     end
                   end

      assert_raise Matcha.Rewrite.Error,
                   ~r/cannot match `128` to `y`: cannot use the match operator in match spec heads/,
                   fn ->
                     defmodule test_module_name(context, "variable second, re-bound later") do
                       y = 129

                       spec =
                         Matcha.spec do
                           {x, 128 = y, z = y} -> {x, y, z}
                         end
                     end
                   end
    end
  end
end
