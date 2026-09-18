# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Detailed project knowledge lives in `.serena/memories/*.md` (read via Serena's `read_memory` or plain file reads). This file is the fast-path summary; the memories are authoritative. Key ones: `core`, `tech_stack`, `suggested_commands`, `conventions`, `task_completion`, `serena_repository_structure`, `adding_new_language_support_guide`, `memory_maintenance`.

## What this is

Serena is an MCP-based "IDE for coding agents": semantic code retrieval / editing / refactoring tools driven by language servers. Two cooperating components:

- **Serena Core** (`src/serena/`) — agent framework, MCP server, tools, project/config layer.
- **SolidLSP** (`src/solidlsp/`) — a unified LSP client wrapping many language servers (one per language under `language_servers/`).
- **interprompt** (`src/interprompt/`) — Jinja2 multi-language prompt-template library, synced from an external repo (see `.syncCommitId.*`).

PyPI package is `serena-agent`; import root is `serena`. Wheel ships `serena`, `interprompt`, `solidlsp`.

## Commands

Tasks run through **poethepoet**: `uv run poe <task>`. The poe executor is `simple`, so plain `poe <task>` works inside the venv without uv re-resolving (important: avoids env recreation while the MCP server is running).

- `poe test` — pytest on `test/`. Per-language LSP tests are **marker-gated** — pass `-m <lang>` (e.g. `-m python`, `-m typescript`) to enable them; default run executes unmarked tests only.
- `poe lint` — ruff format-check + ruff check (no fixes).
- `poe format` — ruff `--fix` then `ruff format` (mutates files).
- `poe type-check` — mypy strict on `src/serena`, `src/solidlsp`, `test/`.
- `poe doc-build` — sphinx docs (uses `rm -rf`; needs a unix-like shell).
- Single test: `uv run pytest test/path/to/test_x.py -vv` (add `-m <lang>` if the test is language-gated).

Entry points: `uv run serena ...` (CLI → `serena.cli:top_level`), `uv run serena-hooks ...` (→ `serena.hooks:hook_commands`).

Regenerate prompts after editing templates: `uv run python scripts/gen_prompt_factory.py` → rewrites `src/serena/generated/generated_prompt_factory.py`, then `poe format` and commit.

## After any change in `src/` or `test/`

1. `uv run poe format`
2. `uv run poe type-check`
3. `uv run poe test` (with the right `-m` markers for affected languages)

If memories were edited/renamed/split: `uv run serena memories check` (finds broken `mem:` references). If prompt templates changed: regenerate the prompt factory (above).

## Conventions that bite

- **mypy strict** — `disallow_untyped_defs`, `strict_optional`, `warn_unreachable`, `no_implicit_optional`. Test files relax only `disallow_untyped_defs`.
- **ruff**: line length 140, double quotes, target `py311`. Many rules are deliberately disabled in `[tool.ruff.lint] ignore` — check there before adding a workaround. Notably: prefer `Optional[T]` over `T | None`, `Union` allowed, **relative imports forbidden**, `%` string formatting allowed. mccabe complexity cap 20.
- **OO style**: explicitly typed abstractions (strategy pattern etc.) over bare callbacks; dataclasses over dicts/tuples for simple containers. Function bodies split into blank-line-separated blocks, each prefixed with a short lowercase elliptical phrase describing the block.
- **Docstrings: reStructuredText** (`:param x:`, `:return:`, `:raises X:`). Descriptions start with a precise elliptical phrase defining *what* the thing is.
- Snapshot tests use **syrupy** (custom `--snapshot-patch-pycharm-diff` plugin, auto-added via `addopts`).

## Dependency pinning (non-obvious)

Dependencies are **exact-pinned** in `pyproject.toml`, not loosely ranged — `uvx` installs Serena from git and **ignores `uv.lock`**, so the pins in `pyproject.toml` are the real version contract. Bump deliberately.

## Architecture map

`src/serena/`:
- `agent.py` — `SerenaAgent`, orchestrates everything. `mcp.py` — MCP server. `cli.py`, `hooks.py`, `project_server.py` — entrypoints/wiring.
- `tools/` — tool implementations (`symbol_tools`, `file_tools`, `memory_tools`, `config_tools`, `workflow_tools`, `query_project_tools`, `cmd_tools`, `jetbrains_tools`); `tools/tools_base.py` is the base class for all tools.
- `config/` — `serena_config.py`, `context_mode.py`, `client_setup.py`; context/mode definitions in `resources/config/contexts/*.yml` and `resources/config/modes/*.yml`.
- `code_editor.py`, `symbol.py`, `ls_manager.py` — symbolic editing + language-server lifecycle.
- `dashboard.py`, `gui_log_viewer.py` — Flask web dashboard / log viewer.
- `prompt_factory.py` + `generated/generated_prompt_factory.py` — prompts.

`src/solidlsp/`: `ls.py` (`SolidLanguageServer`, the core), `language_servers/<lang>_*.py` (one per server), `ls_config.py`, `ls_types.py`, `ls_utils.py`.

Tests: `test/serena/`, `test/solidlsp/<lang>/`; fixture projects in `test/resources/repos/<lang>/`. Shared fixtures in `test/conftest.py` (`create_ls()`, parametrized `language_server` fixture).

Adding a new language → follow `mem:adding_new_language_support_guide`.

## Fork awareness

This checkout is a fork of `oraios/serena` (see `FORK.md`), installed editable so edits are live. There is a custom patch on `main`: a one-line cross-file-indexing wait added to `request_rename_symbol_edit` in `src/solidlsp/ls.py` (fixes rename dropping barrel re-export specifiers). Preserve that line when rebasing on upstream. `upstream` remote tracks `oraios/serena`; `scripts/check-upstream.sh` notifies of new releases.
