# swayward adapter

This black-box adapter starts the real swayward binary with its headless backend,
a private `SWAYSOCK`, and automatic xwayland-satellite integration. It uses no
`SWAYWARD_TEST_CONTROL` hook. The i3 tests create real X11 windows through the
satellite.

The launcher translates the i3 config with swayward's `contrib/sway-to-kdl`
and passes the resulting KDL to swayward. Translation failures abort the test
instead of silently running with defaults.

The launcher applies these premise-preserving translations before conversion:

- Remove i3test's adapter-owned `ipc-socket` directive. The adapter creates and
  publishes the private `SWAYSOCK` itself.
- Like the sway adapter, convert i3's `fake-outputs` directive into headless
  output count, mode, and position settings. Map each `fake-N` name to the
  matching `headless-N+1` name at the config, command, and IPC boundaries,
  including subscribed event payloads; swayward also maps i3's primary-output
  marker.
- Remove the exact `bar { output primary }` block from
  `316-drag-container.t`. The test uses the block only to identify the primary
  fake output, which the translated headless output already identifies.

Rows affected by a translation carry an `adapted` field in
`i3/results/swayward-0fbb931c.toml`. The adapter does not translate X11 `class` criteria
to Wayland `app_id`; that would hide swayward's lack of X11 metadata from
xwayland-satellite.

The runner mounts a private `/tmp`, including both X11 sockets and display lock
files, so parallel satellite instances cannot collide with each other or the
host.

The test-side shim replaces i3's unsupported `I3_SYNC` barrier and adapts
swayward's direct-workspace IPC tree shape to the intermediate output `content`
node expected by i3's helper and direct tree traversal. It does not substitute a
real window for i3's synthetic `open` command: sway has no empty-container
command, and a mapped window would test different behavior. `split toggle` is
resolved from the focused IPC node because swayward currently resolves a
leaf-targeted toggle differently from i3.
