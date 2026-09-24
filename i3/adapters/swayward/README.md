# swayward adapter

This black-box adapter starts the real swayward binary with its headless backend,
a private `SWAYSOCK`, and automatic xwayland-satellite integration. It uses no
`SWAYWARD_TEST_CONTROL` hook. The i3 tests create real X11 windows through the
satellite.

The launcher removes i3test's adapter-owned `ipc-socket` directive, translates
each remaining i3 config with swayward's `contrib/sway-to-kdl`, and passes the
resulting KDL to swayward. The adapter converts i3's `fake-outputs` directive
into headless output count, mode, and position settings, then maps the
`fake-N` names at the config, command, and IPC boundaries. Translation failures
abort the test instead of silently running with defaults. The runner mounts a
private `/tmp`, including both X11 sockets and display lock files, so parallel
satellite instances cannot collide with each other or the host.

The test-side shim replaces i3's unsupported `I3_SYNC` barrier, maps real X11
windows for i3's synthetic `open` command, and adapts swayward's direct-workspace
IPC tree shape to the intermediate output `content` node expected by i3's helper
and direct tree traversal. `split toggle` is resolved from the focused IPC node
because swayward currently resolves a leaf-targeted toggle differently from i3.
