defmodule FramexTest do
  use ExUnit.Case, async: true

  @bundled_demo Path.expand("../priv/corpora/demo_en_17", __DIR__)

  alias Framex.Annotation
  alias Framex.Corpus
  alias Framex.Fe
  alias Framex.Frame
  alias Framex.Lu
  alias Framex.Relation
  alias Framex.SemType

  setup do
    directory =
      Path.join(System.tmp_dir!(), "framenet-query-#{System.unique_integer([:positive])}")

    File.mkdir_p!(Path.join(directory, "annotations"))
    File.write!(Path.join(directory, "catalog.json"), JSON.encode!(catalog()))
    File.write!(Path.join(directory, "annotations/lu-00001.json"), JSON.encode!(annotations()))
    on_exit(fn -> File.rm_rf!(directory) end)
    {:ok, corpus} = Corpus.open(directory)
    %{corpus: corpus}
  end

  test "opens and searches the frame catalog", %{corpus: corpus} do
    assert {:ok, frame} = Frame.get(corpus, "Motion")
    assert frame["id"] == 1
    assert [%{"name" => "Motion"}] = Frame.search(corpus, "Mot")
  end

  test "uses Elixir's built-in JSON module" do
    assert function_exported?(JSON, :decode, 1)
    assert function_exported?(JSON, :encode!, 1)
  end

  test "opens the bundled minimal FrameNet artifact" do
    assert {:ok, corpus} = Corpus.open(@bundled_demo)
    assert {:ok, %{"frame" => "Desiring", "name" => "hope.v"}} = Lu.get(corpus, 6604)
    assert {:ok, %{"frame" => "Motion_noise", "name" => "swish.v"}} = Lu.get(corpus, 1046)
    assert {:ok, examples} = Annotation.arrangements(corpus, 6604)
    assert Enum.any?(examples, fn example -> example.target == "hope" end)
    assert {:ok, ["Motion", "Event"]} = Relation.inheritance_chain(corpus, "Motion")

    assert {:ok, ["Motion_noise", "Motion", "Event"]} =
             Relation.inheritance_chain(corpus, "Motion_noise")

    assert {:ok, ["Sentient"]} = SemType.for_fe(corpus, "Desiring", "Experiencer")
  end

  test "queries lexical units and frame elements", %{corpus: corpus} do
    assert [%{"name" => "run.v"}] = Lu.for_frame(corpus, "Motion")
    assert [%{"name" => "run.v"}] = Lu.search(corpus, "run", part_of_speech: "V")
    assert {:ok, %{"coreness" => "Core"}} = Fe.get(corpus, "Motion", "Theme")
  end

  test "loads only the requested annotation shard", %{corpus: corpus} do
    assert {:ok, [%{"text" => "They run."}]} = Annotation.exemplars(corpus, 1)
    assert {:ok, ["They run."]} = Annotation.sentences(corpus, 1)

    assert {:ok, [%{target: "run", frame_elements: [%{name: "Theme", text: "They"}]}]} =
             Annotation.arrangements(corpus, 1)

    assert {:ok, [%{name: "Goal", type: "DNI", sentence: "They run."}]} =
             Annotation.omitted_roles(corpus, 1)

    assert {:ok, %{"patterns" => [%{"count" => 3}]}} = Lu.valence(corpus, 1)
  end

  test "queries relations", %{corpus: corpus} do
    assert [%{"type" => "Inheritance"}] = Relation.for_frame(corpus, "Motion")
    assert {:ok, ["Motion", "Event"]} = Relation.inheritance_chain(corpus, "Motion")
  end

  test "queries semantic types", %{corpus: corpus} do
    assert {:ok, %{"id" => 8}} = SemType.get(corpus, "Entity")
    assert {:ok, ["Physical_entity"]} = SemType.for_frame(corpus, "Motion")
    assert {:ok, ["Physical_entity"]} = SemType.for_fe(corpus, "Motion", "Theme")
    assert {:ok, ["Physical_entity"]} = SemType.for_lu(corpus, 1)
  end

  defp catalog do
    %{
      "schema_version" => "framenet-query-test-v1",
      "frames" => %{
        "Motion" => %{
          "id" => 1,
          "semantic_types" => ["Physical_entity"],
          "frame_elements" => [
            %{"name" => "Theme", "coreness" => "Core", "semantic_types" => ["Physical_entity"]}
          ]
        },
        "Event" => %{"id" => 2, "frame_elements" => []}
      },
      "lexical_units" => %{
        "1" => %{
          "id" => 1,
          "name" => "run.v",
          "frame" => "Motion",
          "part_of_speech" => "V",
          "semantic_types" => ["Physical_entity"],
          "valence" => %{
            "patterns" => [%{"count" => 3}],
            "null_instantiation" => [%{"frame_element" => "Goal", "type" => "DNI"}]
          },
          "annotation_shard" => "annotations/lu-00001.json"
        }
      },
      "relations" => [
        %{"id" => 3, "type" => "Inheritance", "sub_frame" => "Motion", "super_frame" => "Event"}
      ],
      "semantic_type_hierarchy" => %{"Entity" => %{"id" => 8}}
    }
  end

  defp annotations do
    %{
      "1" => [
        %{
          "id" => 2,
          "text" => "They run.",
          "annotations" => [
            %{
              "layers" => %{
                "Target" => [%{"name" => "Target", "start" => "5", "end" => "7"}],
                "FE" => [
                  %{"name" => "Theme", "start" => "0", "end" => "3"},
                  %{"name" => "Goal", "itype" => "DNI"}
                ],
                "PT" => [%{"name" => "NP", "start" => "0", "end" => "3"}],
                "GF" => [%{"name" => "Ext", "start" => "0", "end" => "3"}]
              }
            }
          ]
        }
      ]
    }
  end
end
