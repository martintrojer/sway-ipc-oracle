# sway adapter

This adapter replaces only i3's compositor launcher and its `I3_SYNC` barrier.
It starts pinned sway with a headless wlroots backend, private IPC and X11
sockets, and runs real X11 clients on sway's own Xwayland. The optional direct
workspace navigation shim is enabled because sway omits i3's intermediate
output `content` node (`sway/sway/ipc-json.c:869-874`).

Like the swayward adapter, it converts i3's `fake-outputs` directive into
headless output count, mode, and position settings, then maps `fake-N` to
`HEADLESS-(count-N)` at config and command boundaries and back in IPC replies and
subscribed event payloads. The headless backend announces its outputs
last-first, so sway gives workspace 1 to `HEADLESS-count`; this mapping keeps
i3's premise that `fake-0` is the first output, holds workspace 1 and has the
initial focus. It also translates i3's `workspace_layout stacked`
and `layout stacked` spelling to sway's `stacking`.
Rows affected by these translations carry the corresponding `adapted` flags in
`i3/results/sway-1.12.toml`. The i3-derived recorder also preserves each source
fake output's mode, position, and initial focus; derived rows that replay this
setup carry `adapted = ["source-fake-output-layout"]`.
