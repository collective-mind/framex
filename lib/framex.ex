defmodule Framex do
  @moduledoc """
  Read-only, lazy queries over a FrameNet JSON artifact.

  `open/1` reads the catalog. Annotation shards remain on disk until requested
  through `Framex.Annotation`.
  """

  alias Framex.Corpus

  def open(path), do: Corpus.open(path)
end
