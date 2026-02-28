# ltacproc

The script `ltacproc` is a Python3 script for processing
our extended version of Lightweight Text Assurance Case (LTAC) format
and generating useful results to enable easy documentation and revision
of assurance cases.

The script `ltacproc` can take information in LTAC format and:
generate SACM notation in mermaid diagram format.
We eventually hope to support other notations (like GSN and CAE)
and other diagram formats.
It can also generate a markdown indented bullet list that looks like LTAC
format but adds hyperlinks.

Perhaps most usefully, it can process a markdown file and replace marked
sections with updated generated information. So you can simply run the
process with a sequence of markdown filenames, and it will update the
markdown with the latest LTAC information.

The specification of LTAC we implement is in file
[docs/ltac-extended.txt](docs/ltac-extended.txt).

(We haven't actually implemented `ltacproc`; the text above is
written to describe what we *intend* to create).
