# verocase wishlist

We have some proposed analysis options, selectors, and
file-modifying options for `verocase.py`.

**Analysis options** provide information without modifying any file.
The existing `--stats` is also an analysis option. Analysis options
may be freely combined with each other. They *NEVER* modify any file,
so they can be run without worrying about unintended changes. Because
of this, they cannot be combined with file-modifying options.
New analysis options proposed: `--empty`, `--missing`, `--leaves`,
`--packages`, `--orphans`, `--misplaced`.

We propose some new selectors: `ltac/txt ID`, `info ID`.
These also provide more information.

**File-modifying options** change the document or LTAC. They cannot
be combined with analysis options.
New file-modifying options proposed: `--fixmissing` (rename of
current `--missing`, with improved placement behavior) and
`--fixmisplaced`.

As always, please add tests as we add functionality, and make sure the --help
information is clear so that humans and AIs who *only* read the --help
output will have a basic understanding of what these are and
how to use them. The updated --help must include all of these.
Update docs/tutorial.md and docs/reference.md too.

---

## `--empty`

List every element whose selector region exists in the document but
has no human-written prose after `<!-- end verocase -->` before the
next marker.

Output format: a header line, then one element per line with type
and ID:

```
Elements with no prose in the document(s):
Evidence KnownVulnsBundleEv
Claim AssetsIdentified
```

**Why useful:** `--stats` already reports a *count* of prose-less
elements, but gives no way to find them. When there are 5 (or 50)
such elements scattered across a 7000-line document, hunting them
by hand is tedious.

---

## `--missing` and `--fixmissing` (rename existing `--missing`)

The current `--missing` option scaffolds stubs into the document
(modifies files). Rename it to **`--fixmissing`** to make clear that
it modifies files, consistent with the naming convention for
file-modifying options.

Add a new **`--missing`** analysis option (read-only) that merely
*lists* elements declared in the LTAC that have no selector region in
the document at all — the read-only counterpart to `--fixmissing`.

Output format: a header line, then one element per line with type
and ID:

```
Elements missing a selector region in the document(s):
Claim XXESafe
Evidence XXESafeEv
```

**Why useful:** Before deciding to scaffold, it's useful to see what's
missing without the document being modified. Also fits the analysis
option contract (never modifies files), which `--fixmissing` cannot
satisfy.

---

## `--leaves`

List every leaf element (no children in the LTAC), grouped by type,
with their `{option}` flags shown.
Include: element ID, type, short title (truncated to ~60 chars),
and flags (`{needssupport}`, `{axiomatic}`, etc.).

Omit `^citations` (they are references, not elements) and `Link`
entries (connectors, not claims or evidence). Do include elements
that are the *target* of a citation yet meet this criterion.
Being cited by another package
does not make an element a non-leaf; if anything it makes it more
important to surface, since multiple elements depend on it.

Output format: LTAC syntax, one element per line, unindented (no
indentation, since parent context is not shown). Options and
file/URL references are included exactly as they appear in the LTAC.

Example output:

```
Leaf elements:
Leaves with {needssupport}:
- Claim AssetsIdentified: Key assets (badge data, user credentials, system availability) have been identified {needssupport}
- Claim ThreatsIdentified: Key threat actors (external attackers, bots, insiders, nation-states) have been identified and addressed {needssupport}

All leaves:
- Claim AssetsIdentified: Key assets ... {needssupport}
- Claim ThreatsIdentified: Key threat actors ... {needssupport}
- Evidence XXESafeEv: Nokogiri disables DTD loading and network access by default... (../Gemfile.lock)
- Evidence ErubisSafeEv: rails_best_practices and pronto are dev/test-only... (../Gemfile)
...
```

Lead with the `{needssupport}` subset (if any) since those are the
most actionable. Then list all leaves. Omit `^citations` and `Link`
entries. Strategy and Context leaves may be omitted unless they carry
a problem flag.

**Why useful:** `--stats` reports the count but not which elements.
When adding new sub-claims (e.g., splitting a `{needssupport}` claim
into sub-claims), I need to confirm which leaves remain and whether
they all have evidence or are legitimately axiomatic.

---

## `--packages`

List each package with its element count, its root element, and the
direct children of that root — in LTAC syntax. Each child is followed
by a count of itself plus all its descendants (including any citations
and links within the subtree), so the reader can immediately judge
which child to `--detach` and what the resulting package sizes would be.

Example output:

