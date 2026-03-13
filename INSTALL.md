# Installing verocase

## Recommended: install with pip

```sh
pip install verocase
```

If you get a permissions error, install into your home directory instead:

```sh
pip install --user verocase
```

Or use [pipx](https://pipx.pypa.io/), which installs command-line tools into
isolated environments and puts them on your PATH automatically; a good
choice for tools like verocase:

```sh
pipx install verocase
```

This installs the `verocase` command so you can run it from anywhere.
You can verify that it works, and see some information about it, by running:

```sh
verocase --help
```

To upgrade to the latest release:

```sh
pip install --upgrade verocase       # system-wide
pip install --user --upgrade verocase  # user install
pipx upgrade verocase                  # pipx install
```

## Single-file installation

`verocase` is intentionally designed as a single self-contained Python script
with no dependencies beyond the Python standard library.  You can copy
`verocase.py` anywhere and run it directly:

```sh
# Copy the file
cp verocase.py ~/bin/verocase

# Run it
python3 ~/bin/verocase --help
```

On Linux and macOS the file already has its executable bit set and a
`#!/usr/bin/env python3` shebang line, so you can run it without the
`python3` prefix if it is on your `PATH`:

```sh
verocase --help
```

## Requirements

- Python 3.8 or later.
- No third-party packages required.
