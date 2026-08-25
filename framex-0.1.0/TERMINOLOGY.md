# FrameNet terminology

This glossary defines the terms used by Framex and the Berkeley FrameNet 1.7
artifact it queries. **FrameNet** is the canonical spelling; it is a lexical
semantic resource, not a general ontology or an authorization system.

## Core semantic model

### Frame

A **frame** is a structured description of a situation, event, state, relation,
attribute, or entity. It names the background knowledge needed to understand a
word sense.

`Commerce_buy`, for example, describes a buying situation rather than merely
the English word `buy`.

### Frame Element (FE)

A **Frame Element** is a participant, property, or other meaningful component
of a frame. In `Commerce_buy`, `Buyer` and `Goods` are FEs.

An FE may carry a semantic-type constraint. For example, a locative role may be
typed as `Locative_relation`; not every FE has an explicit semantic type.

### Core, peripheral, and extra-thematic FE

An FE's **coreness** describes its relation to the frame definition:

- **Core** — conceptually central to the frame, such as `Buyer` and `Goods`.
- **Core-Unexpressed** — central but normally not syntactically expressed.
- **Peripheral** — broadly reusable circumstance, such as `Time`, `Place`, or
  `Manner`.
- **Extra-Thematic** — meaningful event information that is not a defining
  participant of the frame.

Coreness does not mean that a role must occur in every sentence.

### Lexical Unit (LU)

A **Lexical Unit** is a word sense or multiword expression paired with a part
of speech and a frame. It is the unit that evokes a frame.

`purchase.v` in `Commerce_buy` and `run.v` in `Self_motion` are distinct LUs.
The same spelling may occur in several frames; `run.v` is therefore not one
meaning but several frame-specific senses.

### Frame-evoking element and target

The **Frame-Evoking Element** (FEE) is the expression in a sentence that evokes
the frame. In FrameNet annotation it appears in the `Target` layer.

```text
Matheson [purchased] a plot of land.
          ^ Target / FEE
```

## Corpus annotation

### Exemplar

An **exemplar** is an attested corpus sentence annotated for one LU. It is
evidence for an LU's frame and its syntactic realizations.

FrameNet exemplar counts are counts in the selected annotation corpus. They are
not estimates of general English frequency.

### Annotation set

An **annotation set** is one annotation analysis over a sentence. A sentence
may contain more than one annotation set because it can contain multiple
targets, senses, or auxiliary annotation layers.

### Layer and label

A **layer** groups one kind of annotation. A **label** marks a character span
inside that layer. Framex joins labels by their shared `start` and `end` span.

Important layers:

| Layer | Meaning |
| --- | --- |
| `Target` | Frame-evoking expression |
| `FE` | Semantic role labels |
| `PT` | Phrase Type, such as `NP` or `PP[from]` |
| `GF` | Grammatical Function, such as `Ext`, `Obj`, or `Dep` |

### Phrase Type (PT)

**Phrase Type** records the constituent form realizing an FE:

- `NP` — noun phrase
- `PP[from]` — prepositional phrase headed by `from`
- `AVP` — adverb phrase
- `VPto` — infinitival verb phrase

### Grammatical Function (GF)

**Grammatical Function** records the syntactic function of that constituent:

- `Ext` — external argument, often the subject
- `Obj` — object
- `Dep` — dependent

Together, `PT` and `GF` explain how a semantic role is realized.

```text
Matheson purchased the land from a seller.

Buyer   = Matheson       NP / Ext
Goods   = the land       NP / Obj
Seller  = from a seller  PP[from] / Dep
```

## Valence and omitted arguments

### Valence pattern

A **valence pattern** records an attested FE realization for an LU, including
its FE, phrase type, grammatical function, and annotation count.

For `purchase.v`, FrameNet attests patterns including:

```text
Buyer   → NP / Ext
Goods   → NP / Obj
Seller  → PP[from] / Dep
```

Framex exposes the source data with `Framex.Lu.valence/2`.

### Frame Element Configuration (FEC)

