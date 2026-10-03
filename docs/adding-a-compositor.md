# Adding a compositor

The runners measure a compositor from the outside: they start it headless on a
private IPC socket, open real client windows, and talk to it over i3/sway IPC.
Adding a compositor means adding an adapter, not changing a test.

1. Add an adapter beside the existing ones (`i3/adapters/<name>/` for the i3
   suite, a class in `contrib/sway-ipc-run` for the sway IPC scenarios). It may
   start the compositor, translate a test's config into the compositor's own
   config language, and publish the IPC socket path. It must not change an
   assertion or a value observed over IPC.
2. List every translation rule in the adapter's README, and flag affected rows
   as `adapted`. The same premise gets the same translation on every compositor
   that can express it.
3. Pin the compositor's source revision in `pins.toml`, and add its versioned
   snapshot name under `[snapshot]`.
4. Generate its snapshots with the runners and classify every non-pass in
   `i3/classifications/<snapshot>.toml`, citing source.
5. Before publishing a snapshot of someone else's project, send its maintainers
   a courtesy note.

Read [`CONTRIBUTING.md`](../CONTRIBUTING.md) for the rules that keep snapshots
fair across compositors.
