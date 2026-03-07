# Plan 4

Let's make a few small additions to make it easier for people to
get started.

First, a new selector `warning`. It always generates this text
inside its region:

~~~~
<!-- WARNING: DO NOT EDIT text within caseproc SELECTOR ... end caseproc. -->
<!-- Those regions are regenerated. -->
~~~~

For now, don't allow parameters after warning (I'm not sure what
that would mean).
This addition means documents can be regenerated and contain this:

~~~~
<!-- caseproc warning -->
<!-- WARNING: DO NOT EDIT text within caseproc SELECTOR ... end caseproc. -->
<!-- Those regions are regenerated. -->
<!-- end caseproc -->
~~~~


Once that's done, let's implement a new `--start` option.
The purpose of `--start` is to help users quickly get started
(for real or for using it in a tutorial).

The `--start` option is like --validate, --select, --missing, etc.,
in the sense that --start should be added to the
existing mode exclusive group in parse_args so it can't be combined
with those other flags.

The `--start` implementation first checks if there are
any (docs/)case.(ltac,markdown,md,html) files, and if so,
panics noting the file that already exists.
While `.markdown` is less common, if `case.markdown`
*does* exist, we don't want to go any further.
Let's add `case.markdown` and `docs/case.markdown` to our list of
auto-detects, so it's all consistent.

If none of these files exists, we can proceed with its normal use.
This `--start` option
creates a new `case.ltac` file with some pre-canned content. I'll later
extend it, but for now, let's use this as the pre-canned content:

~~~~
- Claim Top: Top level claim
  - Claim G2: G2 is true
  - Claim G3: G3 is true
~~~~

It also creates a stub markdown file in `case.md`, let's use this:

~~~~
# Stub Assurance Case

This is a sample assurance case for you to edit.

<!-- caseproc warning -->
<!-- end caseproc -->

## Packages

<!-- caseproc package * -->
<!-- end caseproc -->

## Elements
~~~~

It then performs the equivalent of what `--missing` does.
This will fill in the warning and `packages *`
list, add all the missing elements, and mark the LTAC with what needs
more work.
We shouldn't need to recursively call `main()` or use a subprocess to do this.
I think we should be able to implement the "equivalent" of
`--missing` by using the same
internal `_add_missing_elements / _mark_needs_support`
code path, rather than recursively calling `main()` or spawning a subprocess.

With the stub LTAC given above, the final document's
warning and package * regions will be filled in,
and those package * regions should show G2 and G3 with {needsSupport}.
The three element regions will be appended under ## Elements
with their stub contents.
The final LTAC file will have
G2 and G3 with {needsSupport} (leaf claims)
and leave Top unmarked (it has children).
We'll eventually change the stub LTAC, but that will be a task for
another time.

I plan to create a tutorial; being able to run ``--start`
will make it easier for people to get started *and* to explain it.

Add a test to test it, both to ensure it generates our starter,
and then try to re-run the test in same directory to ensure it fails.
Do *not* run the test in the top directory, we might add a normal
`case.ltac` in our top directory. Run in a subdir of tests/ instead.