```
Packages:
Package Requirements (21 elements)
- Claim Requirements: Security requirements are identified and met
  - Strategy SecTriad: Security triad (CIA) and access control address the requirements (18 elements)
  - Claim Assets: Assets & threat actors identified & addressed (3 elements)

Package Implementation (31 elements)
- Claim Implementation: Security in implementation
  - Strategy CommonVulns: Most vulnerabilities arise from common categories of error (27 elements)
  - Strategy HardeningStrat: Hardening reduces the impact of successful attacks (2 elements)
  - Claim PubVulns: Published vulnerabilities in dependencies are monitored (3 elements)
...
```

(Element counts are illustrative; actual counts depend on the current LTAC.)

**Why useful:** Complements `--stats`'s "Largest package" line.
When a package is getting large and I'm considering `--detach`,
the direct children of the root are the natural candidate detach
points, and their subtree sizes show exactly what the split would
produce — without reading the full LTAC manually.

---

## `ltac/txt` selector format

A new selector format that renders the selected element and all its
descendants recursively as LTAC source, rather than as processed
Markdown. Following the existing convention of `type/id`, the format
prefix `ltac/txt` precedes any element ID (not just a package root).

Usage examples:

```
./verocase.py --select "ltac/txt Requirements" --stdout
./verocase.py --select "ltac/txt Confidentiality" --stdout
```

Output: the LTAC declaration of the named element and its full
subtree, indented as in `case.ltac`, with element IDs, titles,
options (`{needssupport}`, `{axiomatic}`), and file/URL references —
but none of the generated Markdown: no `<!-- verocase ... -->`
comments, no `#### Claim Foo:` headings, no `**Supported by:**` lines.
Citations (`^ID`) are shown as-is.

**Why useful:** The existing `--select "Package X" --stdout` output
is Markdown, which adds generated header lines, HTML comment markers,
and `[text](url)` link syntax around every cross-reference. When
evaluating a `--detach` candidate, all of that is noise — the LTAC
indented subtree is the signal. Generalizing beyond package roots
means any element can be inspected this way. Currently the workaround
is `grep`-ing the raw `.ltac` file, which requires manually tracing
indentation to find subtree boundaries.

---

## `info ID` selector

A selector that provides full context for a single element ID: where
it sits in the tree, what depends on it, and what it depends on.

Usage example:

```
./verocase.py --select "info SpecialAnalysis" --stdout
```

Output for a non-root element with no citations (e.g., `info SpecialAnalysis`):

```
Element: Claim SpecialAnalysis: Reused components with apparent vulnerabilities are analyzed and safe
Package: Implementation
Ancestors (root first):
  - Claim Implementation: Security in implementation
  - Strategy CommonVulns: Most vulnerabilities arise from common categories of error
  - Claim ReuseSec: Reused software is secure
  - Strategy ReuseStrat: Reuse is often appropriate and can be done securely
Children:
  - Claim XXESafe: Nokogiri/libxml2 XXE exception (CVE-2016-9318) poses no risk in our deployment
  - Claim ErubisSafe: XSS from erubis via pronto-rails_best_practices poses no production risk
  - Claim LocalSecretSafe: Checked-in tmp/local_secret.txt secret_key_base value poses no security risk
  - Claim ActionCableSafe: ActionCable information-exposure risk is mitigated because ActionCable is not used
Descendants: 8 (including self, all descendants, citations, and links in subtree)
Citations: 0
```

For an element that is the target of `^citations` from other packages,
list each citing element and its package (e.g., `info OWASPClaim`):

```
Element: Claim OWASPClaim: All of the most common important implementation vulnerability types countered
Package: OWASPClaim
Ancestors: (package root)
Children:
  - Strategy OWASPStrat: OWASP top 10 represents a broad consensus of the most critical web application security flaws
Descendants: 28 (including self, all descendants, citations, and links in subtree)
Citations: 1
  Cited as ^OWASPClaim by: Claim Implementation (Package Implementation)
```

For a package root with no citations (e.g., `info Security`):

```
Element: Claim Security: The system is adequately secure against moderate threats
Package: Security
Ancestors: (package root)
Children:
  - Strategy Processes: Security is argued by examining all lifecycle processes
  - Claim Controls: ...
Descendants: 11 (including self, all descendants, citations, and links in subtree)
Citations: 0
```

**Why useful:** Determining an element's full ancestry currently
requires reading the LTAC and tracing indentation by hand. When
deciding whether to `--detach` a subtree, or when understanding why
a particular claim exists, seeing ancestors + children + citation
parents in one shot saves significant time.

---

## `--orphans`

List every element that has a selector region in the document
(`<!-- verocase element ID -->` ... `<!-- end verocase -->`) but has
no matching declaration in the LTAC. These are stale regions left
behind after an element has been renamed or removed from the LTAC.

This is the inverse of `--missing`: `--missing` finds LTAC elements
absent from the document; `--orphans` finds document regions absent
from the LTAC.

