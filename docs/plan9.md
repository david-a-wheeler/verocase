# Plan 9

No, this isn't from outer space :-).

## Reorder reference and options

When I extended LTAC, I added options after the reference, this way:

~~~~
Element         = Indent "-" WS NodeType [WS Identifier] ":" WS Text [WS Reference] [WS Options] Newline
~~~~

However, I believe `[WS Reference]` and `[WS Options]` should
have their order *swapped*. That way, a system that can only read *old*
LTAC won't reject the LTAC if it's for one package - the options will
instead be considered part of the statement. That's better, because then
the information isn't lost, it's associated with the element, and the
file *can* be read in such a circumstance.

Modify `docs/ltac-extended.md` (I think you just need to swap
them in that one line). Implement this change in the `caseproc` tool,
our tests, and bp-docs/case.ltac. When implementing this change in our
tests and case.ltac, do a grep first - I suspect doing both a reference and
options is extremely rare. There may not even be a test of this; if there
isn't, add one where we have both an option and a reference.

## Check for escapes when writing LTAC, fix and test

It's legal for an LTAC statement to end in {...} or (...), you just have
to add an empty one afterwards if necessary to escape it.
However, I don't know that we write the escapes when we write LTAC files.

Verify that we can read and correctly rewrite LTAC examples like this, and
if not, fix it. We should only add the empty escapes when we need to.
Here are some examples:

~~~~
- Claim C1: Foo (really a foo) ()
  - Claim C2: Bar {really a bar} {}
  - Claim C3: Baz (really a bar) {needsSupport}
  - Claim C4: Fizz (fizz.txt)
~~~~
