
defmodule Dwarf.CLI do
  alias Dwarf.Tokens, as: Tokens
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
    IO.inspect Tokens.lex(source,0)
  end
end
