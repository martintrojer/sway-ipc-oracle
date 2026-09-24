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

The repository currently includes only [`i3/results/swayward.toml`](i3/results/swayward.toml), imported from swayward. `i3/results/i3.toml` and `i3/results/sway.toml` are omitted until pinned runs produce them. No i3 or sway result is inferred from the existing calibration report.

## Run the suite against sway

The sway calibration runner is useful without swayward. It runs i3's original tests against a real sway process and uses i3's original `i3test.pm`. The runner replaces only process startup and i3's X11 synchronization barrier. Read [`i3/calibration/README.md`](i3/calibration/README.md) for the method and limits.

Check out the pinned sources and build sway 1.12, then run:

```sh
I3SRC=/path/to/i3 \
SWAYBUILD=/path/to/sway-build/build \
CONTAINER=swayward-dev \
TIMEOUT=60 \
./contrib/sway-calibration-run --all
./contrib/sway-calibration-report --results i3/results/swayward.toml
```

`I3SRC` must be at `9be3249ac5b377ed3270e36bca83df53d8023337`. The sway binary must identify commit `88869399`. The default container name reflects the development environment where the runner began; set `CONTAINER` to any distrobox with the dependencies listed in the calibration guide.

The same runner command will produce the pinned i3 and sway measurements after the dedicated i3 baseline mode lands. The repository does not currently claim that mode exists.

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
Use repeated `--scenario NAME` arguments for a subset. `--fresh-per-scenario`
restarts the compositor for each recipe;
the default sequential mode matches the original capture. `--capture` is
restricted to sway and replaces the selected query fixtures after running the
same comparisons. The i3 adapter runs i3 under private Xvfb and opens xterm
clients; both programs must be installed beside the runner.

## Adopt the oracle in another compositor

The oracle's runners contain adapters that start isolated i3, sway, and swayward instances, open real client windows, and connect through private IPC sockets. A compositor can also keep an in-process harness in its own repository. Swayward's [`tests/i3/lib/i3test.pm`](https://github.com/martintrojer/swayward/blob/4faeb28d391c8ede3ead6f9b7cbe4388422d3887/tests/i3/lib/i3test.pm) is one such harness, but this repository does not publish its numbers as black-box oracle measurements.

Publish black-box results from the oracle's runners under the matching oracle's `results/` directory. Publish every verdict count together, pin the compositor and oracle versions, and cite every deliberate difference.

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
