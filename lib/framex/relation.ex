defmodule Framex.Relation do
  @moduledoc "Queries frame relations and semantic-type hierarchy data."

  def for_frame(corpus, frame_name) do
    corpus.catalog["relations"]
    |> Enum.filter(fn relation -> relates_to_frame?(relation, frame_name) end)
  end

  def by_type(corpus, relation_type) do
    corpus.catalog["relations"]
    |> Enum.filter(fn relation -> relation["type"] == relation_type end)
  end

  def inheritance_chain(corpus, frame_name), do: follow_inheritance(corpus, frame_name, [])

  defp relates_to_frame?(relation, frame_name) do
    relation["sub_frame"] == frame_name or relation["super_frame"] == frame_name
  end

  defp follow_inheritance(corpus, frame_name, visited) do
    case frame_name in visited do
      true -> {:error, :cyclic_inheritance}
      false -> continue_inheritance(corpus, frame_name, visited)
    end
  end

  defp continue_inheritance(corpus, frame_name, visited) do
    case parent_relation(corpus, frame_name) do
      nil -> {:ok, Enum.reverse([frame_name | visited])}
      relation -> follow_inheritance(corpus, relation["super_frame"], [frame_name | visited])
    end
  end

  defp parent_relation(corpus, frame_name) do
    Enum.find(corpus.catalog["relations"], fn relation ->
      relation["type"] == "Inheritance" and relation["sub_frame"] == frame_name
    end)
  end
end
