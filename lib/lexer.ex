defmodule Dwarf.Lexer do
  @moduledoc """
  				The lexer generates tokens from an input string. 
  				Tokens are a representation of a node in the AST.
  				A token is a tuple made of a name and its value.
  				If a token does not need a value, the value is nil.

  				tokens are : 
  					op   -> Binary operation such as + - / *
  					uop  -> Unary operation Not
  					ident  -> an identification to a variable a := 3 Ident(a,{int,3})
  					num  -> a number 
  					int -> the integer type
  					bool -> the boolean type
  					Assign -> an assignement to a variable a := 4 = Ident(a,{int,4})
  					semicolon -> end of statement semi-colon
  					print -> Output a value to the command line print 4 ("4")
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
    keywords = map_keywords()
    ident_re = ~r/^[a-zA-Z]\w*/
    number_re = ~r(^[0-9]+)
    space_re = ~r(^[ \h]+)
    newline_re = ~r(^[\n\\|\r\n])

    cond do
      toLex == "" ->
        []

      Regex.match?(space_re, toLex) ->
        lex(Regex.replace(space_re, toLex, "", global: false), num_lines)

      Regex.match?(newline_re, toLex) ->
        lex(Regex.replace(newline_re, toLex, "", global: false), num_lines + 1)

      Regex.match?(ident_re, toLex) ->
        id = List.first(Regex.run(ident_re, toLex, [{:capture, :first}]))
        token = Map.get(keywords, id)
        # Check if the ident is a keyword 
        if token do
          newToken = {token, num_lines}
          newString = Regex.replace(ident_re, toLex, "", global: false)
          [newToken | lex(newString, num_lines)]
        else
          token = {:ident, id}
          [{token, num_lines} | lex(Regex.replace(ident_re, toLex, "", global: false), num_lines)]
        end

      true ->
        {result, str_token} = containsKeyword(toLex, keywords())

        if result do
          {str, token} = str_token
          [{token, num_lines} | lex(String.replace_leading(toLex, str, ""), num_lines)]
        else
          if Regex.match?(number_re, toLex) do
            num = String.to_integer(List.first(Regex.run(number_re, toLex, [{:capture, :first}])))
            [{:num, num} | lex(Regex.replace(number_re, toLex, "", global: false), num_lines)]
          else
            raise "could not parse : #{toLex}"
          end
        end
    end
  end

  # return a string representation of the token
  def show_token(token) do
    case token do
      #the arrow symbol ->
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

      # the boolean true
      {:true} ->
        "true"

      # the boolean false
      {:false} ->
        "false"

      # ident == identifier such as name of var or function
      {:ident, nameOfIdent} ->
        nameOfIdent

      {:semicolon} ->
        ";"

      # the type "int"
      {:type, :int} ->
        "int"
      # lambda
      {:type,:fun} ->
        "fun"
      # the type "boolean"
      {:type, :bool} ->
        "boolean"

      # a print statement
      {:print} ->
        "print"

      # comparison operation
      # ge == greater than or equal
      {:ge} ->
        ">="

      # gt == greater than
      {:gt} ->
        ">"

      # se == smaller than or equal
      {:se} ->
        "<="

      # st == smaller than
      {:st} ->
        "<"

      {:equality} ->
        "=="

      # assign
      # := a var declaration
      {:var_dec} ->
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
      :minus -> "-"
      :add -> "+"
      :div -> "/"
      :mul -> "*"
      :mod -> "%"
      :gt -> ">"
      :ge -> ">="
      :se -> "<"
      :st -> "<"
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
      {:op, :add},
      {:op, :mul},
      {:op, :minus},
      {:op, :div},
      {:op,:ge},
      {:op,:gt},
      {:op,:se},
      {:op,:st},
      {:true},
      {:false},
      {:equality},
      {:var_dec},
      {:eq},
      {:semicolon},
      {:print},
      {:type, :bool},
      {:type, :int},
      {:type, :fun},
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

  # return a map where each string maps to its token i.e %{"print" => {:print}, ";" => {:semicolon}}
  defp map_keywords do
    Enum.reduce(keywords(), %{}, fn {k, v}, acc -> Map.put(acc, k, v) end)
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
