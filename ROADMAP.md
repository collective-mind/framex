# Framex roadmap

This roadmap turns the findings in Boas, Ruppenhofer, and Baker, *FrameNet at
25: Results and Applications* (2025), into deliverable Framex milestones.
The paper is available at <https://doi.org/10.1093/ijl/ecaf011> and an author
hosted PDF is available at
<https://sites.la.utexas.edu/hcb/files/2025/05/Boas-et-al-2025-FrameNet.pdf>.

## Product boundary

Framex is a read-only, local query library over a reviewed FrameNet artifact.
It preserves provenance and exposes FrameNet evidence; it is neither a frame
parser nor an application policy engine.

The source corpus is not a statistically representative sample of English.
Consequently, annotation counts must always mean *attested FrameNet examples*,
never general-language probabilities. This follows the authors' account of the
project's deliberately non-representative annotation selection policy.

## Phase 1: stable core queries

Status: complete for catalog, frame, LU, FE, annotation, relation, and semantic
type lookup.

Public modules:

```elixir
Framex.Corpus
Framex.Frame
Framex.Lu
Framex.Fe
Framex.Annotation
Framex.Relation
Framex.SemType
```

Acceptance criteria:

- `Framex.open/1` validates a catalog without reading annotation shards.
- `Framex.Annotation.exemplars/2` reads only the requested shard.
- `Framex.Annotation.arrangements/2` joins `Target`, `FE`, `PT`, and `GF`
  labels by text span.
- Unknown identifiers and missing shards return tagged errors rather than
  crashing.

## Phase 2: lexical-entry and valence views

The paper describes an LU entry as more than a list of examples: it includes
frame elements, their syntactic realizations, and a valence table of frame
element configurations. Framex already exports the required `valence.patterns`
data; it should expose it directly.

Add:

```elixir
Framex.Lu.valence(corpus, lu_id)
Framex.Lu.valence_patterns(corpus, lu_id)
Framex.Lu.null_instantiation(corpus, lu_id)
```

Return a normalized pattern such as:

```elixir
%{
  frame_elements: ["Agent", "Air", "Depictive"],
  realizations: [
    %{frame_element: "Agent", phrase_type: "NP", grammatical_function: "Ext"},
    %{frame_element: "Depictive", phrase_type: "PP", preposition: "as"}
  ],
  attested_count: 20
}
```

Acceptance criteria:

- Counts are named `attested_count` and documented as corpus evidence only.
- Results can be filtered by FE, phrase type, and grammatical function.
- A pattern links back to the exemplars that support it where source IDs exist.

## Phase 3: realized and omitted roles

FrameNet distinguishes syntactically realized roles from zero realizations. A
missing text span is semantic data, not malformed annotation.

Add:

```elixir
Framex.Annotation.roles(corpus, lu_id)
Framex.Annotation.omitted_roles(corpus, lu_id)
```

The response must keep the distinction explicit:

```elixir
%{
  realized: [%{name: "Buyer", text: "Matheson", phrase_type: "NP"}],
  omitted: [%{name: "Seller", kind: "DNI"}]
}
```

Acceptance criteria:

- Span-less FE labels never crash rendering.
- `DNI`, `INI`, and `CNI` are preserved without collapsing their meaning.
- `arrangements/2` returns visible roles; `roles/2` returns both visible and
  omitted roles.

## Phase 4: idiomatic query composition

Provide a thin query facade only after the direct modules are stable. It must
be composable and transparent about when disk I/O occurs.

```elixir
corpus
|> Framex.Query.from_lu("purchase.v")
|> Framex.Query.in_frame("Commerce_buy")
|> Framex.Query.with_examples()
|> Framex.Query.arrangements()
|> Framex.Query.take(3)
```

Acceptance criteria:

- Catalog filters run before annotation reads.
- `with_examples/1` is the first operation allowed to load a shard.
- Query results retain LU ID, frame name, and source annotation ID.

## Phase 5: multilingual and domain extensions

The paper shows that many frames transfer across languages, but also that
culturally and institutionally specific frames do not transfer without care.
Framex must therefore avoid treating English FrameNet as universal.

Add an explicit artifact identity:

```elixir
%{source: "Berkeley FrameNet", release: "1.7", language: "en"}
```

Then support separate artifacts rather than silently merging inventories:

```elixir
Framex.open("priv/framenet-en-1.7")
Framex.open("priv/framenet-pt-br")
```

Acceptance criteria:

- Every result contains artifact source, release, and language.
- Cross-artifact mappings are opt-in, versioned data.
- Domain frames and local relations can be registered without modifying the
  English inventory.

## Phase 6: assisted annotation, never silent automation

The paper reports continuing automation research for frame creation and corpus
annotation, while emphasizing the cost and unresolved quality issues. Framex
should first support reviewable proposals, not automatic truth.

Add a separate optional package, `framex_assist`:

```elixir
Framex.Assist.propose_frame(sentence, options)
Framex.Assist.propose_roles(sentence, frame, options)
```

Acceptance criteria:

- Proposals carry model, prompt/configuration, source text, and confidence.
- No proposal modifies a reviewed Framex artifact in place.
- Human approval produces a new versioned artifact via the offline exporter.

## Immediate next milestone

Implement Phase 2 and Phase 3 together. They turn the current example display
into the paper's central lexical-entry view: a user can see both the examples
and the recurring FE/syntax configurations that those examples establish.
