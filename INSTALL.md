# Installing verocase

`verocase` is a single self-contained Python script with no third-party
dependencies, so it is easy to install in several ways.

## Recommended: pipx

[pipx](https://pipx.pypa.io/) installs command-line tools into isolated
virtual environments and puts them on your PATH automatically.
It is the cleanest option for developer tools like `verocase` and avoids
all of the permission and system-protection issues described below.

```sh
pipx install verocase
```

Install pipx itself with your system package manager if needed:

```sh
# Debian/Ubuntu
sudo apt install pipx && pipx ensurepath

# macOS (Homebrew)
brew install pipx && pipx ensurepath

# pip
pip install --user pipx && pipx ensurepath
```

## pip install

If you prefer plain pip:

```sh
pip install verocase            # system-wide (may need sudo or admin)
pip install --user verocase     # your home directory only; no sudo needed
```

On modern Linux distributions (Debian 12+, Ubuntu 23.04+, Fedora 38+,
and others) a plain `pip install` may print an error like:

```
error: externally-managed-environment
× This environment is externally managed
╰─> To install Python packages system-wide, ...
```

This is a deliberate protection (PEP 668) to prevent pip from overwriting
packages that the OS package manager owns.  You have four options:

### Option 1: use pipx (recommended)

See above.  Cleanest solution; no system risk.

### Option 2: install into your home directory

```sh
pip install --user verocase
```

This puts `verocase` under `~/.local/` and never touches system files.
Make sure `~/.local/bin` is on your PATH (most modern distros add it
automatically; if not, add `export PATH="$HOME/.local/bin:$PATH"` to your
shell profile).

### Option 3: use --break-system-packages

```sh
pip install --break-system-packages verocase
```

This flag tells pip to install into the system Python environment despite
the protection.  For `verocase` the practical risk is low — it has no
third-party dependencies, so there is nothing to conflict with system
packages — but be aware of the trade-off: if you later install other
packages with `--break-system-packages`, a version conflict with a
system-owned package could cause hard-to-diagnose breakage.

Good fits for this option:

- Your own laptop or workstation where you control the whole system.
- A container or CI environment that is thrown away after use.
- A virtual machine that is not shared with other users.

Avoid it on shared servers or anywhere the system Python is maintained
by someone else.

### Option 4: use a virtual environment

```sh
python3 -m venv ~/.venvs/verocase
~/.venvs/verocase/bin/pip install verocase
```

Then either call `~/.venvs/verocase/bin/verocase` directly, add
`~/.venvs/verocase/bin` to your PATH, or create a symlink in `~/bin/`.
(This is essentially what `pipx` does for you automatically — which is
why pipx is the recommended option.)

## Single-file installation

`verocase` is a single self-contained Python script with no dependencies.
You can copy `verocase.py` anywhere and run it directly without installing
anything:

```sh
# Copy to a directory on your PATH
cp verocase.py ~/bin/verocase
chmod +x ~/bin/verocase

# Run it
verocase --help
```

The file has a `#!/usr/bin/env python3` shebang, so on Linux and macOS
you can run it without the `python3` prefix as long as it is executable
and on your PATH.

This approach works well in CI pipelines, on systems where you cannot
install packages, or when you want to pin a specific version of the script.

## Verifying the installation

```sh
verocase --version
verocase --help
```

## Upgrading

```sh
pipx upgrade verocase                          # pipx
pip install --upgrade verocase                 # system-wide pip
pip install --user --upgrade verocase          # user pip
pip install --break-system-packages --upgrade verocase  # with override
```

## Requirements

- Python 3.8 or later.
- No third-party packages required.
  (TOML config file support requires Python 3.11+, or `pip install tomli`
  for older versions.)
