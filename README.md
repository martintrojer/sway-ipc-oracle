# sway-ipc-oracle

Conformance tests for compositors that speak the i3/sway IPC protocol. This is not a client library.

The repository came out of [swayward](https://github.com/martintrojer/swayward), which is its first adopter. The first import is from swayward commit [`4faeb28d`](https://github.com/martintrojer/swayward/commit/4faeb28d391c8ede3ead6f9b7cbe4388422d3887).

## The two oracles

The repository keeps two independent reference sets:

- `i3/t/` contains unchanged tests from i3 commit `9be3249ac5b377ed3270e36bca83df53d8023337`. Michael Stapelberg and the i3 contributors wrote and maintain the original suite. Their BSD-3-Clause notice remains in [`i3/LICENSE`](i3/LICENSE).
- `sway-ipc/fixtures/` contains IPC replies and event sequences captured from sway 1.12 at commit `88869399f421d9180dd8b6ed0b5a1f4a3585d252`.

Never edit a test or fixture to make a compositor pass. Update an oracle only from its upstream source or by recapturing it from the pinned compositor. An adapter may establish a platform-specific premise, but it must not change an assertion or the value observed over IPC.

## Results are measurements

Each oracle records measurements under `<oracle>/results/<compositor>.toml`. The oracle comes first and the compositor under test comes second: for example, `i3/results/sway.toml` means “the i3 suite run on sway.”

A result must publish pass, skip, and fail counts together for each compositor. Do not quote one count by itself or combine the counts into a score.

A skip needs a reason and a source citation. In particular, sway deliberately differs from i3 where the X11 premise or design does not apply. Those rows describe where sway differs from i3. They do not imply a defect or a quality comparison.

The repository includes pinned black-box measurements for i3, sway, and
swayward. These are raw observations. Unclassified failures and assertions that
the harness did not reach remain visible rather than being converted to skips.
Parser-internal tests that execute i3's build-only helper binaries are classified
as not applicable to other compositors rather than treated as protocol failures.

## Run the i3 suite

Build the pinned i3 and compositor revisions, then run one command per result:

```sh
./contrib/i3-suite-run --compositor i3
./contrib/i3-suite-run --compositor sway --binary /path/to/pinned/sway
./contrib/i3-suite-run --compositor swayward --binary /path/to/pinned/swayward
```

The i3 adapter delegates to upstream `complete-run.pl` on Xvfb. The sway and
swayward adapters run each unchanged test against a headless compositor with a
private IPC socket and private X11 socket directory. Sway owns Xwayland;
swayward uses xwayland-satellite. Every compositor run has a 2 GiB memory cap,
no swap, and a wall-time limit. See [`i3/adapters/`](i3/adapters/) for the
adapter boundaries.

## Run the sway IPC scenarios

`contrib/sway-ipc-run` uses only Python's standard library. It starts sway or
swayward under a 2 GiB, zero-swap systemd scope with a wall-time limit and
private IPC and Wayland sockets. It opens standalone `foot` clients and never
uses the ambient `SWAYSOCK`, `I3SOCK`, `WAYLAND_DISPLAY`, or `DISPLAY`.

```sh
./contrib/sway-ipc-run --compositor sway --binary /path/to/sway \
  --out sway-ipc/results/sway.toml
./contrib/sway-ipc-run --compositor swayward --binary /path/to/swayward \
  --out sway-ipc/results/swayward.toml
```

Recipes live in `sway-ipc/scenarios.toml`; comparison rules and their reasons
live in `sway-ipc/normalize.toml`. `sway-ipc/applicability.toml` limits i3
comparisons to the fields in i3's pinned IPC protocol and cites sway's source
for excluded sway extensions. Every sway field remains applicable to swayward.
Use repeated `--scenario NAME` arguments for a subset. The runner starts a
fresh compositor for each recipe so runtime commands cannot leak into later
measurements. The pinned swayward run records **90 match / 0 mismatch / 3 not
applicable**. Use `--no-fresh-per-scenario` only when investigating sequential
state. `--capture` is
restricted to sway and replaces the selected query fixtures after running the
same comparisons. The i3 adapter runs i3 under private Xvfb and opens xterm
clients; both programs must be installed beside the runner.

### States derived from i3's test suite

The optional calibration recorder logs replayable IPC commands and ordinary
mapped windows while i3's unchanged `.t` files run against sway. It records the
source file and line for each operation. Capture mode replays those logs through
the same isolated sway adapter, hashes a normalized tree shape after every
operation, and keeps one scenario per distinct shape. The committed fixtures
are therefore states reached by i3's own tests, captured from sway 1.12; they
are not hand-authored approximations.

```sh
./contrib/i3-suite-run --compositor sway --record-commands \
  --binary /path/to/pinned/sway
./contrib/sway-ipc-run i3-derived --compositor sway \
  --binary /path/to/pinned/sway --command-logs target/i3-suite/sway --capture
./contrib/sway-ipc-run i3-derived --compositor swayward \
  --binary /path/to/swayward
```

`sway-ipc/i3-derived/scenarios.json` is the compact replay and provenance
manifest. Each hash-named JSON file contains sway's raw tree, workspace, and
output replies for one distinct normalized shape. Commands tied to X11 window
IDs, compositor process lifecycle, or spawned programs are stopped and listed
with a reason rather than translated silently. Capture remains restricted to
real sway.

### Differential mode

Differential mode generates seeded sway command strings, runs each command on
fresh sway and target compositor instances, then compares the command reply,
`GET_TREE`, and `GET_WORKSPACES` after every step through `normalize.toml`.
It delta-debugs the first mismatch to a minimal reproducer and groups identical
reproducers in `sway-ipc/results/differential-swayward.toml`.

```sh
./contrib/sway-ipc-run differential \
  --a sway --a-binary /path/to/sway \
  --b swayward --b-binary /path/to/swayward \
  --seed 0 --seeds 5 --steps 10
```

The defaults (`--seed 0 --seeds 5 --steps 10`) are the fixed-seed CI budget;
a local campaign can use, for example, `--seeds 200 --steps 30`. Add
`--save-scenarios` only after triage: it appends each minimized reproducer to
`scenarios.toml` and writes live sway snapshots from that differential run.
Then recapture the saved scenario with the ordinary `--capture` mode so its
permanent fixtures use the pinned fixture geometry. Never hand-edit those
fixtures. Every mismatch remains `untriaged` until classified as a compositor bug, a
source-cited documented deviation, or a harness issue.

## Adopt the oracle in another compositor

The oracle's runners contain adapters that start isolated i3, sway, and swayward instances, open real client windows, and connect through private IPC sockets. A compositor can also keep an in-process harness in its own repository. Swayward's [`tests/i3/lib/i3test.pm`](https://github.com/martintrojer/swayward/blob/4faeb28d391c8ede3ead6f9b7cbe4388422d3887/tests/i3/lib/i3test.pm) is one such harness, but this repository does not publish its numbers as black-box oracle measurements.

Publish black-box results from the oracle's runners under the matching oracle's `results/` directory. Publish every verdict count together, pin the compositor and oracle versions, and cite every deliberate difference.

## i3 suite comparison

These are measurements, not scores. Each cell is pass/skip/fail; “fail” includes assertions the run did not reach. The shared `headless_xtest_boundary` family marks those assertions as not measured by the harness, not as compositor behavior. The pinned runs record i3 **3,754/1/0**, sway **1,546/134/801**, and swayward **1,427/809/1,075**. All sway failures now carry a verified family classification. `contrib/validate` checks these hand-written summary figures, every table row, and matching boundary-family verdicts across the Wayland compositors against the TOML files.

| File | i3 P/S/F | sway P/S/F | swayward P/S/F |
| --- | ---: | ---: | ---: |
| `001-tile.t` | 3/0/0 | 2/0/1 | 3/0/0 |
| `003-ipc.t` | 1/0/0 | 1/0/0 | 1/0/0 |
| `005-floating.t` | 13/0/0 | 11/0/2 | 6/0/7 |
| `100-fullscreen.t` | 79/0/0 | 16/0/7 | 21/56/2 |
| `101-focus.t` | 8/0/0 | 8/0/0 | 4/0/4 |
| `102-dock.t` | 23/0/0 | 5/0/18 | 1/0/0 |
| `104-focus-stack.t` | 2/0/0 | 2/0/0 | 2/0/0 |
| `111-goto.t` | 13/0/0 | 13/0/0 | 11/0/2 |
| `112-floating-resize.t` | 15/0/0 | 15/0/0 | 15/0/0 |
| `113-urgent.t` | 64/0/0 | 21/0/2 | 18/15/0 |
| `115-ipc-workspaces.t` | 9/0/0 | 9/0/0 | 4/0/5 |
| `116-nestedcons.t` | 7/0/0 | 4/1/0 | 4/1/0 |
| `117-workspace.t` | 92/0/0 | 34/0/16 | 37/0/13 |
| `118-openkill.t` | 6/0/0 | 2/0/4 | 2/4/0 |
| `119-match.t` | 27/0/0 | 4/0/0 | 4/23/0 |
| `120-multiple-cmds.t` | 31/0/0 | 17/0/14 | 1/30/0 |
| `121-next-prev.t` | 12/0/0 | 9/0/3 | 12/0/0 |
| `122-split.t` | 41/0/0 | 16/15/0 | 41/0/0 |
| `124-move.t` | 54/0/0 | 37/0/17 | 38/0/16 |
| `126-regress-close.t` | 1/0/0 | 1/0/0 | 0/1/0 |
| `127-regress-floating-parent.t` | 4/0/0 | 4/0/0 | 1/3/0 |
| `128-open-order.t` | 7/0/0 | 3/0/4 | 2/0/5 |
| `129-focus-after-close.t` | 15/0/0 | 8/4/0 | 8/3/4 |
| `130-close-empty-split.t` | 8/0/0 | 2/0/6 | 2/0/6 |
| `131-stacking-order.t` | 7/0/0 | 6/0/1 | 6/0/1 |
| `132-move-workspace.t` | 160/0/0 | 61/9/30 | 131/6/23 |
| `133-size-hints.t` | 16/0/0 | 9/0/7 | 0/0/16 |
| `134-invalid-command.t` | 1/0/0 | 1/0/0 | 1/0/0 |
| `135-floating-focus.t` | 82/0/0 | 4/0/0 | 3/0/1 |
| `136-floating-ws-empty.t` | 11/0/0 | 11/0/0 | 11/0/0 |
| `137-floating-unmap.t` | 2/0/0 | 1/0/1 | 1/0/1 |
| `138-floating-attach.t` | 11/0/0 | 8/0/3 | 6/0/5 |
| `139-ws-numbers.t` | 8/0/0 | 8/0/0 | 8/0/0 |
| `140-focus-lost.t` | 3/0/0 | 3/0/0 | 3/0/0 |
| `141-resize.t` | 84/0/0 | 60/0/24 | 61/0/23 |
| `142-regress-move-floating.t` | 1/0/0 | 1/0/0 | 1/0/0 |
| `143-regress-floating-restart.t` | 5/0/0 | 3/0/2 | 5/0/0 |
| `144-regress-floating-resize.t` | 1/0/0 | 0/0/0 | 0/1/0 |
| `145-flattening.t` | 8/0/0 | 8/0/0 | 8/0/0 |
| `146-floating-reinsert.t` | 3/0/0 | 3/0/0 | 1/0/2 |
| `147-regress-floatingmove.t` | 2/0/0 | 2/0/0 | 2/0/0 |
| `148-regress-floatingmovews.t` | 1/0/0 | 1/0/0 | 1/0/0 |
| `150-regress-dock-restart.t` | 11/0/0 | 3/0/8 | 1/0/0 |
| `151-regress-float-size.t` | 1/0/0 | 1/0/0 | 1/0/0 |
| `152-regress-level-up.t` | 1/0/0 | 1/0/0 | 1/0/0 |
| `153-floating-originalsize.t` | 7/0/0 | 7/0/0 | 5/0/2 |
| `154-regress-multiple-dock.t` | 2/0/0 | 2/0/0 | 1/0/0 |
| `155-floating-split-size.t` | 4/0/0 | 2/0/2 | 2/0/2 |
| `156-fullscreen-focus.t` | 64/0/0 | 1/0/1 | 2/62/0 |
| `159-socketpaths.t` | 8/0/0 | 0/0/0 | 0/0/8 |
| `161-regress-borders-restart.t` | 4/0/0 | 2/2/0 | 1/2/1 |
| `162-regress-dock-urgent.t` | 4/0/0 | 2/0/2 | 1/0/0 |
| `164-kill-win-vs-client.t` | 12/0/0 | 3/0/0 | 3/9/0 |
| `165-for_window.t` | 79/0/0 | 19/0/0 | 17/60/2 |
| `166-assign.t` | 106/0/0 | 17/0/6 | 23/71/12 |
| `167-workspace_layout.t` | 87/0/0 | 9/19/0 | 45/19/23 |
| `168-regress-fullscreen-restart.t` | 1/0/0 | 1/0/0 | 1/0/0 |
| `169-border-toggle.t` | 20/0/0 | 0/20/0 | 15/5/0 |
| `170-force_focus_wrapping.t` | 12/0/0 | 12/0/0 | 12/0/0 |
| `172-start-on-named-ws.t` | 7/0/0 | 6/0/1 | 7/0/0 |
| `173-get-marks.t` | 3/0/0 | 2/0/1 | 2/1/0 |
| `174-border-config.t` | 13/0/0 | 9/3/1 | 9/1/3 |
| `176-workspace-baf.t` | 26/0/0 | 21/0/2 | 17/3/6 |
| `177-bar-config.t` | 50/0/0 | 23/0/5 | 1/0/1 |
| `178-regress-workspace-open.t` | 1/0/0 | 1/0/0 | 1/0/0 |
| `179-regress-multiple-ws.t` | 6/0/0 | 1/2/3 | 2/1/3 |
| `180-fd-leaks.t` | 1/0/0 | 1/0/0 | 1/0/0 |
| `181-regress-float-border.t` | 6/0/0 | 4/0/2 | 2/0/4 |
| `182-regress-focus-dock.t` | 1/0/0 | 1/0/0 | 0/0/1 |
| `183-config-variables.t` | 9/0/0 | 9/0/0 | 9/0/0 |
| `184-regress-float-split-resize.t` | 1/0/0 | 1/0/0 | 1/0/0 |
| `185-scratchpad.t` | 100/0/0 | 2/0/0 | 2/0/0 |
| `186-regress-assign-focus-parent.t` | 8/0/0 | 8/0/0 | 8/0/0 |
| `187-commands-parser.t` | 25/0/0 | 0/25/0 | 0/25/0 |
| `188-regress-focus-restart.t` | 11/0/0 | 11/0/0 | 11/0/0 |
| `189-floating-constraints.t` | 28/0/0 | 22/0/6 | 12/0/16 |
| `190-scratchpad-diff-ws.t` | 3/0/0 | 3/0/0 | 2/0/1 |
| `191-resize-levels.t` | 3/0/0 | 1/0/2 | 0/0/3 |
| `192-layout.t` | 34/0/0 | 22/0/12 | 34/0/0 |
| `193-ipc-version.t` | 4/0/0 | 3/0/1 | 3/0/1 |
| `194-regress-floating-size.t` | 15/0/0 | 15/0/0 | 5/0/10 |
| `196-randr-output-names.t` | 1/0/0 | 1/0/0 | 1/0/0 |
| `197-regression-move-vanish.t` | 4/0/0 | 4/0/0 | 4/0/0 |
| `198-regression-scratchpad-crash.t` | 1/0/0 | 1/0/0 | 1/0/0 |
| `199-ipc-mode-event.t` | 2/0/0 | 2/0/0 | 1/0/1 |
| `200-urgency-timer.t` | 12/0/0 | 12/0/0 | 8/0/4 |
| `201-config-parser.t` | 32/0/0 | 0/0/32 | 0/32/0 |
| `202-scratchpad-criteria.t` | 27/0/0 | 8/0/3 | 11/0/0 |
| `203-regress-assign-and-move.t` | 2/0/0 | 2/0/0 | 2/0/0 |
| `204-regress-scratchpad-move.t` | 1/0/0 | 1/0/0 | 1/0/0 |
| `205-ipc-windows.t` | 4/0/0 | 2/0/2 | 3/0/1 |
| `206-fullscreen-scratchpad.t` | 8/0/0 | 4/0/0 | 4/4/0 |
| `208-regress-floating-criteria.t` | 1/0/0 | 1/0/0 | 1/0/0 |
| `210-mark-unmark.t` | 17/0/0 | 14/0/3 | 7/0/10 |
| `211-regress-urgency-assign.t` | 3/0/0 | 2/0/1 | 1/1/0 |
| `212-assign-urgency.t` | 3/0/0 | 2/0/1 | 0/0/3 |
| `213-layout-restore-simple.t` | 18/0/0 | 8/10/0 | 8/10/0 |
| `218-regress-floating-split.t` | 2/0/0 | 2/0/0 | 2/0/0 |
| `219-ipc-window-focus.t` | 10/0/0 | 2/0/6 | 1/0/9 |
| `220-ipc-window-title.t` | 4/0/0 | 4/0/0 | 3/0/1 |
| `221-floating-type-hints.t` | 8/0/0 | 0/0/8 | 0/0/2 |
| `222-regress-dock-resize.t` | 1/0/0 | 1/0/0 | 0/0/1 |
| `224-regress-resize-branch.t` | 1/0/0 | 1/0/0 | 1/0/0 |
| `225-ipc-window-fullscreen.t` | 2/0/0 | 2/0/0 | 0/0/2 |
| `226-internal-workspaces.t` | 5/0/0 | 1/0/4 | 1/0/4 |
| `227-ipc-workspace-empty.t` | 3/0/0 | 0/0/1 | 0/0/3 |
| `228-border-widths.t` | 21/0/0 | 18/0/3 | 6/15/0 |
| `231-ipc-floating-event.t` | 2/0/0 | 1/0/1 | 0/0/2 |
| `232-cmd-move-criteria.t` | 22/0/0 | 22/0/0 | 6/0/6 |
| `233-regress-manage-focus-unmapped.t` | 2/0/0 | 1/0/0 | 0/0/2 |
| `235-check-config-no-x.t` | 8/0/0 | 0/0/8 | 0/0/8 |
| `236-floating-focus-raise.t` | 6/0/0 | 0/0/6 | 0/0/6 |
| `237-regress-assign-focus.t` | 1/0/0 | 1/0/0 | 1/0/0 |
| `238-ipc-binding-event.t` | 15/0/0 | 2/0/13 | 2/0/13 |
| `240-focus-on-window-activation.t` | 15/0/0 | 15/0/0 | 10/0/5 |
| `241-consistent-center.t` | 12/0/0 | 5/0/7 | 10/0/2 |
| `242-no-focus.t` | 6/0/0 | 6/0/0 | 3/0/3 |
| `243-move-to-mark.t` | 50/0/0 | 41/0/9 | 3/8/0 |
| `244-new-workspace-floating-enable-center.t` | 2/0/0 | 0/0/2 | 2/0/0 |
| `245-move-position-mouse.t` | 8/0/0 | 0/0/8 | 0/0/8 |
| `246-window-decoration-focus.t` | 3/0/0 | 2/0/1 | 3/0/0 |
| `247-config-line-continuation.t` | 8/0/0 | 4/0/4 | 7/0/1 |
| `248-regress-urgency-clear.t` | 4/0/0 | 4/0/0 | 4/0/0 |
| `251-command-criteria-focused.t` | 11/0/0 | 11/0/0 | 4/0/2 |
| `252-floating-size.t` | 49/0/0 | 40/0/9 | 31/0/18 |
| `254-move-to-output-with-criteria.t` | 16/0/0 | 3/6/7 | 10/0/6 |
| `255-multiple-marks.t` | 9/0/0 | 9/0/0 | 3/0/6 |
| `256-no-auto-back-and-forth.t` | 10/0/0 | 8/0/0 | 8/2/0 |
| `257-keypress-group1-fallback.t` | 17/0/0 | 1/0/0 | 1/0/16 |
| `258-keypress-release.t` | 49/0/0 | 1/0/0 | 1/0/48 |
| `260-invalid-criteria.t` | 2/0/0 | 1/0/1 | 1/0/1 |
| `261-match-con_id-con_mark-combinations.t` | 4/0/0 | 1/0/0 | 2/0/2 |
| `262-config-validation.t` | 2/0/0 | 1/0/0 | 1/0/0 |
| `263-config-reload-reverts-bind-mode.t` | 3/0/0 | 1/0/2 | 2/0/1 |
| `264-dock-criteria.t` | 19/0/0 | 0/0/0 | 0/0/19 |
| `265-ipc-mark.t` | 2/0/0 | 1/0/1 | 0/0/2 |
| `266-net-moveresize-window.t` | 12/0/0 | 0/0/0 | 0/0/12 |
| `267-regress-mark-restart.t` | 1/0/0 | 1/0/0 | 1/0/0 |
| `268-ipc-config.t` | 2/0/0 | 1/1/0 | 1/1/0 |
| `269-focus-stack-above.t` | 5/0/0 | 3/0/2 | 3/0/2 |
| `270-config-no-newline-end.t` | 2/0/0 | 2/0/0 | 2/0/0 |
| `271-for_window_tilingfloating.t` | 20/0/0 | 11/0/9 | 0/0/20 |
| `272-regress-focus-assign.t` | 8/0/0 | 8/0/0 | 2/0/1 |
| `273-regress-focus-toggle.t` | 1/0/0 | 1/0/0 | 1/0/0 |
| `274-move-branch-position.t` | 16/0/0 | 12/0/4 | 16/0/0 |
| `275-ipc-window-close.t` | 3/0/0 | 3/0/0 | 1/0/2 |
| `276-ipc-window-move.t` | 2/0/0 | 2/0/0 | 0/0/2 |
| `277-ipc-window-urgent.t` | 2/0/0 | 2/0/0 | 0/0/2 |
| `279-regress-default-floating-border.t` | 1/0/0 | 0/0/1 | 0/0/1 |
| `280-wm-class-change-handler.t` | 4/0/0 | 3/0/0 | 0/0/4 |
| `281-regress-reload-bindsym.t` | 1/0/0 | 1/0/0 | 1/0/0 |
| `282-tabbed-floating-disable-crash.t` | 1/0/0 | 1/0/0 | 1/0/0 |
| `284-ewmh-visible-name.t` | 5/0/0 | 0/0/0 | 0/0/5 |
| `285-sticky.t` | 11/0/0 | 2/0/0 | 2/9/0 |
| `286-root-window-mouse-binding.t` | 2/0/0 | 1/0/0 | 1/0/0 |
| `287-edge-borders.t` | 31/0/0 | 29/0/2 | 22/9/0 |
| `289-ipc-shutdown-event.t` | 4/0/0 | 0/0/0 | 0/0/4 |
| `290-keypress-numlock.t` | 85/0/0 | 25/0/60 | 1/0/84 |
| `291-swap.t` | 148/0/0 | 1/0/0 | 1/147/0 |
| `292-regress-layout-toggle.t` | 1/0/0 | 1/0/0 | 1/0/0 |
| `293-focus-follows-mouse.t` | 10/0/0 | 4/0/6 | 4/0/6 |
| `293-sticky-output-crash.t` | 3/0/0 | 2/0/1 | 3/0/0 |
| `294-focus-order.t` | 61/0/0 | 1/0/0 | 0/60/1 |
| `295-net-wm-state-focused.t` | 5/0/0 | 3/0/0 | 1/2/2 |
| `296-regress-focus-behind-fullscreen-floating.t` | 1/0/0 | 1/0/0 | 1/0/0 |
| `297-assign-workspace-to-output.t` | 25/0/0 | 13/0/12 | 5/0/20 |
| `297-scroll-tabbed.t` | 16/0/0 | 1/0/0 | 1/0/15 |
| `298-ipc-misbehaving-connection.t` | 2/0/0 | 1/0/1 | 1/0/1 |
| `299-regress-scratchpad-focus.t` | 1/0/0 | 1/0/0 | 1/0/0 |
| `301-shape.t` | 4/0/0 | 1/0/1 | 1/2/1 |
| `302-tree.t` | 15/0/0 | 0/0/0 | 0/0/15 |
| `303-regress-move-floating.t` | 3/0/0 | 1/0/2 | 3/0/0 |
| `304-ipc-workspace-init.t` | 9/0/0 | 1/0/8 | 0/0/9 |
| `306-move-to-parent.t` | 2/0/0 | 0/0/0 | 0/0/2 |
| `307-focus-next-prev.t` | 9/0/0 | 0/0/0 | 0/0/9 |
| `308-focus_wrapping.t` | 32/0/0 | 0/0/32 | 0/0/32 |
| `309-crash-move-parent.t` | 2/0/0 | 0/0/0 | 0/0/2 |
| `310-client-message-sticky.t` | 6/0/0 | 1/0/0 | 1/0/0 |
| `311-get-binding-modes.t` | 2/0/0 | 2/0/0 | 2/0/0 |
| `312-regress-layout-default.t` | 0/0/0 | 0/0/0 | 0/0/0 |
| `313-include.t` | 29/1/0 | 22/8/0 | 21/8/1 |
| `315-all-criterion.t` | 18/0/0 | 2/0/0 | 2/16/0 |
| `315-long-commands.t` | 4/0/0 | 3/0/1 | 3/0/1 |
| `316-drag-container.t` | 18/0/0 | 1/0/0 | 1/0/17 |
| `316-transient-for-loop.t` | 1/0/0 | 1/0/0 | 1/0/0 |
| `317-bar-config-font-fallback.t` | 1/0/0 | 0/0/0 | 0/0/1 |
| `317-bar-config-font-order.t` | 1/0/0 | 0/0/0 | 0/0/1 |
| `317-bar-output-trailing-space.t` | 4/0/0 | 4/0/0 | 0/0/1 |
| `319-gaps.t` | 28/0/0 | 2/0/16 | 1/0/17 |
| `320-mouse-bindings.t` | 14/0/0 | 3/0/0 | 3/0/11 |
| `321-crash-criteria-scratchpad.t` | 6/0/0 | 4/2/0 | 1/2/3 |
| `322-match-error-crash.t` | 2/0/0 | 2/0/0 | 2/0/0 |
| `324-for-window-reload-crash.t` | 1/0/0 | 1/0/0 | 1/0/0 |
| `325-layout-percent-and-marks.t` | 8/0/0 | 2/1/0 | 2/1/0 |
| `500-multi-monitor.t` | 1/0/0 | 0/0/1 | 1/0/0 |
| `501-scratchpad.t` | 44/0/0 | 44/0/0 | 44/0/0 |
| `502-focus-output.t` | 19/0/0 | 19/0/0 | 19/0/0 |
| `503-workspace.t` | 18/0/0 | 3/0/15 | 0/0/18 |
| `504-move-workspace-to-output.t` | 31/0/0 | 8/0/23 | 24/0/7 |
| `505-scratchpad-resolution.t` | 90/0/0 | 45/0/0 | 45/45/0 |
| `506-focus-right.t` | 31/0/0 | 28/0/3 | 28/0/3 |
| `507-workspace-move-crash.t` | 2/0/0 | 2/0/0 | 1/0/1 |
| `509-workspace_layout.t` | 2/0/0 | 1/0/1 | 0/0/2 |
| `510-focus-across-outputs.t` | 19/0/0 | 2/0/8 | 2/9/8 |
| `511-scratchpad-configure-request.t` | 2/0/0 | 2/0/0 | 2/0/0 |
| `512-move-wraps.t` | 10/0/0 | 6/2/2 | 10/0/0 |
| `513-move-workspace.t` | 6/0/0 | 2/0/4 | 2/0/4 |
| `514-ipc-workspace-multi-monitor.t` | 4/0/0 | 3/0/1 | 1/0/3 |
| `515-create-workspace.t` | 2/0/0 | 2/0/0 | 2/0/0 |
| `516-move.t` | 14/0/0 | 9/0/3 | 6/2/6 |
| `517-regress-move-direction-ipc.t` | 2/0/0 | 0/0/2 | 0/0/2 |
| `518-interpret-workspace-numbers.t` | 4/0/0 | 3/0/1 | 0/0/4 |
| `519-mouse-warping.t` | 3/0/0 | 1/0/2 | 0/0/3 |
| `520-regress-focus-direction-floating.t` | 1/0/0 | 0/0/1 | 1/0/0 |
| `522-rename-assigned-workspace.t` | 9/0/0 | 3/0/4 | 1/2/6 |
| `523-move-position-center.t` | 4/0/0 | 4/0/0 | 2/0/2 |
| `524-move.t` | 38/0/0 | 36/0/2 | 26/0/12 |
| `526-reconfigure-dock.t` | 3/0/0 | 0/0/3 | 0/0/3 |
| `527-focus-fallback.t` | 2/0/0 | 1/0/0 | 1/1/0 |
| `528-workspace-next-prev-reversed.t` | 38/0/0 | 3/0/35 | 0/0/38 |
| `530-bug-2229.t` | 1/0/0 | 1/0/0 | 1/0/0 |
| `531-fullscreen-on-given-output.t` | 4/0/0 | 3/0/1 | 0/0/4 |
| `534-dont-warp.t` | 2/0/0 | 2/0/0 | 2/0/0 |
| `535-workspace-next-prev.t` | 38/0/0 | 3/0/35 | 0/0/38 |
| `537-move-single-to-output.t` | 8/0/0 | 8/0/0 | 8/0/0 |
| `538-i3bar-primary-output.t` | 4/0/0 | 0/0/4 | 0/0/4 |
| `539-disable_focus_wrapping.t` | 10/0/0 | 10/0/0 | 10/0/0 |
| `540-sigterm-cleanup.t` | 2/0/0 | 2/0/0 | 2/0/0 |
| `541-resize-set-tiling.t` | 32/0/0 | 20/0/12 | 30/0/2 |
| `543-move-workspace-to-multiple-outputs.t` | 63/0/0 | 14/0/49 | 1/0/62 |
| `544-focus-multiple-outputs.t` | 41/0/0 | 8/0/33 | 8/0/33 |
| `545-i3-registration.t` | 1/0/0 | 1/0/0 | 1/0/0 |
| `546-empty-bindcommand.t` | 1/0/0 | 1/0/0 | 1/0/0 |
| `547-explicit-mode-default.t` | 1/0/0 | 1/0/0 | 1/0/0 |
| `547-nested-variables.t` | 2/0/0 | 2/0/0 | 2/0/0 |
| `549-focus-wrapping-gaps.t` | 2/0/0 | 2/0/0 | 2/0/0 |
| `550-focus-workspace.t` | 17/0/0 | 5/3/0 | 0/9/8 |
| `550-split-redundant-containers.t` | 8/0/0 | 0/0/0 | 0/0/8 |
| `551-net-wm-state-maximized.t` | 12/0/0 | 1/1/0 | 0/10/2 |
| `553-popup_during_fullscreen.t` | 20/0/0 | 16/0/4 | 20/0/0 |
| `554-commands-crash-for-window.t` | 101/0/0 | 67/0/34 | 69/0/32 |
| `556-workspace-keeps-focus-after-move.t` | 5/0/0 | 3/0/0 | 3/0/0 |

## Why this does not run against hy3

The harness requires an i3/sway IPC socket, i3-ipc framing, sway commands, and the i3 `GET_TREE` schema. [hy3](https://github.com/outfoxxed/hy3) is a Hyprland layout plugin. Its current source registers a Hyprland tiled layout and Hyprland dispatchers such as `hy3:movefocus`; it does not create an i3/sway IPC endpoint. Its Lua configuration support also exposes Hyprland dispatcher factories rather than an i3/sway socket. A separate [Lua hy3 layout](https://github.com/aarobc/hy3-lua) registers as `lua:hy3` through Hyprland's custom layout API and requires Hyprland 0.50 or newer.

Testing either implementation would require a translator from sway commands and `GET_TREE` to Hyprland's IPC and state model. The tests would then measure that translator as well as the layout, so this repository does not present such a run as an oracle measurement.

## Validate the repository

```sh
./contrib/validate
```

The check validates each result file, compiles the Python runner, exercises the TAP counter, and compares fixture fields with the pinned sway source.

## Licence

The repository uses the BSD-3-Clause licence. The vendored i3 tests retain the original i3 copyright notice in [`i3/LICENSE`](i3/LICENSE).
