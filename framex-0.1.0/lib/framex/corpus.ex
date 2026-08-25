defmodule Framex.Corpus do
  @moduledoc """
  Opens and validates a FrameNet artifact directory.
  """

  @required_catalog_keys ["schema_version", "frames", "lexical_units", "relations"]

  def open(path) do
    with {:ok, directory} <- validate_directory(path),
         {:ok, catalog} <- read_catalog(directory),
         :ok <- validate_catalog(catalog) do
      {:ok, %{directory: directory, catalog: catalog}}
    end
  end

  def annotation_shard(corpus, shard) do
    corpus.directory
    |> Path.join(shard)
    |> File.read()
    |> decode_json()
  end

  defp validate_directory(path) do
    case File.stat(path) do
      {:ok, %{type: :directory}} -> {:ok, Path.expand(path)}
      {:ok, _stat} -> {:error, {:invalid_artifact_directory, path}}
      {:error, reason} -> {:error, {:artifact_unreadable, reason}}
    end
  end

  defp read_catalog(directory) do
    directory
    |> Path.join("catalog.json")
    |> File.read()
    |> decode_json()
  end

  defp decode_json({:ok, contents}), do: JSON.decode(contents)
  defp decode_json({:error, reason}), do: {:error, {:artifact_unreadable, reason}}

  defp validate_catalog(catalog) do
    case missing_catalog_keys(catalog) do
      [] -> :ok
      keys -> {:error, {:invalid_catalog, {:missing_keys, keys}}}
    end
  end

  defp missing_catalog_keys(catalog) do
    Enum.reject(@required_catalog_keys, fn key -> Map.has_key?(catalog, key) end)
  end
end
