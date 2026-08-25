defmodule Framex.Annotation do
  @moduledoc """
  Lazily reads exemplar annotations for one lexical unit at a time.
  """

  alias Framex.Corpus
  alias Framex.Lu

  def exemplars(corpus, identifier) do
    with {:ok, unit} <- Lu.get(corpus, identifier),
         {:ok, shard} <- annotation_shard(unit),
         {:ok, annotations} <- Corpus.annotation_shard(corpus, shard) do
      Map.fetch(annotations, to_string(identifier))
    end
  end

  def sentences(corpus, identifier) do
    with {:ok, exemplars} <- exemplars(corpus, identifier) do
      {:ok, extract_sentences(exemplars)}
    end
  end

  def arrangements(corpus, identifier) do
    with {:ok, exemplars} <- exemplars(corpus, identifier) do
      {:ok, collect_arrangements(exemplars)}
    end
  end

  def omitted_roles(corpus, identifier) do
    with {:ok, exemplars} <- exemplars(corpus, identifier) do
      {:ok, collect_omitted_roles(exemplars)}
    end
  end

  defp annotated_arrangements(exemplar) do
    exemplar
    |> Map.get("annotations", [])
    |> build_arrangements(exemplar["text"])
    |> reject_empty_arrangements()
  end

  defp arrangement(sentence, annotation_set) do
    case target(annotation_set) do
      nil -> nil
      target_label -> build_arrangement(sentence, annotation_set["layers"], target_label)
    end
  end

  defp build_arrangement(sentence, layers, target_label) do
    %{
      sentence: sentence,
      target: span(sentence, target_label),
      frame_elements: frame_elements(sentence, layers)
    }
  end

  defp target(annotation_set) do
    annotation_set
    |> Map.get("layers", %{})
    |> Map.get("Target", [])
    |> Enum.find(fn label -> has_span?(label) end)
  end

  defp frame_elements(sentence, layers) do
    layers
    |> Map.get("FE", [])
    |> filter_spanned_labels()
    |> build_frame_elements(sentence, layers)
  end

  defp extract_sentences(exemplars) do
    Enum.map(exemplars, fn exemplar -> exemplar["text"] end)
  end

  defp collect_arrangements(exemplars) do
    Enum.flat_map(exemplars, fn exemplar -> annotated_arrangements(exemplar) end)
  end

  defp collect_omitted_roles(exemplars) do
    Enum.flat_map(exemplars, fn exemplar -> omitted_roles_for_example(exemplar) end)
  end

  defp build_arrangements(annotation_sets, sentence) do
    Enum.map(annotation_sets, fn annotation_set -> arrangement(sentence, annotation_set) end)
  end

  defp reject_empty_arrangements(arrangements) do
    Enum.reject(arrangements, fn arrangement -> is_nil(arrangement) end)
  end

  defp filter_spanned_labels(labels) do
    Enum.filter(labels, fn label -> has_span?(label) end)
  end

  defp build_frame_elements(labels, sentence, layers) do
    Enum.map(labels, fn label -> frame_element(sentence, layers, label) end)
  end

  defp omitted_roles_for_example(exemplar) do
    exemplar
    |> Map.get("annotations", [])
    |> Enum.flat_map(fn annotation_set ->
      omitted_roles_for_annotation(exemplar, annotation_set)
    end)
  end

  defp omitted_roles_for_annotation(exemplar, annotation_set) do
    annotation_set
    |> Map.get("layers", %{})
    |> Map.get("FE", [])
    |> omitted_labels()
    |> map_omitted_roles(exemplar)
  end

  defp omitted_labels(labels), do: Enum.filter(labels, fn label -> omitted_role?(label) end)

  defp map_omitted_roles(labels, exemplar) do
    Enum.map(labels, fn label -> omitted_role(exemplar, label) end)
  end

  defp omitted_role?(label), do: label["itype"] in ["DNI", "INI", "CNI"]

  defp omitted_role(exemplar, label) do
    %{
      sentence_id: exemplar["id"],
      sentence: exemplar["text"],
      name: label["name"],
      type: label["itype"]
    }
  end

  defp frame_element(sentence, layers, label) do
    %{
      name: label["name"],
      text: span(sentence, label),
      phrase_type: matching_layer_name(layers, "PT", label),
      grammatical_function: matching_layer_name(layers, "GF", label)
    }
  end

  defp matching_layer_name(layers, layer_name, label) do
    layers
    |> Map.get(layer_name, [])
    |> Enum.find(fn candidate -> same_span?(candidate, label) end)
    |> layer_name()
  end

  defp same_span?(left, right) do
    left["start"] == right["start"] and left["end"] == right["end"]
  end

  defp layer_name(nil), do: nil
  defp layer_name(layer), do: layer["name"]

  defp has_span?(label) do
    is_binary(label["start"]) and is_binary(label["end"])
  end

  defp span(sentence, label) do
    start_index = String.to_integer(label["start"])
    end_index = String.to_integer(label["end"])
    String.slice(sentence, start_index, end_index - start_index + 1)
  end

  defp annotation_shard(unit) do
    case Map.fetch(unit, "annotation_shard") do
      {:ok, shard} -> {:ok, shard}
      :error -> {:error, :annotation_shard_unavailable}
    end
  end
end
