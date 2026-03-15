# API improvement candidates (second pass)

*2026-03-15. Successor to ,api-improvements.md.*

Items 1–5, 8, 9, 19, 20, 21, 27 are done; 17 and 18 were dropped.
Items A, B, C, D, E, F, H, I, J, K, N, O, P are also done or dropped (see below).
H was implemented as `Case.load_ltac_string()` (a Case method using
`self.config`).  N is moot: `load_ltac_file` was deleted; `Case.load()`
validates by default and `load_ltac_string()` intentionally does not.
B and I dropped: `Union[str, bool]` return type is a maintenance headache;
callers that need string capture use `io.StringIO()` directly.
F and J done: `collect_bfs`, `copy_forest`, `write_ltac`, `render_ltac_txt`,
`render_ext_ref` made private; `render_selector` free function deleted;
`needs_support` removed from public API and added as `case.needs_support()`.
K done: `case.update_documents(add_missing=False, strip=False)` added to Case;
`_check_element_coverage` free function deleted and replaced by
`case.check_element_coverage(seen_element_ids)` Case method; main()'s
default mode now delegates to `case.update_documents()`.
D done: `find_citation_parents(ident)` replaced by two methods:
`case.citations_and_links(node)` (single full-forest walk returning all
citation and Link nodes referencing `node`) and `case.parents(nodes)`
(deduplicated parents of a list of nodes).  `render_supports` now calls
`case.parents(case.citations_and_links(node))`.
This document covers what remains: the items that still apply, updated
for the current code (Case class, instance methods, new names).

---

## G. Audit `render_ltac_txt`: drop unused `config` param (was item 14)

**Current state:** `render_ltac_txt(node_list, config, out, sep='')`.
The `config` parameter was carried over from an era when it may have been
used; current inspection suggests it is not referenced in the body.

**Proposed change:** Verify by reading `render_ltac_txt` and
`_write_ltac_node_normalized`.  If `config` is indeed unused:
- Remove it from the free function and the Case shim.
- Consider renaming to `write_ltac_normalized` to distinguish from
  `write_ltac` (which writes the full forest preserving depth).
- Update `__all__` and `--help-api`.

---

## L. Add `case.update_files()` — LTAC + documents atomically (was item 24)

**Current state:** No single call serializes a modified LTAC *and* updates
all documents in one atomic, backed-up operation.

**Proposed change:**

```python
case.update_files(add_missing=False, strip=False) -> bool
```

If `case.ltac_path` is set, includes the LTAC in the `(tmp, final)` pairs.
Includes all `case.document_files`.  Calls `commit_updates` once.
Clears `case.modified` on success.

**Notes:**
- Builds on `save_ltac` (now done) and `update_documents` (item K above).
- The backup snapshot covering LTAC + all docs together is the key value:
  individual snapshots of each file are internally inconsistent.
- Pairs naturally with `case.modified`:
  `if case.modified: case.update_files()`

---

## M. Expose safe file writing for non-Case files (was item 25 option C)

**Current state:** `_make_temp`, `make_backup`, `commit_updates` are private.
Items K and L expose them indirectly via Case methods.

**Recommended future design (when a concrete need arises):** A `SafeWriter`
context manager:

```python
with verocase.SafeWriter(anchor_path, case.config) as w:
    w.write('output.ltac', ltac_content)
    w.write('docs/case.md', doc_content)
# On exit: backup created, all files atomically replaced.
# On exception: temps cleaned up, nothing replaced.
```

Defer until a caller needs to include files verocase doesn't know about
in the same atomic backup.  Option A (Case methods only) is sufficient now.

---

## Summary table

| # | Change | Size | Priority |
|---|--------|------|----------|
| G | Audit + drop unused `config` param from `render_ltac_txt` | Small | Medium |
| L | Add `case.update_files()` (LTAC + docs atomic) | Medium | High |
| M | `SafeWriter` context manager | Large | Defer |
