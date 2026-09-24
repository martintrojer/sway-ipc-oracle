# sway adapter

This adapter replaces only i3's compositor launcher and its `I3_SYNC` barrier.
It starts pinned sway with a headless wlroots backend, private IPC and X11
sockets, and runs real X11 clients on sway's own Xwayland. The optional direct
workspace navigation shim is enabled because sway omits i3's intermediate
output `content` node (`sway/sway/ipc-json.c:869-874`).
