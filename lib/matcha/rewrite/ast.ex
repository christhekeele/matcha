defmodule Matcha.Rewrite.AST do
  defguard is_var(var)
           when is_tuple(var) and is_atom(elem(var, 0)) and is_list(elem(var, 1)) and
                  is_atom(elem(var, 2))

  defguard is_named_var(var)
           when is_var(var) and elem(var, 0) != :_

  defguard is_call(call)
           when (is_atom(elem(call, 0)) or is_tuple(elem(call, 0))) and is_list(elem(call, 1)) and
                  is_list(elem(call, 2))

  defguard is_invocation(invocation)
           when is_call(invocation) and elem(invocation, 0) == :. and is_list(elem(invocation, 1)) and
                  length(elem(invocation, 2)) == 2 and
                  is_atom(hd(elem(invocation, 2))) and is_atom(hd(tl(elem(invocation, 2))))

  defguard is_remote_call(call)
           when is_invocation(elem(call, 0)) and is_list(elem(call, 1)) and
                  is_list(elem(call, 2))

  defguard is_literal(ast)
           when is_atom(ast) or is_integer(ast) or is_float(ast) or is_binary(ast)

  defguard is_non_literal(ast)
           when is_list(ast) or
                  (is_tuple(ast) and tuple_size(ast) == 2) or is_call(ast) or is_var(ast)
end
