#!/usr/bin/env elixir

defmodule PostGISFunctionComparator do
  @moduledoc """
  A script to compare PostGIS functions and identify which ones are not implemented in the Elixir library.
  """

  @doc """
  Main function to compare function lists and identify missing functions
  """
  def compare_functions(postgis_file_path, elixir_file_path, output_path \\ nil) do
    # Read the files
    {:ok, postgis_content} = File.read(postgis_file_path)
    {:ok, elixir_content} = File.read(elixir_file_path)

    # Parse the function lists
    postgis_functions =
      postgis_content
      |> String.split("\n", trim: true)
      |> Enum.map(&String.trim/1)
      |> Enum.filter(&(String.length(&1) > 0))

    # Extract function names from elixir functions (which include parameter info)
    elixir_functions =
      elixir_content
      |> String.split("\n", trim: true)
      |> Enum.map(&String.trim/1)
      |> Enum.filter(&(String.length(&1) > 0))
      |> Enum.map(fn func ->
        # Extract just the function name without parameters
        case Regex.run(~r/^([A-Za-z0-9_]+)(\(.*\))?/, func) do
          [_, name, _] -> name
          [_, name] -> name
          _ -> func
        end
      end)
      |> Enum.uniq()

    # Find functions that are in postgis_functions but not in elixir_functions
    missing_functions =
      postgis_functions
      |> Enum.filter(fn postgis_func ->
        # Check if any elixir function starts with this postgis function name
        !Enum.any?(elixir_functions, fn elixir_func ->
          elixir_func == postgis_func
        end)
      end)
      |> Enum.sort()

    # Print to console
    IO.puts("Found #{length(missing_functions)} PostGIS functions not implemented in Elixir:")
    Enum.each(missing_functions, &IO.puts/1)

    # Write to file if output path is provided
    if output_path do
      File.write!(output_path, Enum.join(missing_functions, "\n"))
      IO.puts("\nMissing functions written to: #{output_path}")
    end

    # Return the list for potential further use
    missing_functions
  end
end

# If this script is run directly (not imported)
if System.argv() != [] do
  case System.argv() do
    [postgis_file_path, elixir_file_path] ->
      PostGISFunctionComparator.compare_functions(postgis_file_path, elixir_file_path)

    [postgis_file_path, elixir_file_path, output_path] ->
      PostGISFunctionComparator.compare_functions(postgis_file_path, elixir_file_path, output_path)

    _ ->
      IO.puts("Usage: ./find_missing_functions.exs <postgis_functions_file> <elixir_functions_file> [output_file]")
  end
else
  # Default behavior when no arguments provided - use the known paths
  PostGISFunctionComparator.compare_functions(
    "./analysis/postgis_functions.txt",
    "./analysis/elixir_functions.txt",
    "./analysis/missing_functions.txt"
  )
end
