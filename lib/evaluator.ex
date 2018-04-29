defmodule Dwarf.Evaluator do
  alias Dwarf.Env

  @moduledoc """
  	The evaluator look at the IR respresented as a list of ASTs and evaluate each of them in order.
  	The evaluator expect that the IR has been typed checked staticly before hand.
  """

  # Loop through each tree and evaluates them by giving them previous environment
  def eval(trees, env) do
    # time_before = Time.utc_now()

    List.foldl(trees, env, fn tree, prev_env ->
      {_, new_env} = eval_stmt(tree, prev_env)
      new_env
    end)

    # time_after = Time.utc_now()
    # IO.puts("end of eval : " <> to_string(Time.diff(time_before, time_after)) <> "s.")
  end

  defp eval_stmt(tree, env) do
    case tree do
      {:fun, line, args} ->
        {{:string, line, [List.first(args)]}, Env.add(env, tree)}

      {:dec, line, args} ->
        [type, name, expr] = args
        new_expr = eval_exp(expr, env)
        {new_expr, Env.add(env, {:dec, line, [type, name, new_expr]})}

      {:if, _, _} ->
        eval_if(tree, env)

      {:assign, line, args} ->
        [name, exp] = args
        new_expr = eval_exp(exp, env)
        new_env = Env.update(env, {:assign, line, [name, new_expr]})
        {new_expr, new_env}

      {:while,_,args} -> 
        {new_expr,new_env} = eval_while(args,env)
        {new_expr,remove_local_vars(env,new_env)}

      {:print, _, [expr]} ->
        new_expr = eval_exp(expr, env)
        IO.puts(new_expr)
        {new_expr, env}

      x when is_list(x) ->
        List.foldl(x, {nil,env}, fn tree, {_,prev_env} ->
          {exp, new_tree} = eval_stmt(tree, prev_env)
          {exp, new_tree}
        end)

      x ->
        {eval_exp(x, env), env}
    end
  end

  defp eval_while([expr,stmt],env) do
    expr2 = eval_exp(expr,env)
    case expr2 do
      false -> 
        {expr2,new_env} = eval_stmt(stmt,env)
        {expr2,remove_local_vars(env,new_env)}
      _ ->
        {_,new_env} = eval_stmt(stmt,env)   
        eval_while([expr,stmt],remove_local_vars(env,new_env))
    end
  end

  defp eval_exp(tree, env) do
    case tree do
      {:uop, _, [exp]} ->
        !eval_exp(exp, env)

      {:op, _, _} ->
        eval_op(tree, env)

      {:num, _, args} ->
        List.first(args)

      {:string, _, args} ->
        List.first(args)

      {:bool, _, args} ->
        List.first(args)

      {:var, line, args} ->
        {result, value} = Env.get(env, List.first(args))

        if !result do
          raise "Dynamic error : var #{List.first(args)} has not been declared on line #{line}"
        end

        value

      {:call, _, _} ->
        eval_fun(tree, env)
    end
  end

  defp eval_op(tree, env) do
    case tree do
      {:op, _, [:add, exp1, exp2]} -> eval_exp(exp1, env) + eval_exp(exp2, env)
      {:op, _, [:sub, exp1, exp2]} -> eval_exp(exp1, env) - eval_exp(exp2, env)
      {:op, _, [:div, exp1, exp2]} -> eval_exp(exp1, env) / eval_exp(exp2, env)
      {:op, _, [:mul, exp1, exp2]} -> eval_exp(exp1, env) * eval_exp(exp2, env)
      {:op, _, [:mod, exp1, exp2]} -> rem(eval_exp(exp1, env), eval_exp(exp2, env))
      {:op, _, [:ge, exp1, exp2]} -> eval_exp(exp1, env) >= eval_exp(exp2, env)
      {:op, _, [:gt, exp1, exp2]} -> eval_exp(exp1, env) > eval_exp(exp2, env)
      {:op, _, [:se, exp1, exp2]} -> eval_exp(exp1, env) <= eval_exp(exp2, env)
      {:op, _, [:st, exp1, exp2]} -> eval_exp(exp1, env) < eval_exp(exp2, env)
      {:op, _, [:equality, exp1, exp2]} -> eval_exp(exp1, env) == eval_exp(exp2, env)
      {:op, _, [:concat, exp1, exp2]} -> eval_exp(exp1, env) <> eval_exp(exp2, env)
    end
  end

  defp eval_fun({:call, line, [name, args]}, env) do
    {valid, fun_spec} = Env.get(env, name)

    if !valid do
      raise "Dynamic error : Could not find a function with name #{name} on line : #{line}"
    end

    {:fun, _, [name, params, stmt]} = fun_spec

    if length(args) != length(params) do
      raise "Dynamic error : Trying to invoque function #{name} with #{length(args)} arguments while #{
              name
            } expects #{length(params)} on line : #{line}"
    end

    {_, new_env, _} =
      List.foldl(params, {0, env, args}, fn param, {pos, old_env, old_args} ->
        # get and remove the arg from the list
        {{_type, _, [val]}, rest} = List.pop_at(old_args, 0)
        {pos + 1, Env.addArg(old_env, param, val), rest}
      end)

    {return_value, _} = eval_stmt(stmt, new_env)
    return_value
  end

  defp eval_fun({a, line, _}, _),
    do: raise("Dynamic error: Expected a call received #{to_string(a)} on line #{line}")

  defp eval_if({:if, _, [expr, stmt1, stmt2]}, env) do
    exp = eval_exp(expr, env)
    if(exp) do
      {new_expr, new_env} = eval_stmt(stmt1, env)
      
      # return the last expression done in the stmt and the env with the local var stripped
      {new_expr, remove_local_vars(env,new_env)}
    else
      {new_expr, new_env} = eval_stmt(stmt2, env)

      # return the last expression done in the stmt and the env with the local var stripped
      {new_expr, remove_local_vars(env,new_env)}
    end
  end

  defp eval_if(_, _), do: raise("Dynamic error : Expected an if statement")
  
  # Remove the addional variables that appears in new_env and not in old_env 
  defp remove_local_vars(old_env,new_env) do
    Enum.reduce(old_env,[],
      fn old_var, acc -> 

        {old_name,_} = old_var

        new_var = Enum.find(new_env, 
          fn new_var -> 
            {new_name,_} = new_var
            old_name == new_name
            end)

      if new_var != nil do
        [new_var|acc]
      else
        [old_var|acc]
      end
        end)
  end
end
