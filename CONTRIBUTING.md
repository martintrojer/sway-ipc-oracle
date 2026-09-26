# Contributing to sway-ipc-oracle

This repository holds an oracle (i3's unchanged tests and captured sway IPC
replies) and snapshots: what each pinned compositor did when measured against
it. Everything below protects one property. Anyone can rebuild the container,
rerun a snapshot, and get the committed file back, give or take a timestamp.

Each rule exists because breaking it once produced numbers that looked fine and
were wrong.

## A snapshot is raw generator output

Result files under `i3/results/` and `sway-ipc/results/` are written by
`contrib/i3-suite-run` and `contrib/sway-ipc-run`, and by nothing else. Review
work lives beside them: reasons, citations and families go in
`i3/classifications/<snapshot>.toml`, keyed by file and assertion. Regenerating
a snapshot then never erases a review, and a review never changes a
measurement.

If validation fails, fix the generator, the adapter or the classification. The
measured counts stay as measured. An early version of this repository could not
reproduce its own results: some came from uncommitted builds, some had been
edited by hand, and the diff against a fresh run was 2,712 lines long.

## Measure only committed builds

`pins.toml` names the exact source revision of every compositor, and in `[snapshot]` the versioned name its result files use. The runners
refuse a build whose `git describe` ends in `-dirty` or `-modified`. To measure
a newer compositor, change its pin in one commit and regenerate its snapshot in
the same pull request.

## A broken harness fails the run

Before a full run, each Wayland compositor must pass a small set of canary
files that pass on every pinned compositor. After the run, a snapshot with too
many zero-pass files, or any adapter log containing `No such atom
(I3_SOCKET_PATH)` or `no free X11 display`, is rejected. This exists because a
container that could not give X11 clients a display once produced a swayward
snapshot of 446 passes where the real figure was over 1,400. Reproducible and
wrong is worse than irreproducible.

A canary that flakes is a harness bug to fix. It stays in the canary set.

## Every compositor gets the same rules

- **Flakiness.** A file is flaky under one rule for all compositors: the same
  number of runs, and the per-assertion outcomes recorded in
  `i3/flaky-runs.toml`. Flaky files stay visible, and the README gives totals
  with and without them. When one compositor's flaky list is much longer than
  another's, look for a synchronisation gap in its adapter first. Sway's list
  once went from 41 files to 8 after its adapter learned to wait for X11 focus
  to settle.
- **Adapter translations.** An adapter may translate a test's premise into the
  compositor's own configuration language, such as i3 config into KDL or i3's
  `fake-outputs` into headless outputs. It must translate the same premise for
  every compositor that can express it, list the rule in its README, and flag
  affected rows as `adapted`. It must never change what a test means. Rewriting
  X11 `class` criteria to Wayland `app_id` for one compositor made a real
  limitation look like a pass.
- **Skip families.** A skip claims the premise does not apply to that
  compositor, with a source citation. It is never applied to a compositor whose
  adapter translates that premise.

## Tolerances are scoped and evidenced

Every comparison exemption is a named rule in `sway-ipc/normalize.toml` with a
reason and measured evidence. `contrib/validate` rejects field exemptions
written into the runner itself. Scope a new rule to the fields and scenarios
that need it. A global rectangle tolerance was once widened from 10 to 70
pixels to absorb one font difference. The fix was to make the fonts agree.

## One compositor per file

A results file describes one compositor at one version, relative to the
oracle. Comparisons between compositors, findings lists and triage of one
compositor against another belong to those projects, not here. A difference
between sway and i3 that looks like a sway bug goes on a list offered to the
sway maintainers, never into a ranking.

## Running things

- Long runs go in the background with a log, and you poll in minutes. A
  one-hour tool call that times out loses the run.
- Scratch output, clones and build directories go on disk, never in `/tmp`,
  which is often RAM.
- Use a private socket and a memory cap for every nested compositor. Keep the
  operator's session out of reach.
- `./contrib/validate` passes before every push.
