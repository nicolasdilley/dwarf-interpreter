defmodule Dwarf.Env do
  @moduledoc """
  	The environment is a list of all the declared variables and functions and their value.

  	vars contained in the env have the form
  		{name,{:fun,_,[args,stmt]}}
  		{name,{:num,line,[value]}}
  		{name,{:bool,line,[value]}}
  		{name,{:string,line,[value]}}
  """

  def add(env, {:fun, line, [name, args, stmt]}) do
    {updated, newEnv} = updateVal(env, {name, {:fun, line, [name, args, stmt]}})

    if !updated do
      [{name, {:fun, line, [name, args, stmt]}} | newEnv]
    else
      newEnv
    end
  end

  def add(env, {:dec, line, [type, name, val]}) do
    {updated, newEnv} = updateVal(env, {name, {type, line, [name, val]}})

    if !updated do
      [{name, {type, line, [name, val]}} | newEnv]
    else
      raise "Dynamic error: var #{name} was already declared can not declare twice the same variable. on line #{
              line
            }"
    end
  end

  # update the value of varName in the environment
  # if varName does not exists raise an error
  def update(env, {:assign, line, [varName, val]}) do
    {updated, new_env} =
      List.foldl(env, {false, []}, fn var, {updated, newEnv} ->
        case var do
          {a, {type, _, [_, _]}} when varName == a ->
            {true, [{varName, {type, line, [varName, val]}} | newEnv]}

          x ->
            {updated, [x | newEnv]}
        end
      end)

    if !updated do
      raise "Dynamic error: Trying to assign to var #{varName} but it has not been declared yet."
    end

    new_env
  end

  def addArg(env, {:param, line, [type, name]}, val) do
    {updated, newEnv} = updateVal(env, {name, {type, line, [name, val]}})

    if !updated do
      [{name, {type, line, [name, val]}} | env]
    else
      newEnv
    end
  end

  def get(env, varName) do
    var =
      Enum.find(env, fn x ->
        case x do
          {name, _} -> varName == name
        end
      end)

    case var do
      nil ->
        {false, {}}

      # returning the value of a var
      {_, {_, _, [_name, value]}} ->
        {true, value}

      # returning the function
      {_, a} ->
        {true, a}
    end
  end

  # Update the value if it is contained in the env and return a tuple with the first value 
  # Telling if the env has been updated or not and the changed or unchanged env
  defp updateVal([], _), do: {false, []}

  defp updateVal(env, {name, {type, line, [name, val]}}) do
    List.foldl(env, {false, []}, fn var, {updated, newEnv} ->
      case var do
        {a, _} when name == a ->
          {true, [{name, {type, line, [name, val]}} | newEnv]}

        x ->
          {updated, [x | newEnv]}
      end
    end)
  end

  defp updateVal(env, {name, {type, line, [name, args, stmt]}}) do
    List.foldl(env, {false, []}, fn var, {updated, newEnv} ->
      case var do
        {_, a, _, _} when name == a ->
          {true, [{name, {type, line, [name, args, stmt]}} | newEnv]}

        x ->
          {updated, [x | newEnv]}
      end
    end)
  end
end
