defmodule Dwarf.Lexer do
  @moduledoc """
  				The lexer generates tokens from an input string. 

  				tokens are : 
  					{:concat} -> the concat symbols "<>"
  					{:op,"op"}   -> Binary operation such as + - / * >= < ==
  					{:uop,"!"}  -> Unary operation Not
  					{:ident,"name of ident"}  -> an identification to a variable a := 3 Ident(a,{int,3})
  					{:num,10000}  -> a number 
  					{:string,"string"} -> a string "string"
  					{:true} -> the keyword "true"
  					{:false} -> the keyword "false"
  					{:int} -> the integer type
  					{:bool -> the boolean type
  					{:fun} -> the fun type
  					{:dec} -> the symbol ":=" which is used to declare a new var or fun (IE.int a := 4)
  					{:coma} -> a coma ","
  					{:print} -> Output a value to the command line print 4 ("4")
  					{:if} -> the keyword "if"
  					{:then} -> the keyword "then"
  					{:else} -> The keyword "else"
  					{:arrow} -> the arrow symbole '->'
  					{:lbracket},{:rbracket} -> "()"
  					{:lcurly},{:rcurly} -> "{}"
  					{:eq} -> "="

  """

  @doc """
  	## Examples

  	iex> Tokens.lex("thisShouldWork")
  	true
  iex> Tokens.lex("9ThisShouldntWork")
  	false

  """
  @type op :: {:op, atom}
  @type uop :: {:uop, atom}
  @type str_token :: {String.t(), tuple}

  @spec lex(String.t(), integer) :: list
  def lex(toLex, num_lines) do
    
    # Create the list of keywords
    keywords = keywords()
    ident_re = ~r(^[a-zA-Z]\w*)
    number_re = ~r(^[0-9]+)
    space_re = ~r(^[ \h]+)
    newline_re = ~r(^[\n\\|\r\n])
    string_re = ~r/^"(?:[^"\\]|\\.)*"/
    
    cond do

      toLex == "" ->
        []

      Regex.match?(space_re, toLex) ->
        lex(Regex.replace(space_re, toLex, "", global: false), num_lines)

      Regex.match?(newline_re, toLex) ->
        lex(Regex.replace(newline_re, toLex, "", global: false), num_lines + 1)

      Regex.match?(number_re, toLex) ->
            num = String.to_integer(List.first(Regex.run(number_re, toLex, [{:capture, :first}])))
            [{:num, num} | lex(Regex.replace(number_re, toLex, "", global: false), num_lines)]
       Regex.match?(string_re, toLex) ->
            string = List.first(Regex.run(string_re, toLex, [{:capture, :first}]))
            sliced_string = String.slice(string, 1, String.length(string) - 2)
            [{:string, sliced_string} | lex(Regex.replace(string_re, toLex, "", global: false), num_lines)]
      true ->
      	{result,str_token} = containsKeyword(toLex, keywords)

      	cond do 
      	  result -> 
      	    {str, token} = str_token
            [{token, num_lines} | lex(String.replace_leading(toLex, str, ""), num_lines)]
        
          Regex.match?(ident_re, toLex) ->
            id = List.first(Regex.run(ident_re, toLex, [{:capture, :first}]))
		    token = {:ident, id}
            [{token, num_lines} | lex(Regex.replace(ident_re, toLex, "", global: false), num_lines)]
      
          true -> raise "could not parse : #{toLex}"
        end	
      end
  end

  # return a string representation of the token
  def show_token(token) do
    case token do
      # the arrow symbol ->
      {:arrow} ->
        "->"

      # operation such as + - 
      {:op, _} ->
        show_op(token)

      # unary operation not 
      {:uop, _} ->
        show_uop(token)

      # just a number like 1,2,3
      {:num, a} ->
        to_string(a)

      # just a string like "foo", "bar"
      {:string, a} ->
      	a

      # the boolean true
      {:true} ->
        "true"

      # the boolean false
      {:false} ->
        "false"

      # ident == identifier such as name of var or function
      {:ident, nameOfIdent} ->
        nameOfIdent

      # the type "int"
      {:type, :int} ->
        "int"

      # lambda
      {:type, :fun} ->
        "fun"

      # the type "boolean"
      {:type, :bool} ->
        "boolean"
      # The type "String" ->
      {:type, :string} ->
      	"string"

      # a print statement
      {:print} ->
        "print"

      # assign
      # := a var declaration
      {:dec} ->
        ":="

      # = used for assignment
      {:eq} ->
        "="

      # flow statement
      {:if} ->
        "if"

      {:else} ->
        "else"

      {:then} ->
        "then"

      # syntax brackets
      {:lcurly} ->
        "{"

      {:rcurly} ->
        "}"

      {:lbracket} ->
        "("

      {:rbracket} ->
        ")"

      {:coma} ->
        ","

      {a} ->
        raise "Lexer Error : have received #{to_string(a)}, the lexer does not recognize this input"
    end
  end

  # shows the operator as a string from the token 
  @spec show_op(op) :: String.t()
  defp show_op({:op, operator}) do
    case operator do
      :concat -> "<>"
      :sub -> "-"
      :add -> "+"
      :div -> "/"
      :mul -> "*"
      :mod -> "%"
      :gt -> ">"
      :ge -> ">="
      :se -> "<="
      :st -> "<"
      :equality -> "=="
      _ -> raise "Lexer Error : Unknown Binary operator : #{operator}"
    end
  end

  # if a non-operation token is given returns an error
  defp show_op({a}) do
    atom_str = to_string({a})
    raise "Lexer Error : not a binary operation : #{atom_str}"
  end

  # return a string representation 
  @spec show_uop(uop) :: String.t()
  defp show_uop({:uop, operator}) do
    case operator do
      :not -> "!"
      _ -> raise "Lexer Error : Unknown Unary operator : #{operator}"
    end
  end

  defp show_uop({a}) do
    atom_str = to_string(a)
    raise "not a unary operation : #{atom_str}"
  end

  # returns a list of all the keywords of the language 
  @spec keywords() :: [str_token]
  defp keywords() do
    tokens = [  
      {:arrow},
      {:uop, :not},
      {:op, :concat},
      {:op, :add},
      {:op, :mul},
      {:op, :sub},
      {:op, :div},
      {:op, :equality},
      {:op, :ge},
      {:op, :gt},
      {:op, :se},
      {:op, :st},
      {:true},
      {:false},
      {:dec},
      {:eq},
      {:print},
      {:type, :bool},
      {:type, :int},
      {:type, :fun},
      {:type, :string},
      {:if},
      {:else},
      {:then},
      {:lcurly},
      {:rcurly},
      {:lbracket},
      {:rbracket},
      {:coma}
    ]

    token_to_map = fn a -> {show_token(a), a} end
    Enum.map(tokens, token_to_map)
  end

  @spec containsKeyword(String.t(), list) :: {boolean, tuple}
  defp containsKeyword(input, keywords) do
    Enum.reduce_while(keywords, {}, fn {key, val}, _ ->
      if !String.starts_with?(input, key) do
        {:cont, {false, {}}}
      else
        {:halt, {true, {key, val}}}
      end
    end)
  end
end
