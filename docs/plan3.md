# Plan 3: Auto-generate document headers

## Tweaks

Let's begin by first making a few smaller changes:

* In the LTAC spec `docs/ltac-extended.txt` completely remove the
  [PackageIdentifier] notation from ExternalIdentifer. This changes it from
  `ExternalIdentifier = "^" [ "[" PackageIdentifier "]" ] LocalIdentifier ;`
  to `ExternalIdentifier = "^" LocalIdentifier ;`
  LTAC identifiers are globally unique, so
  we don't need to specify the package at all.
  Indeed, globally unique identifiers make many things simpler.
  This change also eliminates figuring out the "conventional" name of a
  package in the spec.
  Note that you can still refer to an external identifier anywhere in a package
  (not just at the top).

  We need to remove the code that supports this notation from `caseproc`
  and change tests that use it. We want to simplify things!

* Whenever generating the LTAC or documents, be sure to use its line-ending
  conventions (either CRLF or LF). The first line of the file determines
  the convention. We could guess LF, but I don't know of a case where have
  to guess; in this new model, we only replace code in documents after we
  have a marker (so we know where to start), and if we're updating an LTAC
  file, we use its current convention. We do this for each file (they might
  differ).

After we've done that, let's focus on our main improvement.

## Main improvement

Currently our process for handling headers is convoluted and
different than everything else.
We have to look for markdown/HTML headers, filter out
certain anchors, etc. Our search has to identify specific English
names in headers, tying it English.

Let's *remove* all code for detecting document headers (`#...` and `<hNUMBER>`)
and for replacing the equivalent anchors. In its place, let's
create 2 new selectors `element` and `package`.

The selector `element ID` generates at least the following
when we are processing a markdown document (where `ELEMENT_TYPE`, etc.,
are placeholders):

~~~~markdown
<a id="ELEMENT_TYPE-ID"></a>
### ELEMENT_TYPE ID: ELEMENT_STATEMENT

~~~~

The same selector would generate at least the following
when we are processing an HTML document:

~~~~html
<a id="ELEMENT_TYPE-ID"></a>
<h3 id="ELEMENT_TYPE-ID-ELEMENT_STATEMENT"
>ELEMENT_TYPE ID: ELEMENT_STATEMENT</h3>

~~~~

This means we need to know if we're processing markdown or HTML while
updating a document file.
A file ending in `.md` or `.markdown` (ignoring case) is markdown.
A file ending in `.htm` or `.html` (ignoring case) is HTML.
We'll guess standard input (`-`) is markdown.
Anything else is a panic.
In --stdout mode, the input determines the output type.

The heading level (number of `#` in markdown) is determined by
the config value `element_level`, which defaults to 3.

Note that `element` sets the "current id" value to that ID
(we previously called this the "current element").
We don't allow `*` instead of ID, that wouldn't make sense.

I said the selector element generates at least, because what it generates
after that would depend on the config value `element_selections`.
This is a comma-separated list of 0+ selection names, which will be applied
in order after this. They'll each use the "current id" to determine
what to apply this to (as that was set by `element`).

By default `element_selections` will have the value
`referenced_by,supported_by,supports`.

Here is the markdown version of each of those selections:

