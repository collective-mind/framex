defmodule Framex.Lu do
  @moduledoc "Queries lexical units from the catalog index."

  def get(corpus, identifier),
    do: Map.fetch(corpus.catalog["lexical_units"], to_string(identifier))

  def for_frame(corpus, frame_name) do
    corpus
    |> units()
    |> Enum.filter(fn unit -> unit["frame"] == frame_name end)
  end

  def search(corpus, query, options \\ []) when is_binary(query) do
    corpus
    |> units()
    |> filter_matching_units(query)
    |> filter_units_by_options(options)
  end

  def valence(corpus, identifier) do
    with {:ok, lexical_unit} <- get(corpus, identifier) do
      {:ok, Map.get(lexical_unit, "valence", empty_valence())}
    end
  end

  defp units(corpus), do: Map.values(corpus.catalog["lexical_units"])

  defp matches_query?(unit, query), do: String.contains?(unit["name"], query)

  defp filter_matching_units(units, query) do
    Enum.filter(units, fn unit -> matches_query?(unit, query) end)
  end

  defp filter_units_by_options(units, options) do
    Enum.filter(units, fn unit -> matches_options?(unit, options) end)
  end

  defp matches_options?(unit, options) do
    Enum.all?(options, fn option -> matches_option?(unit, option) end)
  end

  defp matches_option?(unit, {:frame, frame_name}), do: unit["frame"] == frame_name

  defp matches_option?(unit, {:part_of_speech, part_of_speech}),
    do: unit["part_of_speech"] == part_of_speech

  defp matches_option?(_unit, _option), do: false

  defp empty_valence, do: %{"patterns" => [], "null_instantiation" => []}
end
