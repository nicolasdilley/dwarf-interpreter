defmodule Dwarf.Parser do
  @moduledoc """
  	The parser takes a list of tokens and genarates an AST trees from it.
    The parse is a decent recursive parser.
  	This AST tree will be further optimized by the optimizer.

  	type of stmt =
  		{:assign,line,[nameOfVar,expr]} -> type nameOfVar := expr
  		{:print,line,[expr]} -> print expr
  		{:call,line,[nameOfFunction,args]} -> add(args)
  		{:dec,line,[type,ident,expr]} -> type ident := expr
      {:if,line,[expr,true_stmt,false_stmt]} -> if expr then true_stmt else false_stmt
      {:fun,line,[name,args,stmt]} -> fun name := (args) -> stmt

  	type of expr = 
  		{:op,line,[expr,operator,expr2} = expr op expr2
  		{:uop,line,[:not,expr]} = !expr
  		{:var,line,[identifier]} -> var like a, foo, bar
  		 
    type of param = 
      {:param,line,[type,name]}
  """

  @doc """
  	Parses a list of tokens into an AST tree
  """

  def parse([]), do: []

  def parse(tokens) do
    {stmt, rest} = parse_stmt(tokens)
    [stmt | parse(rest)]
  end

  @spec parse_stmt(list) :: {list, list}
  defp parse_stmt([token | rest]) do
    case token do
      # parse a function declaration
      {:type, _, [:fun]} ->
        parse_fun_dec([token | rest])

      # parse a var declaration (int i := 3)
      {:type, _, _} ->
        parse_var_dec([token | rest])

      # parse an if statement
      {:if, _, _} ->
        parse_if_stmt([token | rest])

      # print statement
      {:print, _, _} ->
        parse_print([token | rest])

      # assignmment such as a = a + 4
      {:ident, _, _} ->
        case List.first(rest) do
          {:eq, _, _} -> parse_assign([token | rest])
          _ -> parse_exp([token | rest])
        end

      # parse a list of statements
      {:lcurly, _, _} ->
        parse_stmts([token | rest])

      {a, line, _} ->
        raise "Parsing error : unexpected #{to_string(a)} on line : #{line}"
    end
  end

  defp parse_stmt([]), do: []

  defp parse_factor([token | rest]) do
    case token do
      {:num, _, _} ->
        {token, rest}

      {:string, _, _} ->
        {token, rest}

      {true, line, [val]} ->
        {{:bool, line, [val]}, rest}

      {false, line, val} ->
        {{:bool, line, [val]}, rest}

      {:uop, line, [op]} ->
        {expr, rest1} = parse_factor(rest)
        {{:uop, line, [op, expr]}, rest1}

      {:ident, line, [a]} ->
        case rest do
          [{:lbracket, _, _} | _] -> parse_func([token | rest])
          _ -> {{:var, line, [a]}, rest}
        end

      {:lbracket, _, _} ->
        {expr, rest1} = parse_exp(rest)

        case rest1 do
          [{:rbracket, _, _} | rest2] ->
            {expr, rest2}

          [{_, line, _} | _] ->
            raise "Parsing error: expected a ) on line #{line}"

          [] ->
            raise "Parsing error: unexpected end of file in a bracketised expression"
        end

      {a, line, _} ->
        raise "Parsing Error : expected a factor but got #{to_string(a)} on line #{line}"
    end
  end

  # look for the rest of operators with medium precedence
  defp parse_term([]), do: raise("Parsing error : End of file while trying to parse a term")

  defp parse_term(tokens) do
    {l_expr, rest} = parse_factor(tokens)

    case rest do
      [{:op, line, [:mul]} | rest1] ->
        {r_expr, rest2} = parse_term(rest1)
        {{:op, line, [:mul, l_expr, r_expr]}, rest2}

      [{:op, line, [:div]} | rest1] ->
        {r_expr, rest2} = parse_term(rest1)
        {{:op, line, [:div, l_expr, r_expr]}, rest2}

      [{:op, line, [:mod]} | rest1] ->
        {r_expr, rest2} = parse_term(rest1)
        {{:op, line, [:mod, l_expr, r_expr]}, rest2}

      _ ->
        {l_expr, rest}
    end
  end

  # look for operator with low precedence like addition or substraction 
  # and then look for term 
  defp parse_op(tokens) do
    {l_expr, rest} = parse_term(tokens)

    case rest do
      [{:op, line, [:add]} | rest1] ->
        {r_expr, rest2} = parse_op(rest1)
        {{:op, line, [:add, l_expr, r_expr]}, rest2}

      [{:op, line, [:sub]} | rest1] ->
        {r_expr, rest2} = parse_op(rest1)
        {{:op, line, [:sub, l_expr, r_expr]}, rest2}

      [{:op, line, [:ge]} | rest1] ->
        {r_expr, rest2} = parse_op(rest1)
        {{:op, line, [:ge, l_expr, r_expr]}, rest2}

      [{:op, line, [:gt]} | rest1] ->
        {r_expr, rest2} = parse_op(rest1)
        {{:op, line, [:gt, l_expr, r_expr]}, rest2}

      [{:op, line, [:se]} | rest1] ->
        {r_expr, rest2} = parse_op(rest1)
        {{:op, line, [:se, l_expr, r_expr]}, rest2}

      [{:op, line, [:st]} | rest1] ->
        {r_expr, rest2} = parse_op(rest1)
        {{:op, line, [:st, l_expr, r_expr]}, rest2}

      [{:op, line, [:equality]} | rest1] ->
        {r_expr, rest2} = parse_op(rest1)
        {{:op, line, [:equality, l_expr, r_expr]}, rest2}

      _ ->
        {l_expr, rest}
    end
  end

  defp parse_exp([]), do: raise("Parsing error: End of file while trying to parse an expression")
  @spec parse_exp(list) :: {tuple, list}
  defp parse_exp(tokens) do
    {l_expr, rest} = parse_op(tokens)

    case rest do
      [{:op, line, [:concat]} | rest1] ->
        {r_expr, rest2} = parse_exp(rest1)
        {{:op, line, [:concat, l_expr, r_expr]}, rest2}

      _ ->
        {l_expr, rest}
    end
  end

  # Parse a list of statement and return a list of statements and the rest of the tokens.
  @spec parse_stmts(list) :: {list, list}
  defp parse_stmts([token | rest]) do
    case token do
      {:rcurly, _, _} ->
        {[], rest}
      {:lcurly,_,_} -> 
        {stmt, rest1} = parse_stmt(rest)
        {stmts, rest2} = parse_stmts(rest1)

        {[stmt | stmts], rest2}
      _ -> 
        {stmt, rest1} = parse_stmt([token|rest])
        {stmts, rest2} = parse_stmts(rest1)

        {[stmt | stmts], rest2}
        
    end
  end

  defp parse_func([token | rest]) do
    case token do
      {:ident, line, [a]} ->
        case rest do
          [{:lbracket, _, _} | [{:rbracket, _, _} | rest1]] ->
            {{:call, line, [a, []]}, rest1}

          [{:lbracket, _, _} | rest1] ->
            {args, rest2} = parse_args(rest1)

            case rest2 do
              [{:rbracket, line, _} | rest3] -> {{:call, line, [a, args]}, rest3}
              [{_, line, _}, _] -> raise "Parser error : Expected a ) on line #{line}"
            end

          [{_, line, _} | _] ->
            raise "Parser error : parsing a function without a ( on line #{line}"
        end

      {_, line, _} ->
        raise "Parser error : Expected an identifier for a function on line #{line}"
    end
  end

  # parses the args of a function such as add(2+3,8)
  defp parse_args([token | rest]) do
    {node, rest1} = parse_exp([token | rest])

    case rest1 do
      [{:coma, _, _} | rest2] ->
        {args, rest3} = parse_args(rest2)
        {[node | args], rest3}

      _ ->
        {[node], rest1}
    end
  end

  defp parse_args([]), do: raise("Parsing Error: end of file while parsing args")

  @spec parse_var_dec(list) :: {tuple, list}
  defp parse_var_dec([token | rest]) do
    case rest do
      [] ->
        {a, line, _} = token

        raise "Parsing error : unexpected end of file in var dec after #{to_string(a)} on line : #{
                line
              }"

      [{:ident, _, [a]} | rest1] ->
        case rest1 do
          [{:dec, _, _} | rest2] ->
            {exp, rest3} = parse_exp(rest2)
            {_type, line, [type]} = token
            {{:dec, line, [type, a, exp]}, rest3}

          [{a, line, _} | _] ->
            raise "Parsing error : expected := but got #{to_string(a)} on line #{line}"
        end

      [{a, line, _} | _] ->
        raise "Parsing error : expected a var name but got #{to_string(a)} on line : #{line}"
    end
  end

  defp parse_var_dec([]),
    do: raise("Parsing Error: end of file while parsing a variable declaration")

  # Parse a function declaration
  # To create a function "fun nameOfFunction := (int param1, fun param2) -> expr"
  defp parse_fun_dec([token | rest]) do
    case token do
      {:type, line, [:fun]} ->
        case rest do
          [{:ident, _, [function_name]} | rest1] ->
            case rest1 do
              [{:dec, _, _} | rest2] ->
                case rest2 do
                  [{:lbracket, _, _} | [{:rbracket, _, _} | rest3]] ->
                    {expr, rest4} = parse_exp(rest3)
                    {{:fun, line, [function_name, [], expr]}, rest4}

                  [{:lbracket, _, _} | rest1] ->
                    {args, rest2} = parse_params(rest1)

                    case rest2 do
                      [{:rbracket, _, _} | [{:arrow, _, _} | rest3]] ->
                        {expr, rest4} = parse_stmt(rest3)
                        {{:fun, line, [function_name, args, expr]}, rest4}

                      [{_, line} | _] ->
                        raise "Parser error : Expected a ) on line #{line}"
                    end

                  [{_, line, _} | _] ->
                    raise "Parser error : parsing a function without a ( on line #{line}"
                end

              [{a, line, _} | _] ->
                raise "Parsing error : expected a := name received : #{to_string(a)} on line : #{
                        line
                      }"
            end

          [{a, line, _} | _] ->
            raise "Parsing error : Expected a function name received : #{to_string(a)} on line : #{
                    line
                  }"
        end

      {_, line, _} ->
        raise "Parsing error : Trying to parse a function declaration without starting with 'fun' on line #{
                line
              }"
    end
  end

  defp parse_params([]), do: raise("Parsing error : End of file expected a type")

  defp parse_params([token | rest]) do
    case token do
      {:type, line, [type]} ->
        case rest do
          [{:ident, _, [name]} | rest1] ->
            case rest1 do
              [{:coma, _, _} | rest2] ->
                {args, rest3} = parse_params(rest2)
                {[{:param, line, [type, name]} | args], rest3}

              _ ->
                {[{:param, line, [type, name]}], rest1}
            end
        end

      {a, line, _} ->
        raise "Parsing error : Expected a type received #{to_string(a)} on line : #{line}"
    end
  end

  defp parse_if_stmt([token | rest]) do
    case token do
      {:if, line, _} ->
        {expr, rest1} = parse_exp(rest)

        case rest1 do
          [{:then, _, _} | rest2] ->
            {true_stmt, rest3} = parse_stmt(rest2)

            case rest3 do
              [{:else, _, _} | rest4] ->
                {false_stmt, rest5} = parse_stmt(rest4)
                {{:if, line, [expr, true_stmt, false_stmt]}, rest5}

              [{a, line, _} | _] ->
                raise "Parsing error : Expected 'else' received : #{to_string(a)} on line : #{
                        line
                      }"
            end

          [{_, line, _} | _] ->
            raise "Parsing error : Expected a then on line #{line}"

          [] ->
            raise "Parsing error : End of file expected then"
        end

      {a, line, _} ->
        raise "Parsing error : Expected 'if' received : #{to_string(a)} on line : #{line}"
    end
  end

  defp parse_print([token | rest]) do
    case token do
      {:print, line, _} ->
        {exp, rest1} = parse_exp(rest)
        {{:print, line, [exp]}, rest1}

      {a, line, _} ->
        raise "Parsing error : expected a print got a #{to_string(a)} on line : #{line}"
    end
  end

  defp parse_assign([token | rest]) do
    case token do
      {:ident, line, [ident]} ->
        case rest do
          [{:eq, _, _} | rest1] ->
            {expr, rest2} = parse_exp(rest1)
            {{:assign, line, [ident, expr]}, rest2}

          [{a, line, _} | _] ->
            raise "Parsing error : expected an = but got : #{to_string(a)} on line : #{line}"
        end

      {a, line, _} ->
        raise "Parsing error : expected a variable name received : #{to_string(a)} on line : #{
                line
              }"
    end
  end
end
