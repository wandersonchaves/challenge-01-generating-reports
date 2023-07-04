defmodule GenReport.Parser do
  @moduledoc """
  Provides function parse_file/1 to reade and convert file in List
  """

  @doc """
  Read and return a List with all lines of a CSV file.

  ## Parameters

    - fileName: String that representas the file to read and parser.
  """

  _fileName = "./gen_report.csv"

  def parse_file(fileName) do
    "report/#{fileName}"
    |> File.stream!()
    |> Stream.map(fn line -> parse_line(line) end)
  end

  @doc """
  Parser a line, removing spaces and split in array

  ## Parameters

    - line: String that represents the line read of the file.
  """
  defp parse_line(line) do
    line
    |> String.trim()
    |> String.split(",")
    |> List.update_at(1, &String.to_integer/1)
    |> List.update_at(2, &String.to_integer/1)
    |> List.update_at(3, &String.to_integer/1)
    |> List.update_at(4, &String.to_integer/1)
  end
end
