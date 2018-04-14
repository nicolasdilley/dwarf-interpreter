defmodule Dwarf.Parser do
	alias Dwarf.Lexer
	@moduledoc """
		The parser takes a list of tokens and genarates an AST trees from it.
		This AST tree will be further optimized by the optimizer.

		type of stmt =
			{:assign,type,nameOfVar, expr} -> type nameOfVar := expr
			{:print,expr} -> print nameOfVar
		type of expr = 
			{:op,operator,expr,expr2} = expr op expr2
			{:uop,!,expr} = !expr
			{:ident,nameOfVar} = nameOfVar 


	"""

	@doc """
		Parses a list of tokens into an AST tree
	""" 


	@spec parse(list) :: list
	def parse ([token|rest]) do
		case token do 
			{{:int},_} -> {node,toParse} = parse_var_dec([token|rest]) # parse the var declaration and continue with the rest
						  	  [node | parse(toParse)]
			{{:bool},_} -> {node,toParse} = parse_var_dec([token|rest]) 
						  	  [node | parse(toParse)]
			{{:fun},_} -> {node,toParse} = parse_fun_dec([token|rest]) 
							  [node|parse(toParse)]
			{{:if},_} -> {node,toParse} = parse_if_stmt([token|rest])
							  [node|parse(toParse)]
			{{:print},_} -> {node,toParse} = parse_print([token|rest]) # print statement
						  	  [node | parse(toParse)]
			{{a,_},line} -> raise "Parsing error : unexpected #{to_string(a)} on line : #{line}"
			{{a},line} -> raise "Parsing error : unexpected #{to_string(a)} on line : #{line}"
			
		end	
			
	end

	def parse([]) do
		[]
	end

	@spec parse_exp(Lexer.str_token) :: {tuple,list}
	def parse_exp([token|rest]) do
	end

	@spec parse_var_dec(list) :: {tuple,list}
	def parse_var_dec([token|rest]) do
		case rest do
			[] -> {a,line} = token
				  raise "Parsing error : unexpected end of file in var dec after #{to_string{a}} on line : #{line}"
			[{{:ident,a},_}|rest1] -> case rest1 do
									[{{:var_dec},_}|rest2] -> {exp,rest3} = parse_exp rest2
															 [{:var_dec,a,exp}|rest3]
									[{a,line}|_] -> raise "Parsing error : expected := but got #{Enum.join(Tuple.to_list(a))} on line #{line}"
									end
			[{a,line}|rest1] -> raise "Parsing error : expected a var name but got #{Enum.join(Tuple.to_list(a))} on line : #{line}"
		end
	end

	def parse_print([token|rest]) do
		case token do
			{{:print},_} -> IO.puts "print statement"
			{a,line} -> raise "Parsing error : expected a print got a #{to_string(a)} on line : #{line}"
		end
	end
end