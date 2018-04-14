
defmodule Dwarf.CLI do
  alias Dwarf.{Lexer,Parser}
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
    {:ok,source} = File.read(List.first args)
    source 
    |> Lexer.lex(0) # turns the source programs into a list of tokens
    # |> Parser.parse # turns the list of tokens into an AST
    |> IO.inspect # Inspect the output
  end
end
