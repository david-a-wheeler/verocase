# caseproc README

`caseproc` is a simple open source software tool
that makes it *easy* and *efficient*
to create and maintain a small or moderately-sized assurance case.
It's a simple Python3 script that processes our
extended version of the
[Lightweight Text Assurance Case (LTAC) format](docs/ltac-extended.txt),
along with markdown or HTML documentation,
to generate useful assurance case documentation.
This includes automatically generating graphics with hyperlinks
for Structured Assurance Case Metamodel (SACM) and
Goal Structuring Notation (GSN).

An assurance case is "a body of evidence organized into an argument demonstrating that some claim about a system holds (i.e., is assured). An assurance case is needed when it is important to show that a system exhibits some complex
property, such as safety, security, privacy, or reliability."
([NIST Special Publication 800-53A Revision 5](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-53Ar5.pdf)).

## Background

There are many notations for expressing and maintaining assurance cases,
including SACM, GSN, and CAE.
Large assurance cases are often maintained using specialized tools that
manage a data structure containing the assurance case information.
Examples include
[Adalard ASCE](https://www.adelard.com/asce/) and
[Argevide PREMIS](https://www.argevide.com/assurance-case/).
These specialized tools allow people to edit
diagrams that flexibly present the information graphically.
For large assurance cases these tools can be quite helpful.

However, these sophisticated tools may seem excessive for
smaller assurance cases. I was looking for an alternative.

An obvious alternative to these sophisticated tools
is to write an assurance case entirely as a traditional document.
That's possible, and traditional document editing tools make it easy to
edit a document.
However, this approach doesn't provide *any* support for the
structure of an assurance case.
Maintaining an assurance case
this way requires a lot of extra work to keep parts consistent.
It's too easy to make mistakes, leading to inconsistencies,
and the results often go slowly out of date.
Such documents
often don't provide many helpful graphics to show the overview, since those are
difficult to create and maintain.

## Our approach

This tool, `caseproc`, takes a completely different approach:

* As input, it reads a simple text file written in our
  extended version of the Lightweight Text Assurance Case (LTAC) format.
  This simple format is easily understood and used, and makes it
  easy to express simple hierarchy of structure.
  The tool will identify and report various kinds of invalid constructs.
* As output, it takes a set of 1+ documents (markdown or HTML)
  and inserting graphics and text at specific insertion points.
  Note that it *automatically* generates graphical notation in SACM or
  GSN notation - you don't need to fiddle with the graphics at all.
  It also automatically generates a number of hypertext links, making it
  easy to navigate the assurance case.

Currently it can generate both SACM and GSN notation in mermaid format.
It can also generate a markdown indented bullet list that looks like LTAC
format but adds hyperlinks, making it easy to go from a high-level
summary to specific details and back.
It might someday support CAE notation as well.

Perhaps most usefully, its `-i` (in place) option
allows you to update the markdown/HTML files in place.
As a result,
you can simply run the process with a sequence of markdown filenames,
and it will update the documents directly.

## Handling evolution

Assurance cases evolve. This tool is designed to handle that.

Claims get refined, strategies get renamed,
and statement wording gets clarified.
If you *purely* do this in a document, the diagrams and document
headings easily go out of sync, and there's no hint that there's a problem.
One of the advantages of a database-based tool is that it can detect
and warn of various problems.
In addition, when a statement is changed, in a datbase-based
tool such changes are immediately updated everywhere.

This tool does a number of validations and produces various warnings.
The `--help` provides a full list, but for example,
each identifier must be declared (no ^ prefix) exactly once, and it
will tell you if that rule is violated.
We also warn every time a declared LTAC element fails to have a
corresponding document header.

We also have another trick to make editing easier.
When a markdown
document header such as `## Claim C1: Old wording` has the same
label but its statement no longer
matches the authoritative statement in the LTAC file,
`caseproc` normally warns about the discrepancy.
That warning is useful for catching accidental drift.
But when you have *intentionally* updated the LTAC and simply want
all the document headers to catch up automatically,
use the `--update` flag (or matching configuration flag) will do exactly that.
It will rewrites every stale markdown header statement to match the LTAC,
treating the LTAC as the authoritative source.
A notification is printed to stderr for each header that's changed,
so you always have a clear record of what was updated and why.

## Pros and Cons

The big pro of this approach is that it takes very little time to
get started, get graphical representations, and generate information.
It's also fairly easy to edit material.

The key outline of the assurance case is stored in the LTAC file.
The details (e.g., the "contents" in SACM terminology) is always
kept in one or more markdown or HTML files, which are
updated by this program.
Everything is done in easily-edited files, not in a database that
requires a special tool to maintain.
Since we *do* have some basic information on the element types
in the assurance case, we can report (and complain) about problems in it.
We can also complain about problems such as an element with no supporting
information.
In short, this approach makes it easy to notice and fix problems in a way
that a pure document approach does not.

The big con of this approach is that to make it work, we are intentionally
imposing various limits:

* The hierarchical representation of LTAC forces a hierarchy that GSN and SACM
  don't natively require. Instead, we require that an assurance case
  be grouped into multiple packages (modules),
  each one have a single top claim, and that they be hierarchical from there.
  We name the package after that top claim.
  We also require that any claim only be defined in one package.
  However, a claim may be *referenced* in many packages, and "Links" allow
  references to an element already in use.
  So this restriction isn't a serious problem in practice.
* We generate graphics automatically, and we currently
  use `mermaid` because it's
  directly support by GitHub's built-in markdown processor.
  Mermaid is quite limited in what it can do. This isn't too bad if you
  limit your packages to smaller numbers of elements, but it's definitely
  a limitation.
* This is not a database, it's a way to make it easier to manage documents.
  If you want a database, this tool
  isn't it. So if you are managing a large
  assurance case, this approach is probably less appealing.

## Other information

The specification of extended LTAC that we implement is in file
[docs/ltac-extended.txt](docs/ltac-extended.txt).
