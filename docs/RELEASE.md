# Release Process

This document describes the step-by-step process for publishing a new
release of `verocase` to PyPI.
We use the PyPI trusted publisher process, so we don't need to directly handle a
PyPI API token or password.

## Prerequisites

- You must have write access to the
  [verocase GitHub repository](https://github.com/david-a-wheeler/verocase).

## Step-by-step release

### 1. Update the version string

Edit `verocase.py` and update `__version__` near the top of the file
to a semantic versioning (SemVar) version identifier:

```python
__version__ = '1.2.3'   # use the new version number
```

[flit](https://flit.pypa.io/) reads this value directly as the package
version (via `dynamic = ["version"]` in `pyproject.toml`), so this location
is the single source of truth.

Verify the version is correct:

```sh
python3 verocase.py --version
```

### 2. Update CHANGELOG.md

Ask an AI assistant to summarize the changes since the last release and
draft the new CHANGELOG.md entry.  Then review and edit the result before
committing.

**Get the raw material for the AI:**

```sh
# Find the previous release tag
git tag --sort=-version:refname | head -5

# Show commits since that tag (replace v0.1.0 with the actual previous tag)
git log v0.1.0..HEAD --oneline

# Show the full diff if needed for detail
git diff v0.1.0..HEAD -- verocase.py
```

**Prompt to give the AI** (paste the `git log` output after it):

> I am preparing a release of the `verocase` command-line tool.
> Please draft a CHANGELOG.md entry for the new version following the
> [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.
> Use these section headings as applicable, in this order, omitting any
> that are empty: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`,
> `Security`.
>
> Guidelines:
> - Focus on user-visible changes; omit pure internal refactors unless
>   they affect behaviour or performance noticeably.
> - One bullet per logical change; do not repeat the same change under
>   multiple headings.
> - Write for a user reading the changelog, not a developer reading diffs;
>   describe *what changed and why it matters*, not how it was implemented.
> - For `--stats` output changes, describe the new fields shown.
> - For new validations or error messages, describe what is now checked
>   and what the user should do to fix it.
> - Start the entry with a heading in Keep a Changelog format, e.g.:
>   `## [1.2.3] - 2025-03-13`
>
> Here are the commits since the last release:
> (paste `git log` output here, and tell the AI the new version number and today's date)

**After the AI responds:**

1. Review every bullet for accuracy; the AI may misread commit messages.
2. Check that the existing `[Unreleased]` section (if any) is cleared out
   or promoted to the new version heading.
3. Make sure the comparison link at the bottom of the file is updated, e.g.:
   ```markdown
   [1.2.3]: https://github.com/david-a-wheeler/verocase/compare/v1.2.2...v1.2.3
   ```

### 3. Commit the version bump with CHANGELOG.md

```sh
VERSION=$(python3 verocase.py --version)
git add verocase.py CHANGELOG.md
git commit -m "Bump version to $VERSION"
```

### 4. Create and push a signed tag

Tag names must be prefixed with `v`.  Use `--version` to confirm the exact
string to embed:

```sh
VERSION=$(python3 verocase.py --version)
git tag -a "v${VERSION}" -m "Release v${VERSION}"
git push origin main "v${VERSION}"
```

### 5. Create a GitHub Release

1. Go to **Releases** on the GitHub repository page.
2. Click **Draft a new release**.
3. Choose the tag you just pushed (`v1.2.3`).
4. Set the release title to `v1.2.3` (or a short description).
5. Write release notes (new features, fixes, breaking changes).
6. Click **Publish release**.

Publishing the release triggers the `publish.yml` workflow automatically.

### 6. Approve the publish workflow (environment gate)

The `publish.yml` workflow runs in the `pypi` GitHub Actions environment,
which is configured to require a manual approval before deployment.

1. Go to **Actions** on the GitHub repository page.
2. Open the **Publish to PyPI** workflow run for your release.
3. Review and **Approve** the pending deployment to the `pypi` environment.

The workflow then builds the package and publishes it to PyPI without any
passwords or tokens; authentication is handled entirely by trusted publishing.

### 7. Verify the release

```sh
pip install --upgrade verocase
verocase --version
```

## Background information

### Trusted publishing

We use [PyPI Trusted Publishing](https://docs.pypi.org/trusted-publishers/)
(OIDC-based) rather than long-lived API tokens or passwords.

**Why this is better for security:**

- No secret credential is stored in GitHub (no `PYPI_API_TOKEN` secret to
  rotate, leak, or phish).
- The PyPI token is minted on demand for a single workflow run and expires
  immediately afterward.
- The grant is scoped to one specific workflow file in one specific repository,
  so a compromised fork or unrelated workflow cannot publish.
- Eliminates the entire class of "stolen API token" supply-chain attacks.

### Release configuration

The trusted publisher was registered on PyPI with these values:

| Field       | Value            |
|-------------|------------------|
| Owner       | `david-a-wheeler` |
| Repository  | `verocase`        |
| Workflow    | `publish.yml`     |
| Environment | `pypi`            |

See also:
- [PyPI Trusted Publishers documentation](https://docs.pypi.org/trusted-publishers/)
- [GitHub OIDC documentation](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/about-security-hardening-with-openid-connect)

### Reproducible builds

Our release builds are reproducible: building from the same source tree
always produces bit-for-bit identical wheel and sdist archives.

**How:** Python's `build` module and most archive tools embed the current
wall-clock time in archive metadata by default, which causes every build to
differ. We suppress this by setting the `SOURCE_DATE_EPOCH` environment
variable to the Unix timestamp of the last git commit before running
`python -m build`:

```yaml
- name: Set SOURCE_DATE_EPOCH
  run: echo "SOURCE_DATE_EPOCH=$(git log -1 --format=%ct)" >> $GITHUB_ENV

- name: Build package
  run: python -m build
```

`SOURCE_DATE_EPOCH` is the
[reproducible-builds standard](https://reproducible-builds.org/docs/source-date-epoch/)
for communicating a canonical timestamp to build tools. When set, `build`
(and the underlying flit backend) uses that timestamp for all file metadata
in the generated archives instead of the current time.

To reproduce a release locally:

```sh
export SOURCE_DATE_EPOCH=$(git log -1 --format=%ct)
python -m build
```

## See also

- [Reproducible Builds project](https://reproducible-builds.org/)
- [SOURCE_DATE_EPOCH specification](https://reproducible-builds.org/docs/source-date-epoch/)
- [Python packaging reproducibility](https://packaging.python.org/en/latest/guides/reproducible-builds/)