A **Frame Element Configuration** is a combination of FEs realized together in
one valence pattern. It is richer than an individual FE realization: it models
the configuration of roles that co-occur in a construction.

### Null instantiation

**Null instantiation** means an FE is semantically understood but has no text
span in the sentence. This is data, not an annotation defect.

| Type | Meaning |
| --- | --- |
| `DNI` | **Definite Null Instantiation**: the omitted filler is recoverable from context. |
| `INI` | **Indefinite Null Instantiation**: an unspecified filler is understood. |
| `CNI` | **Constructional Null Instantiation**: a construction licenses the omission. |

`Framex.Annotation.omitted_roles/2` returns sentence-level omitted roles from
span-less `FE` labels. `Framex.Lu.valence/2` retains the LU-level aggregate
null-instantiation patterns.

## Network structure

### Frame relation

A **frame relation** links frame meanings. It is typed and directed as stored
by FrameNet: `sub_frame ──type──> super_frame`.

Common relation types:

| Relation | Meaning |
| --- | --- |
| `Inheritance` | A more specific frame inherits structure from a broader one. |
| `Subframe` | A frame is a stage of a larger scenario. |
| `Causative_of` | A frame is the caused counterpart of another. |
| `Perspective_on` | A frame selects a perspective on a larger scenario. |
| `Using` | A frame reuses another's conceptual structure. |
| `See_also` | A navigational relatedness link, not a derivation rule. |
| `ReFraming_Mapping` | A mapping between related frame conceptualizations. |

For example:

```text
Self_motion ──Inheritance──> Motion
Motion ──Inheritance──> Event
Motion ──Causative_of──> Cause_motion
```

Relations support navigation and structured comparison. They must not be
treated as automatic equivalence, application permission, or policy inference.

### Frame Element mapping

An **FE mapping** links roles across a related pair of frames. It lets a client
compare how a role in one conceptualization corresponds to a role in another.

### Semantic type (SemType)

A **semantic type** is a FrameNet type label arranged in a hierarchy. It can
annotate a frame, FE, or LU and provides a more general semantic constraint.

```elixir
Framex.SemType.for_fe(corpus, "Motion", "Theme")
# => {:ok, ["Physical_object"]}
```

Semantic types are evidence supplied by FrameNet; an absent type is not an
inference that the role has no real-world restriction.

## Framex artifact terms

### Catalog

`catalog.json` is the artifact's index. It contains frames, LU metadata,
relations, semantic-type hierarchy, and each LU's annotation-shard reference.
Framex loads the catalog when `Framex.open/1` succeeds.

### Annotation shard

An **annotation shard** is a separate JSON file containing exemplars for one or
more LUs. Framex reads a shard only when an annotation query requires it.

### Artifact manifest

An **artifact manifest** identifies the source, language, release, schema,
exporter version, and integrity checksum of a distributed dataset. It belongs
to the data release, not to the `framex` Hex code package.

### Reviewed artifact

A **reviewed artifact** is an offline-exported and validated dataset accepted
as the semantic evidence used at runtime. XML parsing, corpus acquisition, and
artifact construction remain outside the runtime library.

## Framex API map

| Module | Primary question |
| --- | --- |
| `Framex.Corpus` | Can this artifact be opened and read? |
| `Framex.Frame` | Which frame models this situation? |
| `Framex.Lu` | Which sense/LU evokes this frame, and how is it realized? |
| `Framex.Fe` | Which semantic roles does the frame define? |
| `Framex.Annotation` | Which roles are expressed or omitted in exemplars? |
| `Framex.Relation` | How does this frame connect to other frames? |
| `Framex.SemType` | Which semantic-type constraints are recorded? |

## Non-goals

Framex does not by itself:

- parse an arbitrary new sentence into frames and roles;
- claim that FrameNet annotation counts are population frequencies;
- turn semantic relations into business rules or permissions;
- alter the reviewed artifact at runtime;
- claim English FrameNet frames are automatically universal across languages.
