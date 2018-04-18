defmodule Dwarf.Env do
	@moduledoc """
		The environment is a list of all the declared variables and functions and their value.

		vars contained in the env have the form
			{:fun,name,args,stmt}
			{:num,name,value}
			{:bool,name,value}
			{:string,name,value}
	"""

	def add(env,{:fun,name,args,val}) do
		{updated,newEnv} = updateVal(env,{:fun,name,args,val})
		if !updated do
			[{:fun,name,args,val}|newEnv]
		else
			newEnv
		end
	end


	def add(env,{:dec,{:type,type},name,val}) do
		{updated,newEnv} = updateVal(env,{type,name,val})
		if !updated do
			[{type,name,val}|newEnv]
		else
			raise "Dynamic error: var #{name} was already declared can not declare twice the same variable."
		end
	end

	def addArg(env,{:param,type,name},val) do
		{updated,newEnv} = updateVal(env,{type,name,val})
		if !updated do
			[{type,name,val}|env]
		else
			newEnv
		end
	end

	def get(env,varName) do
	  var = Enum.find(env, fn(x) -> 
		  case x do
		    {_,name,_,_} -> varName == name
		    {_,name,_} -> varName== name
		  end	
		end)
	  case var do
		{_,_,value} -> {true,value}
	  	a -> {true,a}
	  end
	end

	# Update the value if it is contained in the env and return a tuple with the first value 
	# Telling if the env has been updated or not and the changed or unchanged env
	defp updateVal([],_), do: {false,[]}
	defp updateVal(env,{type,name,val}) do
		List.foldl(env,{false,[]},fn var, {updated,newEnv} -> 
			case var do
				{_,a,_} when name == a-> 
				  {true,[{type,name,val}|newEnv]}
				x -> {updated,[x|newEnv]}
			end
		end)
	end
	defp updateVal(env,{type,name,args,stmt}) do
		List.foldl(env,{false,[]},fn var, {updated,newEnv} -> 
			case var do
				{_,a,_,_} when name == a -> 
				  {true,[{type,a,args,stmt}|newEnv]}
				x -> {updated,[x|newEnv]}
			end
		end)
	end
end