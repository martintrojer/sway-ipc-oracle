# sway adapter

This adapter replaces only i3's compositor launcher and its `I3_SYNC` barrier.
It starts pinned sway with a headless wlroots backend, private IPC and X11
sockets, and runs real X11 clients on sway's own Xwayland. The optional direct
workspace navigation shim is enabled because sway omits i3's intermediate
output `content` node (`sway/sway/ipc-json.c:869-874`).

Like the swayward adapter, it converts i3's `fake-outputs` directive into
headless output count, mode, and position settings, then maps `fake-N` to
`HEADLESS-(N+1)` at config and command boundaries and back at IPC boundaries.
Rows affected by this translation carry `adapted =
["fake-outputs->headless-outputs"]` in `i3/results/sway.toml`.
