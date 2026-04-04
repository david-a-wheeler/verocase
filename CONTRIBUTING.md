# CONTRIBUTING.md

We love contributions! Please do!

Contributors must agree to the [MIT license](LICENSE.md).

## Set up for development

Install some tools for development. Install Python3, then:

```bash
pip install flit
flit install --symlink
pipx install ruff
pipx install pyright
```

We use:

- `ruff` as a linter (to detect style issues and likely mistakes)
- `pyright` for type-checking
- `unittest` (Python built-in) for the test framework

## Development commands

You can run all checks with this (if you have make):

**Run all checks (lint + type check + tests):**
```bash
make verify
```

## Architecture

The entire implementation lives in a single file: `verocase.py`. This is intentional, because it keeps installation trivial. Users can copy that one file anywhere and use the tool, they don't *have* to use pip or pipx or whatever.

See the file [AGENTS.md](./AGENTS.md) for more about its architecture. We put the information there to ensure that AI agents will find it. The `--help-api` and `--help-api-details` options should also be helpful.

## Documentation

The `docs/` directory includes documentation.

The tool also has built-in help (`--help`, `--help-validations`, `--help-config`, `--help-api`, `--help-security`, etc.) implemented in `verocase.py`. Keep the built-in help up-to-date when the user interface changes; it lets users and AI quickly understand the tool without consulting a separate file.
