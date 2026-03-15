# API improvement candidates (second pass)

*2026-03-15. Successor to ,api-improvements.md.*

Items 1–5, 8, 9, 19, 20, 21, 27 are done; 17 and 18 were dropped.
Items A, O, P are also done (see below).
This document covers what remains: the items that still apply, updated
for the current code (Case class, instance methods, new names).

---

## B. `out=None` returns `str` from render methods (was item 7)

**Current state:** All render methods require a `TextIO out`.

**Proposed change:** When `out` is omitted (defaults to None), create an
internal `StringIO`, fill it, and return `getvalue()`.  When `out` is
provided, behave as today (return bool).

```python
# Before:
buf = io.StringIO(); case.render_info('X', buf); text = buf.getvalue()

# After:
text = case.render_info('X')
```

**Applies to:** `render_info`, `render_selector`, `render_element`,
`render_package`, `render_ltac_txt`, `write_ltac`, `ltac_string` (item D
below already does this one).

**Notes:**
- The return type becomes `Union[str, bool]` depending on whether `out` is
  provided.  Alternatively, always return `str` and drop the bool entirely —
  callers rarely branch on the bool in practice.
- A shared helper avoids repetition:
  ```python
  def _maybe_str(func, *args, out=None, **kwargs):
      if out is None:
          buf = io.StringIO()
          func(*args, out=buf, **kwargs)
          return buf.getvalue()
      return func(*args, out=out, **kwargs)
  ```
- Can be done method-by-method; no need to change all at once.

---

## C. Rename `decl_pkg_id_for` → `declaring_package()`, return Node (was item 10)

**Current state:** `case.decl_pkg_id_for(ident) -> Optional[str]` returns the
string ID of the package root.  Most callers immediately do
`case.registry[case.decl_pkg_id_for(ident)]` to get the Node.

**Proposed change:**

```python
def declaring_package(self, ident: str) -> Optional['Node']:
    pkg_id = self.id_info.get(ident, _EMPTY).get('decl_pkg_id')
    return self.registry.get(pkg_id) if pkg_id else None
```

Keep `decl_pkg_id_for` as a deprecated alias returning the string.

**Notes:** Grep `decl_pkg_id_for` to find internal callers in render
functions that can be simplified to `case.declaring_package(ident)`.

---

## D. Rename `find_citation_parents` → `citing_nodes` (was item 11)

**Current state:** `case.find_citation_parents(ident) -> List[Node]`.

**Proposed change:** Rename to `case.citing_nodes(ident)`.
Keep old name as alias.

---

## E. Add `case.node_for(ident)` simple lookup (was item 12)

**Current state:** `case.registry.get(ident)` is the only way.

**Proposed change:**

```python
def node_for(self, ident: str) -> Optional['Node']:
    """Return the Node for ident, or None if not found."""
    return self.registry.get(ident)
```

One-liner; keeps `registry` internal detail hidden from callers who
just want a node.

---

## F. Rename `collect_bfs` → `nodes_bfs` (was item 13)

**Current state:** `collect_bfs(roots) -> List[Node]`; free function and
Case shim both named `collect_bfs`.

**Proposed change:** Rename to `nodes_bfs` (consistent with `all_nodes`,
`all_nodes_fast`).  Keep `collect_bfs` as alias and in `__all__`.

**Notes:** Grep `collect_bfs` in verocase.py and tests to find callers.

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

## H. Add `parse_ltac_string(text, config=None) -> Case` (was item 15)

**Current state:** `parse_ltac_lines(lines, config)` requires a list.

**Proposed change:** One-liner wrapper in `__all__`:

```python
def parse_ltac_string(text: str, config=None) -> 'Case':
    return parse_ltac_lines(text.splitlines(keepends=True), config=config)
```

Add after `parse_ltac_lines`; add to `__all__` and `--help-api`.

---

## I. Add `case.ltac_string() -> str` (was item 16)

**Current state:** Getting LTAC as a string requires `io.StringIO()` boilerplate.

**Proposed change:**

```python
def ltac_string(self) -> str:
    buf = io.StringIO()
    self.write_ltac(buf)
    return buf.getvalue()
```

If item B (out=None) is implemented first, `write_ltac` itself gains this
ability and `ltac_string()` may become redundant — keep it anyway as a
named convenience.

---

## J. Add `case.needs_support()` Case shim (was item 22)

**Current state:** `needs_support(nodes)` is a public free function; callers
must write `needs_support(list(case.all_nodes()))`.

**Proposed change:**

```python
def needs_support(self) -> List['Node']:
    return needs_support(list(self.all_nodes()))
```

Trivial shim; free function stays in `__all__`.

---

## K. Add `case.update_documents()` (was item 23)

**Current state:** No Case method processes all document files in-place with
the backup+atomic-replace machinery.

**Proposed change:**

```python
case.update_documents(add_missing=False, strip=False) -> bool
```

Processes every path in `self.document_files`, writes output to temp files,
calls `commit_updates` once.  Returns `not self.had_error`.

**Notes:**
- `_detect_line_ending` (or equivalent) determines CRLF handling per file —
  grep the file for how `main()` handles this before calling `_make_temp`.
- `commit_updates` and `_make_temp` are defined late in the file; Python
  resolves method body names at call time so forward references are fine.
- Consider also returning the `seen` set (like item A) so callers can
  check element coverage.
- This is the most valuable remaining high-level method: it lets library
  callers do `load_case()` + `case.update_documents()` to mirror the CLI.

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

## N. `validate=True` on `load_ltac_file`; align with `load_case` (was item 26)

**Current state:** `load_ltac_file(path, config=None)` performs no validation.
`load_case(..., validate=True)` validates by default.  `case.validate_ltac()`
exists (added in the Case refactor).

**Proposed change:**

```python
def load_ltac_file(path, config=None, validate=True) -> Case:
```

When `validate=True`, calls `case.validate_ltac()` before returning.

**Notes:**
- `load_case` calls `load_ltac_file` internally; it must pass `validate=False`
  and then call `case.validate_ltac()` itself to avoid double-validation.
- `parse_ltac_lines` keeps `validate=False` default (lowest-level entry point,
  used in tests with intentionally invalid LTAC).
- This closes the asymmetry: `load_ltac_file` is now safe by default just
  like `load_case`.

---

## Summary table

| # | Change | Size | Priority |
|---|--------|------|----------|
| B | `out=None` returns `str` from render methods | Medium | Medium |
| C | `decl_pkg_id_for` → `declaring_package()` returning Node | Small | Medium |
| D | `find_citation_parents` → `citing_nodes` | Trivial | Low |
| E | Add `case.node_for(ident)` | Trivial | Medium |
| F | `collect_bfs` → `nodes_bfs` | Trivial | Low |
| G | Audit + drop unused `config` param from `render_ltac_txt` | Small | Medium |
| H | Add `parse_ltac_string(text, config=None)` | Trivial | Medium |
| I | Add `case.ltac_string()` | Trivial | Medium |
| J | Add `case.needs_support()` shim | Trivial | Low |
| K | Add `case.update_documents()` | Medium | High |
| L | Add `case.update_files()` (LTAC + docs atomic) | Medium | High |
| M | `SafeWriter` context manager | Large | Defer |
| N | `validate=True` on `load_ltac_file` | Small | High |
