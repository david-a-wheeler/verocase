# verocase.py Code Review

## Pre-calculated Constants

**13. Config fallback strings are repeated literals instead of `DEFAULT_CONFIG[key]`**
E.g., `config.get('pkg_header_prefix', '### ')` — the literal `'### '` must stay in sync with `DEFAULT_CONFIG`. Use `DEFAULT_CONFIG['pkg_header_prefix']` as the fallback instead.

**14. `_ASSERTION_STATUSES` defined at ~5360, used at ~971**
Move it near `_STATUS_OPTIONS` (~2760) where the related constant lives, and reconcile why `_ASSERTION_STATUSES` includes `'ascited'` but `_STATUS_OPTIONS` does not (see overlapping constants below).

---

## Excessive Blank Lines

Three or more consecutive blank lines (should be two between top-level definitions per PEP 8) appear at approximately lines: **3127, 3776, 3896, 4095, 5361, 5483–5487**.

---

## Overlapping Constants Maintenance Hazard

**`_STATUS_OPTIONS` vs `_ASSERTION_STATUSES`** — two frozensets covering overlapping domain (assertion statuses), defined ~2500 lines apart, with `_ASSERTION_STATUSES` including `'ascited'` that `_STATUS_OPTIONS` does not. The mutual-exclusivity check manually adds `'ascited'` at the use site. These should be one constant (or clearly documented as intentionally different).
