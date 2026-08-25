defmodule Framex.Fe do
  @moduledoc "Queries semantic roles declared by frames."

  alias Framex.Frame

  def all(corpus, frame_name) do
    with {:ok, frame} <- Frame.get(corpus, frame_name) do
      {:ok, Map.get(frame, "frame_elements", [])}
    end
  end

  def get(corpus, frame_name, element_name) do
    with {:ok, elements} <- all(corpus, frame_name) do
      find_element(elements, element_name)
    end
  end

  defp find_element(elements, element_name) do
    case matching_element(elements, element_name) do
      nil -> {:error, :unknown_frame_element}
      element -> {:ok, element}
    end
  end

  defp matching_element(elements, element_name) do
    Enum.find(elements, fn element -> element["name"] == element_name end)
  end
end
