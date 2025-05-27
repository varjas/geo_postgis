#!/usr/bin/env elixir

defmodule PostGISFunctionExtractor do
  @moduledoc """
  A script to extract all PostGIS function names from the fragment macros in geo_postgis.ex
  """

  @doc """
  Main function to extract and output PostGIS function names
  """
  def extract_functions(file_path, output_path \\ nil) do
    {:ok, content} = File.read(file_path)

    # Extract function signatures using regex
    # Looking for patterns like: fragment("ST_Function(?, ?, ?)"
    function_signatures =
      Regex.scan(~r/fragment\(["']([^"']+)["']/, content)
      |> Enum.map(fn [_, function_signature] -> function_signature end)
      |> Enum.uniq()
      |> Enum.sort()

    # Print to console
    IO.puts("Found #{length(function_signatures)} unique PostGIS function signatures:")
    Enum.each(function_signatures, &IO.puts/1)

    # Write to file if output path is provided
    if output_path do
      File.write!(output_path, Enum.join(function_signatures, "\n"))
      IO.puts("\nFunction signatures written to: #{output_path}")
    end

    # Return the list for potential further use
    function_signatures
  end
end

# If this script is run directly (not imported)
if System.argv() != [] do
  case System.argv() do
    [file_path] ->
      PostGISFunctionExtractor.extract_functions(file_path)

    [file_path, output_path] ->
      PostGISFunctionExtractor.extract_functions(file_path, output_path)

    _ ->
      IO.puts(
        "Usage: ./analysis/extract_postgis_functions.exs <path_to_geo_postgis.ex> [output_file_path]"
      )
  end
else
  # Default behavior when no arguments provided - use the known path
  PostGISFunctionExtractor.extract_functions(
    "./lib/geo_postgis.ex",
    "./analysis/postgis_functions.txt"
  )
end
