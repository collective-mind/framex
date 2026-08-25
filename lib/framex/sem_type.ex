defmodule Framex.SemType do
  @moduledoc "Queries FrameNet semantic types and their hierarchy."

  alias Framex.Fe
  alias Framex.Frame
  alias Framex.Lu

  def get(corpus, name) do
    corpus.catalog
    |> Map.get("semantic_type_hierarchy", %{})
    |> Map.fetch(name)
  end

  def parents(corpus, name) do
    with {:ok, sem_type} <- get(corpus, name) do
      {:ok, Map.get(sem_type, "parents", [])}
    end
  end

  def for_frame(corpus, frame_name) do
    with {:ok, frame} <- Frame.get(corpus, frame_name) do
      {:ok, Map.get(frame, "semantic_types", [])}
    end
  end

  def for_fe(corpus, frame_name, fe_name) do
    with {:ok, frame_element} <- Fe.get(corpus, frame_name, fe_name) do
      {:ok, Map.get(frame_element, "semantic_types", [])}
    end
  end

  def for_lu(corpus, identifier) do
    with {:ok, lexical_unit} <- Lu.get(corpus, identifier) do
      {:ok, Map.get(lexical_unit, "semantic_types", [])}
    end
  end
end
