# caseproc

`caseproc` is a simple text-based tool to make it *easy* and *efficient*
to create and maintain a moderately-sized assurance case.

An assurance case is "a body of evidence organized into an argument demonstrating that some claim about a system holds (i.e., is assured). An assurance case is needed when it is important to show that a system exhibits some complex
property, such as safety, security, privacy, or reliability."
([NIST Special Publication 800-53A Revision 5](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-53Ar5.pdf)).

There are many notations for expressing and maintaining assurance cases.
Large assurance cases are often maintained using specialized tools that
manage databases of such information, and allow people to edit
diagrams that flexibly present the information graphically using
OMG SACM, GSN, or CAE. However, for smaller systems, it's hard to argue
for the use of such sophisticated tools for an assurance case.
The obvious alternative is to write an assurance as a traditional document.
However, traditional document don't provide any support for the
structure between the parts of an assurance case, requiring a lot of
extra work.

`caseproc` takes a different approach:
it's a simple Python3 script that processes our
extended version of the Lightweight Text Assurance Case (LTAC) format
to generate useful documentation.
This simple approach makes it easy create and maintain moderately-sized
assurance cases.

Currently it can generate SACM notation in mermaid format.
We eventually hope to support other notations, specifically GSN and CAE.
It can also generate a markdown indented bullet list that looks like LTAC
format but adds hyperlinks, making it easy to go from a high-level
summary to specific details and back.

Perhaps most usefully, it can process a markdown file and replace marked
sections with updated generated information. So you can simply run the
process with a sequence of markdown filenames, and it will update the
markdown with the latest LTAC information.

The specification of LTAC we implement is in file
[docs/ltac-extended.txt](docs/ltac-extended.txt).