Output format: a header line, then one element per line with type
and ID as recorded in the document's selector comment:

```
Orphaned selector regions in the document(s) (not in LTAC):
Claim OldClaimName
Evidence FormerEvidenceId
```

`--orphans` is a read-only analysis option and never modifies any
file. To actually remove orphaned regions, the author should review
them manually and delete them — they may contain prose worth
salvaging before deletion.

**Why useful:** After renaming or removing an element in the LTAC,
its old selector region silently persists in the document. verocase
has no way to warn about this during normal operation because it only
processes elements it knows about. Orphaned regions waste space and
can confuse readers; `--orphans` makes them visible.

---

## `--misplaced` and `--fixmisplaced`

`--misplaced` is a read-only analysis option that lists elements
whose selector region appears in the document in a different order
than their declaration order in the LTAC. `--fixmisplaced` is the
corresponding file-modifying option that moves the misplaced full regions
(selector comment, generated text, selector end,
and the following prose block until another selector or verocase-config)
into the correct position.

**What "correct position" means:** The LTAC defines a tree order for
all elements (depth-first, as written). In the document, each
element's selector region should appear in the same relative order as
in the LTAC. An element is "misplaced" if it appears before or after
where it should be relative to its siblings and neighbors.

**The most common case:** `--fixmissing` (the file-modifying scaffold
command) appends new element regions at the *end* of the document.
After scaffolding, all newly added elements are misplaced — they sit
at the bottom instead of near their parent. `--misplaced` identifies
them; `--fixmisplaced` moves them.

Output format for `--misplaced`: a header line, then one element per
line showing its current document line number and its expected
predecessor:

```
Misplaced elements (document order differs from LTAC order):
Claim XXESafe: at line 7314, expected after Claim SpecialAnalysis (line 3057)
Evidence XXESafeEv: at line 7325, expected after Claim XXESafe (line 7314)
Claim ErubisSafe: at line 7294, expected after Evidence XXESafeEv (line 7325)
```

`--fixmisplaced` moves each misplaced region to immediately after
its expected predecessor, preserving all content. A "region" consists
of everything from the `<!-- verocase element ID -->` start comment
through `<!-- end verocase -->` and then all following lines up to
(but not including) the next `<!-- verocase element -->`,
`<!-- verocase-config -->`, or `<!-- end verocase -->` marker — i.e.,
the generated header plus the author's prose block. It processes
moves in LTAC order so that each move lands in the right place even
when multiple elements are misplaced. It modifies the document file
and is not combinable with analysis options.

**Why useful:** After a round of `--fixmissing`, newly scaffolded
elements cluster at the bottom of a large document far from their
parent claims, making the document hard to read and edit. Manually
finding the right insertion point for each element in a 7000-line
file is tedious and error-prone.

---

## Improve `--fixmissing` placement

Currently `--fixmissing` appends all new element stubs at the end of
the document. It should instead place each new stub near its natural
position in the document, using the following algorithm:

**For each missing element, in LTAC depth-first order:**

1. Walk backwards through the LTAC depth-first sequence from that
   element's position to find the nearest predecessor that already
   has a selector region in the document. "Already has" includes
   both pre-existing regions *and* regions placed earlier in this
   same `--fixmissing` run (so a batch of new elements placed
   together all land in the right relative order).

2. Insert the new stub immediately after that predecessor's full
   region: after the predecessor's `<!-- end verocase -->` tag and
   its entire following prose block — i.e., everything up to but not
   including the next `<!-- verocase element -->` or
   `<!-- verocase-config -->` marker.

3. Fall back to appending at the end of the document only if no
   predecessor with a selector region exists (e.g., the document is
   empty or every element in the LTAC is new).

Processing in LTAC order is essential: it ensures that each
newly-placed element is a valid predecessor for the elements that
follow it in the LTAC, so even large batches of new elements are
placed correctly relative to each other.

**Goal:** After `--fixmissing`, the document should be in correct
LTAC order with no elements needing `--fixmisplaced`. The
append-at-end fallback should be rare (empty document or first-time
scaffold only). `--fixmisplaced` remains useful for repairing
documents whose LTAC was reorganized after the document was written,
but should not be needed as a routine follow-up to `--fixmissing`.

---

## Notes on combining

These analysis options should be combinable freely, e.g.:

```
./verocase.py --empty --missing --orphans --misplaced --leaves
```

prints each report in sequence, separated by a blank line, then exits
without modifying any file. None of them trigger document
regeneration.

The file-modifying counterparts (`--fixmissing`, `--fixmisplaced`)
are NOT analysis options and cannot be combined with analysis options
or with each other.
