defmodule Dwarf.CLI do
  alias Dwarf.{Lexer, Parser, Evaluator}

  @moduledoc """
  Dwarf is a small language that only contain very few operations. 

  The operations are : +,-,*,/,%
  The languages can support assignment on variable and multiple statements.

  To compile and run a file : 

                                call "./dwarf nameOfFile.dw"
                                then "./nameOfFile.s"

  """

  @doc """
    Compiles the file passed in the args. 

  """
  def main(args \\ []) do
    {:ok, source} = File.read(List.first(args))

    source
    # turns the source programs into a list of tokens
    |> Lexer.lex(1)
    # turns the list of tokens into an AST
    |> Parser.parse()
    # Inspect the output
    |> Evaluator.eval([])
  end
end
