# swayward adapter

This black-box adapter starts the real swayward binary with its headless backend,
a private `SWAYSOCK`, and automatic xwayland-satellite integration. It uses no
`SWAYWARD_TEST_CONTROL` hook. The i3 tests create real X11 windows through the
satellite; the adapter replaces only startup and i3's unsupported `I3_SYNC`
barrier, plus the same direct-workspace navigation needed for sway's tree shape.