`referenced_by` (for markdown):
~~~~
Referenced by: (hyperlinked list of packages containing it, starting with
  the one it's defined in, comma-separated)

~~~~

`supported_by`:
~~~~
Supported by: (hyperlinked list of children elements of definition)

~~~~

`supports`:
~~~~
Supports: (hyperlinked list of parents of the definition and all citations)

~~~~

As a result, a single `element` selector can generate a header
and a lot of infomration, and exactly what information is generated
is easily controlled in one place.

Similarly, the selector `package ID|*` generates in markdown at least:

~~~~markdown
### Package ID

~~~~

In markdown we don't need to add `<a id="package-ID"></a>`;
that's done by the markdown processor, and we always just show the ID
(we don't show a separate statement).

The config value `package_level` controls level of the heading,
which starts at 3.

Note that every time `package` generates a header it
sets the "current id" value to that ID
(we previously called this the "current element").

Similarly, what `package` generates after that header
would depend on the config value `package_selections`.
This is a comma-separated list of 0+ selection names, which will be applied
in order after this header for each header. They'll each use the "current id".

By default `package_selections` will have the value
`representation,pkg_root,pkg_defines,pkg_citing,pkg_cited`.

The `representation` selector, whenever used,
applies whatever selection is stored in
the config value `default_representation`, which defaults to `sacm`.
That way, users can change just the config value
`default_representation` to `gsn` and they'll get gsn for every package.

Let's add new selectors sacm, gsn, and ltac. Each of them select
the `/markdown` or `/html` variations of them depending on whether or not
the containing document is markdown or html.
E.g., `sacm` is interpreted as `sacm/markdown` when generating markdown.

The `pkg_root` selector shows the word `Root: ` followed by a single
"TYPE ID" that has a hyperlink to its header (`#TYPE-ID`)
followed by a blank line. The TYPE would usually be Claim, but we won't
enforce that here. This links us rapidly to the top element,
which is often important for understanding the package as a whole.

The `pkg_defines` selector shows the word `Defines: `,
followed by a comma-separated list of "TYPE ID" (e.g., "Claim Foo")
that has a hyperlink to its header (`#TYPE-ID`),
followed by a blank line. These are all of the elements that are
*defined* in this package (don't use `^`), starting with the top element
(which is normally a claim). Thus, we can easily jump from here
to the details of any element defined in this package from the
representation *or* this list.

The `pkg_citing` selector shows `Citing: `,
followed by a comma-separated list of "TYPE ID" (e.g., "Claim Foo").
These are all of the elements that are citing (`^`) within this package,
with a link to the *package* that defines it
(even if it's also *defined* in this package, a weirdness we allow).
Again, a blank line follows.

The `pkg_cited` selector shows `Cited by: `,
followed by a comma-separated list of "Package ID" (e.g., "Package Foo"),
where "ID" is the ID of a package's topmost element.
These are all of the packages in the assurance case
that include a cite (`^`) to an id that is defined within this package,
even if that's this package.
Its link is to the *package*.

Note that these all share the same heading.

I've expressed "followed by a blank line" or showed trailing blank lines
everywhere. When it's in a generated segment, let's suppress the very last
blank line at the end of what's generated, so we don't have lots of
useless blank lines.

Currently, per reference.md, --validate
"cross-checks their headers against the LTAC."
Instead of cross-checking *headers*, it now cross-checks against the
*element* declarations, listing elements not currently included.
Basically, it validates that every
declared LTAC element has a corresponding element selector.

The `update_headers` config key becomes obsolete with this change,
so we'll remove the config item and the code for it.

Migration strategy:
This hard-removes header scanning. Existing documents using headers
(### Claim C1: ...) will break. We don't have users yet, so I'm not worried
about transition periods. However, we should build a simple transition tool
so we can convert our test suite efficiently.

## Dynamic modification of config values

Let's make it possible to modify a config value dynamically.
That'll be especially useful, for example, for the heading levels.
Use this:

`<!-- caseproc config KEY = VALUE... -->`
Note that there's no reason to end it. This sets config KEY to VALUE,
which will last until changed again.

In the past we tracked the "current element". Let's make that the
"current ID"; using either of these new "element" or "package" selectors
*sets* the current ID. In the case of package `*`,
the system loops through each package, setting the "current ID" each time.
that way, when it calls other selectors to generate the package contents,
they'll have the correct one. After `*` ends, the "current ID" would be
the last package presented I guess.

We'll need to update tests, `--help`, and `docs/reference.md` among other
places.

## Option to add missing elements to documents

Add markers to LTAC, identify leaf nodes (including these)
with no info other than blank lines.

## Discussion

* Should we remove some existing selectors? Which ones should we remove?
  Some selectors are useful for debugging, or for special uses.
  Please list the existing selectors, and suggest which should stay
  and which should go (and why).
