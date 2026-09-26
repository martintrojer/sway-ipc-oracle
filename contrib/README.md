# Contributor tools

This directory contains the repository's executable maintenance tools. `contrib/validate` checks this inventory, the result files, and the fixture schema.

| Script | Purpose and inputs or outputs | Who runs it | Why it remains separate |
|---|---|---|---|
| `check-sway-fixture-schema` | Compares the checked-in fixture fields with the serializer fields in the pinned sway checkout. It takes the checkout path and reports mismatches. | CI through `validate`; maintainers after updating sway fixtures | This source-level schema check needs a sway checkout. The scenario runner only observes IPC output. |
| `coverage-report` | Validates one `i3/results/<snapshot>.toml` file or prints its summary, gaps, or JSON representation. | CI through `validate`; contributors who classify i3 results | This is a read-only result validator. `i3-suite-run` executes compositors and rewrites result files. |
| `i3-suite-run` | Runs the unchanged vendored i3 suite against i3, sway, or swayward and writes `i3/results/<snapshot>.toml` (names from `pins.toml`). It also owns the TAP parser and its self-test. | Maintainers who refresh i3-suite evidence; CI runs only `--self-test` | It requires the i3 test harness and compositor adapters. The sway IPC runner uses data-driven Wayland scenarios instead. |
| `sway-ipc-run` | Runs, captures, or compares sway IPC scenarios. It reads scenario and normalization TOML and writes fixtures or result TOML. | Maintainers who refresh fixtures; contributors investigating protocol differences | It owns compositor lifecycle and raw sway IPC. The i3-suite runner owns the upstream Perl suite and TAP results. |
| `validate` | Runs all repository checks, self-tests, inventory checks, and the pinned sway schema comparison. Its `reproduce` mode regenerates result files inside the pinned container. | CI and contributors before pushing or refreshing evidence | This is the single check and reproduction entry point. Folding domain logic into it would duplicate the tools that contributors also run directly. |

`contrib/tests/` contains tests called only by `validate`; it is not part of the executable tool inventory. Python bytecode and other generated files do not belong in `contrib/`.
