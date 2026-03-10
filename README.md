# caseproc README

`caseproc` is a simple open source software tool
that makes it *easy* and *efficient*
to create and maintain a small or moderately-sized assurance case,
e.g., for justifying why a system is secure against attack.

More specifically, `caseproc` is a simple open source software (OSS)
Python3 script that reads a file written in our extended version of the simple
[Lightweight Text Assurance Case (LTAC) format](docs/ltac-extended.txt)
and updates related markdown or HTML documentation.
The result is an easily read and easily modified assurance case.
The script automatically generates graphics
for both Structured Assurance Case Metamodel (SACM) and
Goal Structuring Notation (GSN), and generates many hyperlinks
to make it easy navigate an assurance case.
Because these are simple text files, they're easily read and easily modified
both by humans and by AI.

An assurance case is "a body of evidence organized into an argument demonstrating that some claim about a system holds (i.e., is assured). An assurance case is needed when it is important to show that a system exhibits some complex
property, such as safety, security, privacy, or reliability."
([NIST Special Publication 800-53A Revision 5](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-53Ar5.pdf)).

The [tutorial](docs/tutorial.md) explains how to use the tool.
The [reference manual](docs/reference.md) explains tool use in detail.

## Background

Large assurance cases are often maintained using specialized tools that
manage data structures containing the assurance case information.
Examples include
[Adalard ASCE](https://www.adelard.com/asce/) and
[Argevide PREMIS](https://www.argevide.com/assurance-case/).
These specialized tools allow people to edit
diagrams that flexibly present the information graphically.
For large assurance cases these tools can be quite helpful.

However, these sophisticated tools seem excessive for
smaller assurance cases.
They require installation, learning to use them, and committing to
storing all data in a database that can only be managed by a complex tool.
I was looking for an alternative.

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
often don't provide many helpful graphics to show the overview, since those
graphics are a pain to create and maintain.

The graphics matter, too.
There are several graphical notations for easily
expressing and maintaining assurance cases, including
the Object Management Group's
[Structured Assurance Case Metamodel (SACM)](https://www.omg.org/spec/SACM),
[Goal Structuring Notation (GSN)](https://scsc.uk/gsn-standard), and
[Claims Arguments Evidence (CAE)](https://claimsargumentsevidence.org/notations/claims-arguments-evidence-cae/).
Hand-maintaining them can be burdensome, involving carefully placing
all the symbols, and moving and updating them as information changes.
An AI can help, but it's error-prone for humans to maintain them,
and AI can make the same mistakes.

## Our approach

This tool, `caseproc`, takes a completely different approach:

* As input, it reads a simple text file (default file `case.ltac`
  in `./` or `docs/`). This file is written in our
  extended version of the Lightweight Text Assurance Case (LTAC) format.
  This simple format is easily understood and used, and makes it
  easy to express simple hierarchy of structure and high-level statements.
  The tool will identify and report various kinds of invalid constructs
  (e.g., citations of undefined elements, invalid types, logical circularity,
  unreachable elements, and so on).
* As output, it updates a set of 1+ documents (in markdown or HTML),
  including fixing headers and inserting/updating graphics
  (default file `case.[md,html]` in `./` or `docs/`).
  Note that it *automatically* generates graphical notation in SACM or
  GSN notation - you don't need to fiddle with the graphics at all.
  It also automatically generates a number of hypertext links, making it
  easy to navigate the assurance case.
  The expectation is that humans and AIs would edit these documents to
  provide all the details (aka "content").
  In contrast, `caseproc` updates the document to
  keep all information easily in sync.

Just run `caseproc` and the output documents will be updated based on the
input LTAC file.

Currently the tool can generate both SACM and GSN notation in mermaid format.
It can also generate a markdown indented bullet list that looks like LTAC
format but adds hyperlinks, making it easy to go from a high-level
summary to specific details and back.
It might someday support CAE notation as well.
The tool can also insert various cross-references and update heading names
as appropriate.

The result is *much* easier to integrate into version control systems like git,
since all information is kept in simple text files.
Both AI and humans find this information really easy to follow.
AI systems love markdown and HTML, and they
also know how to handle indented structures like LTAC.
It's remarkably easy to edit, too - just use tools you already know how to use.

## Handling evolution

Assurance cases evolve.
If you *purely* edit an assurance case
in a document various errors can creep in, the diagrams and document
headings can easily go out of sync,
and there's no hint that there's a problem.
This tool is designed to easily handle assurance case evolution
better than a simple document can.

This tool does a number of validation checks;
see `--help` for the full list.
If it validates, the tool automatically updates the documents to match
the LTAC input, e.g., it updates the graphics and the headings.

Database-based tools can make it easy to make specific changes "everywhere".
However, database-based tools are complex and requiring using that
specialized tool for almost all assurance case tasks.
Our goal is to get many of those benefits using a different and
simpler approach.

We achieve similar capabilities using a few simple options.
Normally the tool will only *read* the LTAC file, not modify it.
However, a few options will *update* the LTAC file.
The `--update` option updates the LTAC file so that all elements that cite an
element will have their statements updated to match the definition.
The option `--rename OLD NEW` let you rename IDs in
the LTAC and document files, while
`--restate LABEL STATEMENT` lets you change the statment of a given label
in the LTAC and document files.
This gives us many of the advantages of database-based approaches
(you can do one operation to change
certain values "everywhere"), while providing better transparency,
greater simplicity, and easier integration with AI and version control
of a text-based approach.

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
  be grouped into multiple packages (modules).
  Each package must have
  a single top claim and it must be hierarchically decomposed.
  We name the package after that top claim, and we also
  require that any claim only be defined in one package.
  However, a claim may be *referenced* in many packages, and "Links" allow
  references to an element already in use.
  These abilities mean that these restrictions aren't
  a serious problem in practice.
* We generate graphics automatically, and we currently
  use `mermaid` because it's
  directly support by GitHub's built-in markdown processor.
  Mermaid is quite limited in what it can do. This isn't too bad if you
  limit your packages to smaller numbers of elements, but it's definitely
  a limitation. You can have as many packages as you want; we suggest
  limiting package size. That's easier for humans to follow, too.
* This is not a database, it's a way to make it easier to manage documents.
  If you want a database, this tool
  isn't it. So if you are managing a large
  assurance case, this approach is probably less appealing.

## Other information

The specification of extended LTAC that we implement is in file
[docs/ltac-extended.txt](docs/ltac-extended.txt).
