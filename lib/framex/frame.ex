defmodule Framex.Frame do
  @moduledoc "Queries FrameNet frame records."

  def get(corpus, name), do: Map.fetch(corpus.catalog["frames"], name)

  def all(corpus) do
    corpus.catalog["frames"]
    |> attach_frame_names()
    |> sort_frames()
  end

  def search(corpus, query) when is_binary(query) do
    corpus
    |> all()
    |> Enum.filter(fn frame -> String.contains?(frame_name(frame), query) end)
  end

  defp frame_name(frame), do: Map.get(frame, "name", "")

  defp attach_frame_names(frames) do
    Enum.map(frames, fn {name, frame} -> Map.put_new(frame, "name", name) end)
  end

  defp sort_frames(frames) do
    Enum.sort_by(frames, fn frame -> frame["name"] end)
  end
end
