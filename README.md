# sway-ipc-oracle

A conformance oracle for compositors that speak the i3/sway IPC protocol. It
runs i3's own test suite, unchanged, and replays IPC replies captured from real
sway, then records what each compositor did.

It is for people who build or change a sway-compatible compositor and want to
know where it behaves like sway and i3, and where it does not.

## What's in it

- **The i3 suite.** `i3/t/` holds 242 test files from i3, unchanged, at commit
  `9be3249a`. Michael Stapelberg and the i3 contributors wrote them; their
  BSD-3-Clause notice is in [`i3/LICENSE`](i3/LICENSE).
- **Sway's replies.** `sway-ipc/fixtures/` and `sway-ipc/i3-derived/` hold IPC
  replies and events captured from sway 1.12, including 270 tree states reached
  by i3's own tests.
- **Snapshots.** One result file per compositor and version, written only by the
  runners, with review notes kept beside them in `classifications/`.

The oracle came out of [swayward](https://github.com/martintrojer/swayward),
its first user. Nothing here depends on swayward.

## Snapshots

Each row is one pinned compositor measured against the oracle. The i3-suite
column is pass/skip/fail (fail includes assertions the run never reached),
excluding files listed as flaky. The sway-ipc column is match/mismatch/not
applicable; for i3 it is match/differs/not applicable, because i3's protocol
lacks sway's extensions. These are measurements, not scores.

| Snapshot | i3 suite (pass/skip/fail) | Flaky files | sway IPC | Commit |
| --- | --- | --- | --- | --- |
| `i3-4.25` | 3,754/1/0 | 0 | 28/59/93 | `9be3249a` |
| `sway-1.12` | 1,469/20/2,110 | 8 | 93/0/0 | `88869399` |
| `swayward-0fbb931c` | 1,443/11/2,279 | 1 | 93/0/0 | `0fbb931c` |

Most of sway's non-passes against i3's tests are deliberate: sway is a Wayland
compositor, and many i3 tests assume X11. Every non-pass carries a reviewed
classification with a source citation, in `i3/classifications/`.

## Try it

Run one test file against your own sway build:

```sh
./contrib/i3-suite-run --compositor sway --binary /path/to/sway 001-tile.t
```

- [Running the oracle](docs/running.md): the i3 suite and the sway IPC scenarios.
- [Reproducing the snapshots](docs/reproducing.md): the pinned container, and one command per snapshot.
- [Adding a compositor](docs/adding-a-compositor.md).

## Compositor inventory

The runners need an i3/sway IPC socket with `i3-ipc` framing, compatible
commands, and the i3 `GET_TREE` schema. "Runnable" means an adapter can start
the project and test that interface directly, without translating another
protocol.

| Project | IPC | Runnable? | Snapshotted? | Why not? |
| --- | --- | :---: | :---: | --- |
| [i3](https://i3wm.org/docs/ipc.html) | i3 IPC | Yes | Yes | — |
| [sway](https://github.com/swaywm/sway/blob/master/sway/sway-ipc.7.scd) | i3-compatible sway IPC | Yes | Yes | — |
| [swayward](https://github.com/martintrojer/swayward) | sway IPC | Yes | Yes | — |
| [SwayFX](https://github.com/wlrfx/swayfx) | sway IPC, with effect commands | Yes | No | The project has not received the courtesy notice required before this oracle publishes measurements. |
| [scroll](https://github.com/dawsers/scroll) | sway IPC, with scrolling-layout extensions through `scrollmsg` | Yes | No | The project has not received the courtesy notice required before this oracle publishes measurements. |
| [swirl](https://github.com/visnudeva/swirl) | sway IPC through stock `swaymsg` | Yes | No | The project has not received the courtesy notice required before this oracle publishes measurements. |
| [miracle-wm](https://wiki.miracle-wm.org/develop/ipc/) | i3/sway IPC; no `GET_CONFIG` or `GET_BAR_CONFIG`, and no `GET_INPUTS` or `GET_SEATS` yet | Yes | No | The project has not received the courtesy notice required before this oracle publishes measurements. |
| [niri](https://niri-wm.github.io/niri/IPC.html) | Its own newline-delimited JSON protocol on `NIRI_SOCKET` | No | No | It has no i3/sway IPC endpoint. |
| [Hyprland](https://wiki.hypr.land/IPC/) | Hyprland command and event sockets | No | No | Plugins can add i3-like layouts, but there is no i3/sway IPC endpoint. |
| [river](https://man.archlinux.org/man/river.1.en) | `river-window-management-v1` Wayland protocol | No | No | It has no i3/sway IPC endpoint. |
| [Qtile](https://github.com/qtile/qtile/blob/master/libqtile/ipc.py) | Qtile's own Unix-socket protocol | No | No | It has no i3/sway IPC endpoint. |
| [Wayfire](https://wayfire.org/2023/10/07/Wayfire-0-8.html) | Its own extensible JSON IPC plugin | No | No | Its upstream IPC is not i3/sway IPC. A separate experimental [`wayfire-ipc`](https://github.com/AR-CADE/wayfire-ipc) plugin would make the measurement depend on an adapter inside the compositor. |
| [COSMIC](https://github.com/pop-os/cosmic-protocols) | COSMIC-specific Wayland protocol extensions | No | No | It has no i3/sway IPC endpoint. |
| [i3-gaps](https://github.com/Airblader/i3) | i3 IPC | Covered | Covered by i3 | i3-gaps was merged into i3 for version 4.22 and its repository was archived. |

A runnable project gets a snapshot only after its maintainers have had a
courtesy note, as i3 and sway did.

## Contributing

Read [`CONTRIBUTING.md`](CONTRIBUTING.md) before changing a runner, an adapter
or a snapshot. It explains how snapshots stay reproducible and fair.

## Licence

BSD-3-Clause. The i3 tests keep their original notice in
[`i3/LICENSE`](i3/LICENSE).
