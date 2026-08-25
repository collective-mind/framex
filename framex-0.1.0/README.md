# Framex

FrameNet is a lexical database organized around semantic *frames*. Following
Boas, Ruppenhofer, and Baker, a frame has a prose definition, a set of lexical
units that evoke it, and frame elements: the situation-specific participants
and props involved. Annotated corpus sentences show which spans realize those
elements. A lexical unit is one word sense in one frame: for example, `hope.v`
evokes `Desiring`.

This concise description follows [*FrameNet at 25: Results and
Applications*](https://doi.org/10.1093/ijl/ecaf011), §2, rather than inventing
a competing terminology.

`Framex` is a read-only Elixir query layer for a reviewed FrameNet JSON
artifact. It lets an application ask which frame a word sense evokes, which
roles the frame has, how those roles appear in real sentences, and how frames
relate to one another. It is intended for artifacts produced from FrameNet 1.7
XML, but its runtime does not require Python, XML, or the original corpus.

## What FrameNet represents

FrameNet treats meaning as structured background knowledge, not as an isolated
word-to-gloss mapping. Understanding a word that evokes a frame makes the
other parts of that situation available as well. For example, `hope.v` evokes
the `Desiring` frame: someone who desires (`Experiencer`) wants a possible
change or state (`Event`) to occur. A sentence may state some of those roles,
leave others unexpressed, or realize them in different grammatical forms.

The resource records five connected kinds of evidence:

- A **frame** is the situation or concept, with a prose definition. Frames can
  describe events, states, attributes, relations, or entities.
- A **lexical unit** (LU) is a word sense or multiword expression associated
  with one frame, such as `hope.v` in `Desiring`; it has its own definition.
- A **frame element** (FE) is a role or prop in that situation. FEs are marked
  as core when they help define the frame, or as peripheral or extra-thematic
  when they provide more general contextual information.
- **Valence** records the observed grammatical realizations of FEs for an LU:
  for example, a role expressed as an external noun phrase, a prepositional
  phrase, or a finite clause.
- **Annotated exemplars** connect the analysis to real corpus sentences. They
  identify the target expression and the exact text spans that realize FEs.

Frames are also connected by typed relations. An `Inheritance` relation means
that a more specific frame inherits structure from a more general one; the
bundled corpus, for example, contains `Motion_noise → Motion → Event`.

This summary paraphrases Section 2 of Boas, Ruppenhofer, and Baker’s
[*FrameNet at 25: Results and
Applications*](https://sites.la.utexas.edu/hcb/files/2025/05/Boas-et-al-2025-FrameNet.pdf).

Framex requires Elixir 1.18 or newer and uses Elixir's built-in `JSON` module;
it has no JSON-library dependency.

The catalog is loaded once. Annotation JSON files remain on disk and are read
only when `Framex.Annotation.exemplars/2` requests a lexical unit.

## Install

```elixir
def deps do
  [{:framex, "~> 0.1"}]
end
```

## Open an artifact

```elixir
{:ok, corpus} = Framex.open("priv/framenet-1.7")
```

## Bundled demo artifact

The Hex package includes a small, real FrameNet 1.7 artifact at
`priv/corpora/demo_en_17`. It contains the `hope.v`, `purchase.v`, and `swish.v`
lexical units, their selected frames, semantic-type closure, internal frame
relations, and up to twelve annotated exemplars per lexical unit.

```elixir
with {:ok, corpus} <- Framex.open(Application.app_dir(:framex, "priv/corpora/demo_en_17")),
     {:ok, hope} <- Framex.Lu.get(corpus, 6604),
     {:ok, examples} <- Framex.Annotation.arrangements(corpus, 6604) do
  %{lexical_unit: hope["name"], frame: hope["frame"], first_example: List.first(examples)}
end
```

In IEx, this returns only the final summary rather than printing the catalog as
an intermediate assignment value.

The complete corpus is deliberately not embedded in the Hex package. Use an
external artifact path for the full FrameNet dataset.

## Three FrameNet-style investigations

The bundled corpus is small, but its records are genuine FrameNet 1.7 data.
These IEx queries correspond to three central uses of FrameNet: describing a
lexical entry, inspecting a corpus annotation, and following the conceptual
network. Start an IEx session with `iex -S mix`, then open the artifact once:

```elixir
demo_path = Application.app_dir(:framex, "priv/corpora/demo_en_17")
{:ok, corpus} = Framex.open(demo_path)
```

### 1. A lexical entry and its valence

`hope.v` evokes the `Desiring` frame. The query returns its conceptually core
roles and the number of annotated syntactic valence patterns. A valence pattern
records how a frame element is expressed, for example as a noun phrase or a
finite clause.

```elixir
with {:ok, hope} <- Framex.Lu.get(corpus, 6604),
     {:ok, desiring} <- Framex.Frame.get(corpus, hope["frame"]),
     {:ok, valence} <- Framex.Lu.valence(corpus, 6604) do
  %{
    lexical_unit: hope["name"],
    frame: hope["frame"],
    core_roles:
      desiring["frame_elements"]
      |> Enum.filter(fn element -> element["coreness"] == "Core" end)
      |> Enum.map(fn element -> element["name"] end),
    valence_patterns: length(valence["patterns"])
  }
end
```

```elixir
%{
  lexical_unit: "hope.v",
  frame: "Desiring",
  core_roles: ["Experiencer", "Event", "Focal_participant", "Location_of_event"],
  valence_patterns: 12
}
```

### 2. A corpus sentence with semantic roles

FrameNet does not merely associate a word with a frame: it records which span
of an authentic sentence realizes each frame element. Here, the finite clause
realizes the desired `Event`.

```elixir
with {:ok, arrangements} <- Framex.Annotation.arrangements(corpus, 6604) do
  List.first(arrangements)
end
```

```elixir
%{
  target: "hoped",
  sentence: "It can be hoped that Spanish Prime Minister ...",
  frame_elements: [
    %{
      name: "Event",
      text: "that Spanish Prime Minister ...",
      grammatical_function: "Dep",
      phrase_type: "Sfin"
    }
  ]
}
```

### 3. A frame relation as a conceptual path

`Motion_noise` is a more specific kind of `Motion`, which is in turn a kind of
`Event`. This inheritance path makes the structure of the semantic network
explicit.

```elixir
Framex.Relation.inheritance_chain(corpus, "Motion_noise")
```

```elixir
{:ok, ["Motion_noise", "Motion", "Event"]}
```

These queries support applications such as explanatory dictionaries, semantic
role labeling, language-learning material, and semantic analysis of
requirements text. Framex reports corpus evidence; it does not infer facts
that are absent from the artifact.

## Query modules

```elixir
alias Framex.Annotation
alias Framex.Fe
alias Framex.Frame
alias Framex.Lu
alias Framex.Relation
alias Framex.SemType

{:ok, motion} = Frame.get(corpus, "Motion")
units = Lu.for_frame(corpus, "Motion")
{:ok, theme} = Fe.get(corpus, "Motion", "Theme")
{:ok, examples} = Annotation.exemplars(corpus, 123)
{:ok, omitted} = Annotation.omitted_roles(corpus, 123)
{:ok, valence} = Lu.valence(corpus, 123)
relations = Relation.for_frame(corpus, "Motion")
{:ok, chain} = Relation.inheritance_chain(corpus, "Motion")
{:ok, types} = SemType.for_fe(corpus, "Motion", "Theme")
```

The API is divided into seven modules: `Framex.Corpus`, `Framex.Frame`,
`Framex.Lu`, `Framex.Fe`, `Framex.Annotation`, `Framex.Relation`, and
`Framex.SemType`.

FrameNet supplies semantic evidence, not application authorization or policy.

See [the terminology guide](TERMINOLOGY.md) for FrameNet and Framex concepts.
